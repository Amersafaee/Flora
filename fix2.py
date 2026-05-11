import re

path = r'c:\Projects\Flora\lib\screens\swap_market_screen.dart'
with open(path, 'rb') as f:
    raw = f.read()

try:
    content = raw.decode('utf-8')
except Exception:
    content = raw.decode('utf-16')

# write as utf-8 unconditionally
with open(path, 'wb') as f:
    f.write(content.encode('utf-8'))
print('Saved as UTF-8.')
