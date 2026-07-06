import os
import re

FRONTEND_DIR = r"d:\project\MuhimmatAltawseel\frontend"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    has_format_currency = bool(re.search(r'(?<!import { )formatCurrency\(', content))
    has_format_date = bool(re.search(r'(?<!import { )formatStandardDateTime\(', content))

    # We added: import { formatCurrency, formatStandardDateTime } from '@shared/lib/formatters';
    # If one is not used, remove it from the import.
    
    if not has_format_currency and 'formatCurrency' in content:
        content = content.replace('formatCurrency, formatStandardDateTime', 'formatStandardDateTime')
        content = content.replace('formatStandardDateTime, formatCurrency', 'formatStandardDateTime')
        
    if not has_format_date and 'formatStandardDateTime' in content:
        content = content.replace('formatCurrency, formatStandardDateTime', 'formatCurrency')
        content = content.replace('formatStandardDateTime, formatCurrency', 'formatCurrency')

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned imports in {filepath}")

for root, _, files in os.walk(FRONTEND_DIR):
    for file in files:
        if file.endswith(('.ts', '.tsx')):
            process_file(os.path.join(root, file))
