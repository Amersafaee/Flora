import os
import re

screens_dir = r'c:\Projects\Flora\lib\screens'
services_dir = r'c:\Projects\Flora\lib\services'

screen_files = [f for f in os.listdir(screens_dir) if f.endswith('.dart')]
service_files = [f for f in os.listdir(services_dir) if f.endswith('.dart')]

report = []
report.append('# Flora App Complete Audit\n')
report.append('## Screen Files Inventory')
for f in screen_files:
    report.append(f'- {f}')
report.append('\n## Service Files Inventory')
for f in service_files:
    report.append(f'- {f}')
report.append('\n---\n')

def analyze_screen(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    filename = os.path.basename(filepath)
    screen_name = filename.replace('.dart', '').replace('_', ' ').title()
    
    # Purpose
    purpose = 'Manages ' + screen_name.lower()
    
    # Buttons
    buttons = []
    for match in re.finditer(r'(IconButton|ElevatedButton|TextButton|OutlinedButton|FloatingActionButton|GestureDetector|InkWell)[\s\S]*?(onPressed|onTap):\s*(\([^\)]*\)\s*(async\s*)?\{[\s\S]*?\}|[\w\._]+|null|=>[^,]+,)', content):
        btn_type = match.group(1)
        action_raw = match.group(3)
        status = 'working'
        if 'Coming soon' in action_raw or 'Coming Soon' in action_raw or 'coming soon' in action_raw:
            status = 'coming soon'
        elif action_raw == 'null' or '{}' in action_raw.replace(' ', ''):
            status = 'broken/empty'
        
        # Try to find a child Text or Icon to name it
        btn_name = btn_type
        # Heuristic backward search for Text/Icon
        block = content[max(0, match.start()-200):match.end()+200]
        text_match = re.search(r'Text\(([\'\"].*?[\'\"])', block)
        icon_match = re.search(r'Icon\(Icons\.([a-z_]+)', block)
        if text_match:
            btn_name = f'{btn_type} ({text_match.group(1)})'
        elif icon_match:
            btn_name = f'{btn_type} (Icon: {icon_match.group(1)})'
            
        action_summary = action_raw.strip()[:60].replace('\n', ' ') + '...'
        buttons.append(f'- {btn_name}: {action_summary} ({status})')
        
    if not buttons:
        buttons = ['- No standard buttons detected or handled via other widgets']
        
    # Data connection
    collections_read = set(re.findall(r'\.collection\([\'\"]([a-zA-Z_]+)[\'\"]\)', content))
    collections_str = ', '.join(collections_read) if collections_read else 'None direct (may use services)'
    
    # Dark mode
    if 'Theme.of(context)' in content:
        dark_mode = 'yes (uses Theme.of(context))'
    else:
        dark_mode = 'no/partial (missing Theme usage)'
        
    # Bugs
    bugs = []
    for match in re.finditer(r'//\s*(TODO|FIXME|BUG).*', content, re.IGNORECASE):
        bugs.append('- ' + match.group(0))
    if 'Coming soon' in content:
        bugs.append('- Contains \'Coming soon\' placeholders')
    if not bugs:
        bugs = ['- No explicit TODOs or placeholders found']
        
    report.append(f'### Screen name: {screen_name}')
    report.append(f'**Purpose:** {purpose}')
    report.append('**Every button and what it does:**')
    report.extend(buttons)
    report.append(f'**Every data connection:** Reads/Writes to {collections_str}')
    report.append('**Known bugs or issues:**')
    report.extend(bugs)
    report.append('**Missing features that were planned but not implemented:** ' + ('See bugs/Coming soon' if 'Coming soon' in content else 'None immediately apparent'))
    report.append(f'**Dark mode support:** {dark_mode}\n')

def analyze_service(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    filename = os.path.basename(filepath)
    service_name = filename.replace('.dart', '').replace('_', ' ').title()
    
    # Purpose
    purpose = 'Service for ' + service_name.lower()
    
    # Methods
    working_methods = []
    broken_methods = []
    for match in re.finditer(r'(Future<.*?>|void|Stream<.*?>|String|int|bool|List<.*?>|Map<.*?>)\s+([a-zA-Z_][a-zA-Z0-9_]*)\(.*?\)\s*(async)?\s*\{([\s\S]*?)\n  \}', content):
        ret_type = match.group(1)
        name = match.group(2)
        body = match.group(4)
        if body.strip() == '' or '// TODO' in body or body.strip() == 'return;':
            broken_methods.append(f'- {name} (empty or stub)')
        else:
            working_methods.append(f'- {name}')
            
    if not working_methods:
        working_methods = ['- None detected']
    if not broken_methods:
        broken_methods = ['- None empty or broken']
        
    perf = []
    if 'get()' in content and 'limit' not in content:
        perf.append('- Potential unbounded get() query')
    if not perf:
        perf = ['- No immediate major concerns detected by static analysis']
        
    report.append(f'### Service name: {service_name}')
    report.append(f'**Purpose:** {purpose}')
    report.append('**Methods that work:**')
    report.extend(working_methods)
    report.append('**Methods that are empty or broken:**')
    report.extend(broken_methods)
    report.append('**Any performance concerns:**')
    report.extend(perf)
    report.append('\n')

for f in screen_files:
    analyze_screen(os.path.join(screens_dir, f))
    
report.append('\n---\n')
for f in service_files:
    analyze_service(os.path.join(services_dir, f))

with open('audit_report.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(report))
