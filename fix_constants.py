import re
import os

files = [
    r'd:\MuhimmatAltawseel\supabase\migrations\20260415000001_constants.sql',
    r'd:\MuhimmatAltawseel\supabase\manual_sync.sql'
]

mapping = {
    "_const_order_cancelled()": "'cancelled'",
    "_const_installment_pending()": "'pending'",
    "_const_installment_deferred()": "'deferred'",
    "_const_approval_approved()": "'approved'",
    "_const_work_orders()": "'orders'",
    "_const_work_shift()": "'shift'",
    "_const_work_hybrid()": "'hybrid'",
    "_const_days_per_month()": "30.0",
    "_const_employee_active()": "'active'",
    "_const_payment_cash()": "'cash'",
    "_const_payment_bank()": "'bank'",
    "_const_calc_calculated()": "'calculated'",
    "_const_calc_source_v6()": "'engine_v6_shift_fallback'",
    "_const_calc_source_v7()": "'engine_v7_shift_fixed'",
    "_const_calc_method_orders()": "'orders'",
    "_const_calc_method_shift()": "'shift'",
    "_const_calc_method_shift_fixed()": "'shift_fixed'",
    "_const_calc_method_shift_full_month()": "'shift_full_month'",
    "_const_calc_method_mixed()": "'mixed'",
    "_const_calc_method_orders_fallback()": "'orders_fallback'",
    "_const_tier_fixed()": "'fixed_amount'",
    "_const_tier_incremental()": "'base_plus_incremental'"
}

for filepath in files:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    def replacer(match):
        func_name = match.group(1)
        return_type = match.group(2)
        inner_call = match.group(3)
        
        for key, val in mapping.items():
            if key in func_name + "()":
                new_inner = inner_call.replace(key, val)
                return f"CREATE OR REPLACE FUNCTION {func_name}() RETURNS {return_type} AS $$\n{new_inner}\n$$"
        
        return match.group(0)

    pattern = re.compile(r"CREATE OR REPLACE FUNCTION ([a-zA-Z0-9_]+)\(\) RETURNS ([a-zA-Z0-9_]+) AS \$\$\n(.*?)\n\$\$", re.DOTALL)
    
    new_content = pattern.sub(replacer, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

print("Done")
