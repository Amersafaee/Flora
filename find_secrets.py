import subprocess
import re
import json
from collections import defaultdict

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, text=True, encoding='utf-8', errors='replace')
    except subprocess.CalledProcessError as e:
        return e.output

commits_info = {}
out = run_cmd(['git', 'log', '--all', '--format=%H|%cI|%s'])
for line in out.splitlines():
    if '|' in line:
        h, d, m = line.split('|', 2)
        commits_info[h] = {'date': d, 'msg': m}

commits = list(commits_info.keys())

findings = defaultdict(lambda: defaultdict(list))

for h in commits:
    cmd = ['git', 'grep', '-E', 
           '-e', 'AIza[0-9A-Za-z_-]{20,}', 
           '-e', 'sk-[A-Za-z0-9]{20,}', 
           '-e', 'AKIA[0-9A-Z]{16}', 
           '-e', 'BEGIN (RSA )?PRIVATE KEY',
           '-e', '1:[0-9]+:(android|ios|web):[0-9a-f]+',
           '-e', 'api_?key|secret|token|password|private_?key', h]
    
    grep_out = run_cmd(cmd)
    for line in grep_out.splitlines():
        parts = line.split(':', 2)
        if len(parts) >= 3:
            commit_hash = parts[0]
            file_path = parts[1]
            content = parts[2]
            
            for m in re.finditer(r'AIza[0-9A-Za-z_-]{20,}', content):
                findings['Google API'][m.group(0)].append((commit_hash, file_path))
            for m in re.finditer(r'sk-[A-Za-z0-9]{20,}', content):
                findings['OpenAI'][m.group(0)].append((commit_hash, file_path))
            for m in re.finditer(r'AKIA[0-9A-Z]{16}', content):
                findings['AWS'][m.group(0)].append((commit_hash, file_path))
            if re.search(r'BEGIN (RSA )?PRIVATE KEY', content):
                findings['Private Key']['[PRIVATE KEY BLOCK]'].append((commit_hash, file_path))
            for m in re.finditer(r'1:[0-9]+:(android|ios|web):[0-9a-f]+', content):
                findings['Firebase AppID'][m.group(0)].append((commit_hash, file_path))
            for m in re.finditer(r'(?i)(?:api_?key|secret|token|password|private_?key)\s*[:=]\s*(["\'])([^"\']+)\1', content):
                val = m.group(2)
                if len(val) > 4 and not re.match(r'^\$\{.+\}$', val) and "apiKey" not in val and "API_KEY" not in val:
                    findings['Generic Secret'][val].append((commit_hash, file_path))

with open('findings.json', 'w', encoding='utf-8') as f:
    json.dump(findings, f, indent=2)

print("Done.")
