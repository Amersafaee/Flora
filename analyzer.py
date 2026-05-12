import os
import glob
import re

def parse_file(path):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    filename = os.path.basename(path)
    lines = content.split('\n')
    
    # 1. Screen/Service Purpose
    classes = re.findall(r'class\s+([A-Za-z0-9_]+)', content)
    
    # 2. Firestore interactions
    firestore_calls = []
    for line in lines:
        if ('FirestoreService' in line and '.' in line) or ('_firestore' in line and '.' in line) or ('FirebaseFirestore' in line):
            call = line.strip()
            if len(call) < 150 and call not in firestore_calls:
                firestore_calls.append(call)
                
    # 3. Buttons & Actions
    buttons = []
    # simple extraction of onPressed and onTap
    for i, line in enumerate(lines):
        if 'onPressed:' in line or 'onTap:' in line or 'GestureDetector(' in line or 'IconButton(' in line or 'ElevatedButton(' in line:
            # find context
            context_start = max(0, i - 2)
            context_end = min(len(lines), i + 3)
            block = " ".join([l.strip() for l in lines[context_start:context_end]])
            
            status = "Working"
            if '() {}' in block.replace(' ', ''): status = "Broken/Empty"
            if 'Coming soon' in block or 'Not implemented' in block or 'SnackBar(' in block: status = "UI Only / Coming Soon"
            if 'TODO' in block: status = "TODO"
            
            action_name = re.search(r'(Text|Icon|Tooltip|label)[\(:]\s*[\'"]([^\'"]+)[\'"]', block)
            name = action_name.group(2) if action_name else line.strip()
            
            buttons.append(f"- {name} [{status}]")
            
    # 4. Navigation
    navigation = []
    for line in lines:
        if 'Navigator.' in line or 'context.push' in line or 'context.go' in line:
            nav = line.strip()
            if nav not in navigation: navigation.append(nav)
            
    # 5. Issues/Todos
    issues = []
    for line in lines:
        if 'TODO' in line or 'FIXME' in line or 'Coming soon' in line:
            issues.append(line.strip())

    report = f"### {filename}\n"
    report += f"**Classes:** {', '.join(classes[:3])}\n"
    if firestore_calls:
        report += "**Firestore Usage:**\n" + "\n".join([f"  - {c}" for c in firestore_calls[:5]]) + "\n"
    if buttons:
        report += "**Buttons/Actions:**\n" + "\n".join(set(buttons[:10])) + "\n"
    if navigation:
        report += "**Navigation:**\n" + "\n".join([f"  - {n}" for n in navigation[:5]]) + "\n"
    if issues:
        report += "**Known Issues:**\n" + "\n".join([f"  - {i}" for i in issues[:5]]) + "\n"
        
    return report

screens = glob.glob('lib/screens/*.dart')
services = glob.glob('lib/services/*.dart')

with open('report_draft.md', 'w', encoding='utf-8') as f:
    f.write("# Flora App State Report Draft\n\n")
    for s in screens + services:
        f.write(parse_file(s) + "\n\n")

print("Generated report_draft.md")
