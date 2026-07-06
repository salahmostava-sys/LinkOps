import os
import re

FRONTEND_DIR = r"d:\project\MuhimmatAltawseel\frontend"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Regex to find:
    # <div className="space-y-[1-4].*?">
    #   <Label.*?> SOME_TEXT </Label>
    #   <Input ... />
    # </div>
    # 
    # Because of React's nesting, we need a somewhat robust regex or do it in a controlled manner.
    
    # Let's match simpler block:
    # <div className="space-y-2">
    #   <Label>اسم المؤسسة (بالعربية)</Label>
    #   <Input value={nameAr} onChange={e => setNameAr(e.target.value)} placeholder="شركة المنسق الرقمي" dir="rtl" />
    # </div>
    
    pattern = re.compile(
        r'<div\s+className=["\']space-y-\d+[^"\']*["\']>\s*'
        r'<Label[^>]*>(.*?)</Label>\s*'
        r'<Input\s+(.*?)\s*/>\s*'
        r'</div>',
        re.DOTALL
    )

    def replacer(match):
        label_text = match.group(1).strip()
        input_props = match.group(2).strip()
        
        # Clean label text if it has nested JSX (skip if too complex)
        if '<' in label_text:
            return match.group(0) # don't modify
            
        return f'<BaseInput label="{label_text}" {input_props} />'

    new_content = pattern.sub(replacer, content)

    if new_content != original:
        # Need to import BaseInput
        if 'BaseInput' not in new_content:
            new_content = "import { BaseInput } from '@shared/components/ui/base-input';\n" + new_content
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Refactored inputs in {filepath}")

for root, _, files in os.walk(FRONTEND_DIR):
    # skip some modules where we don't want to break layout
    if 'ui' in root: continue
    
    for file in files:
        if file.endswith(('.tsx')):
            process_file(os.path.join(root, file))

print("Input refactor done.")
