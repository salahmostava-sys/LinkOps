import os
import re

FRONTEND_DIR = r"d:\project\MuhimmatAltawseel\frontend"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    # Pattern 1: {x.toLocaleString('en-US')} ر.س
    # Replace with {formatCurrency(x)}
    pattern1 = re.compile(r'\{([a-zA-Z0-9_.\(\)\[\]]+?)\.toLocaleString\([\'"]en-US[\'"]\)\}\s*ر\.س')
    content = pattern1.sub(r'{formatCurrency(\1)}', content)

    # Pattern 2: ${x.toLocaleString('en-US')} ر.س (inside template literals)
    pattern2 = re.compile(r'\$\{([a-zA-Z0-9_.\(\)\[\]]+?)\.toLocaleString\([\'"]en-US[\'"]\)\}\s*ر\.س')
    content = pattern2.sub(r'${formatCurrency(\1)}', content)

    # Pattern 3: ${(x).toFixed(1)} ر.س
    pattern3 = re.compile(r'\$\{([^}]+)\.toFixed\(\d+\)\}\s*ر\.س')
    content = pattern3.sub(r'${formatCurrency(\1)}', content)

    # Pattern 4: {x} <span...>ر.س</span> where x has toLocaleString
    pattern4 = re.compile(r'\{([a-zA-Z0-9_.\(\)\[\]]+?)\.toLocaleString\([\'"]en-US[\'"]\)\}\s*<span[^>]*>ر\.س</span>')
    content = pattern4.sub(r'{formatCurrency(\1)}', content)

    # Date pattern 1: ${new Date(x).toLocaleDateString('ar-SA')}
    date_pattern1 = re.compile(r'\$\{new Date\(([^)]*)\)\.toLocaleDateString\([\'"]ar-SA[\'"]\)\}')
    content = date_pattern1.sub(r'${formatStandardDateTime(\1)}', content)

    # Date pattern 2: {new Date(x).toLocaleDateString('ar-SA')}
    date_pattern2 = re.compile(r'\{new Date\(([^)]*)\)\.toLocaleDateString\([\'"]ar-SA[\'"]\)\}')
    content = date_pattern2.sub(r'{formatStandardDateTime(\1)}', content)

    if content != original_content:
        # ensure imports are added if missing
        imports_added = False
        import_stmt = "import { formatCurrency, formatStandardDateTime } from '@shared/lib/formatters';\n"
        
        # Check if formatCurrency is already imported
        if 'formatCurrency' not in original_content and 'formatStandardDateTime' not in original_content:
            # Add to top of file
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i, import_stmt)
                    imports_added = True
                    break
            if imports_added:
                content = '\n'.join(lines)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

for root, _, files in os.walk(FRONTEND_DIR):
    for file in files:
        if file.endswith(('.ts', '.tsx')):
            process_file(os.path.join(root, file))

print("Done.")
