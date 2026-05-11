import re
path = r'c:\Projects\Flora\lib\screens\swap_market_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(r"'\$\{location\}[^']*?\$\{distanceKm\}km'")
new_content = re.sub(pattern, "'$location · ${distanceKm}km'", content)

if new_content != content:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Replaced!')
else:
    print('Not replaced!')
