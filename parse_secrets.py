import re

commits_info = {}
with open('commits.txt', 'r', encoding='utf-16') as f:
    for line in f:
        h = line.strip()
        if h:
            commits_info[h] = True

def parse_grep(file_name, pattern_dict, is_aiza=False):
    findings = {}
    with open(file_name, 'r', encoding='utf-8-sig') as f:
        for line in f:
            parts = line.strip().split(':', 2)
            if len(parts) >= 3:
                h = parts[0]
                filepath = parts[1]
                content = parts[2]
                
                for p_name, pattern in pattern_dict.items():
                    for match in re.finditer(pattern, content):
                        val = match.group(0)
                        
                        if val not in findings:
                            findings[val] = {'type': p_name, 'commits': set(), 'files': set()}
                        
                        findings[val]['commits'].add(h)
                        findings[val]['files'].add(filepath)
    return findings

patterns1 = {
    'Google API': r'AIza[0-9A-Za-z_\-]{20,}'
}
patterns2 = {
    'OpenAI': r'sk-[A-Za-z0-9]{20,}',
    'AWS': r'AKIA[0-9A-Z]{16}',
    'Private Key': r'BEGIN (?:RSA )?PRIVATE KEY',
    'Firebase AppID': r'1:[0-9]+:(?:android|ios|web):[0-9a-f]+'
}

all_findings = {}
all_findings.update(parse_grep('aiza_secrets.txt', patterns1))
all_findings.update(parse_grep('other_secrets.txt', patterns2))

# print results
print(f"Total distinct secrets: {len(all_findings)}")
for val, info in all_findings.items():
    masked = val[:8] + '...' if len(val) > 8 else val
    print(f"\nSecret: {masked} ({info['type']})")
    print(f"Commits: {', '.join(info['commits'])}")
    print(f"Files: {', '.join(info['files'])}")

