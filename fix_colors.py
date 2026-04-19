import os
import re

def fix_color_api(directory):
    # Regex untuk mencari .withValues(alpha: 0.1) dan menggantinya dengan .withOpacity(0.1)
    pattern = re.compile(r'\.withValues\(alpha:\s*([0-9.]+)\)')
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern.sub(r'.withOpacity(\1)', content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed: {path}")

if __name__ == "__main__":
    fix_color_api('d:\\simpakab\\lib')
