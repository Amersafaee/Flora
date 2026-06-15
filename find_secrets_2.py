import subprocess
import re
import json

def get_commits():
    out = subprocess.check_output(['git', 'log', '--all', '--format=%H|%cI|%s'], text=True)
    return [line.split('|', 2) for line in out.splitlines() if '|' in line]

def get_files(commit_hash):
    out = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', commit_hash], text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]

def get_content(commit_hash, path):
    try:
        # Some files might be binary or not exist
        return subprocess.check_output(['git', 'show', f'{commit_hash}:{path}'], text=True, errors='replace')
    except Exception:
        return ""

commits = get_commits()
findings = {}

patterns = {
    'Google API': r'AIza[0-9A-Za-z_\-]{20,}',
    'OpenAI': r'sk-[A-Za-z0-9]{20,}',
    'AWS': r'AKIA[0-9A-Z]{16}',
    'Private Key': r'BEGIN (?:RSA )?PRIVATE KEY',
    'Firebase AppID': r'1:[0-9]+:(?:android|ios|web):[0-9a-f]+',
    'Generic Secret': r'(?i)(?:api_?key|secret|token|password|private_?key)\s*[:=]\s*(["\'])([^"\']+)\1'
}

for h, d, m in commits:
    files = get_files(h)
    for f in files:
        content = get_content(h, f)
        for p_name, pattern in patterns.items():
            for match in re.finditer(pattern, content):
                val = match.group(0) if p_name != 'Generic Secret' else match.group(2)
                
                # Filter generics
                if p_name == 'Generic Secret':
                    if len(val) < 5 or re.match(r'^\$\{.+\}$', val) or val.startswith('AIza') or val.startswith('sk-') or "apiKey" in val or "API_KEY" in val:
                        continue
                
                if p_name not in findings:
                    findings[p_name] = {}
                if val not in findings[p_name]:
                    findings[p_name][val] = []
                
                findings[p_name][val].append({'commit': h, 'date': d, 'file': f})

with open('findings2.json', 'w', encoding='utf-8') as f:
    json.dump(findings, f, indent=2)

print("Done scanning using git show.")
