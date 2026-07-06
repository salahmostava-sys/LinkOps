import os
import re

FRONTEND_DIR = r"d:\project\MuhimmatAltawseel\frontend"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    if '<BaseInput' in content and 'import { BaseInput }' not in content:
        # Add import after the first import or at top
        import_stmt = "import { BaseInput } from '@shared/components/ui/base-input';\n"
        content = import_stmt + content

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed missing BaseInput import in {filepath}")

for root, _, files in os.walk(FRONTEND_DIR):
    for file in files:
        if file.endswith(('.tsx')):
            process_file(os.path.join(root, file))

print("Done.")
