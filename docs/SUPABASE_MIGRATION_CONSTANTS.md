# SQL Migration Constants

## المشكلة
SonarCloud يحذر من تكرار string literals في ملفات SQL migrations، مما يزيد من صعوبة الصيانة ويرفع احتمالية الأخطاء.

## الحل
تم إنشاء ملف `_constants.sql` يحتوي على دوال ثابتة لكل القيم المتكررة.

## كيفية الاستخدام

### قبل (مع التكرار):
```sql
WHERE d.status IS NULL OR d.status <> 'cancelled'
AND ai.status IN ('pending', 'deferred')
AND ed.approval_status = 'approved'
```

### بعد (باستخدام Constants):
```sql
WHERE d.status IS NULL OR d.status <> _const_order_cancelled()
AND ai.status IN (_const_installment_pending(), _const_installment_deferred())
AND ed.approval_status = _const_approval_approved()
```

## الثوابت المتاحة

### Order Statuses
- `_const_order_cancelled()` → `'cancelled'`

### Installment Statuses
- `_const_installment_pending()` → `'pending'`
- `_const_installment_deferred()` → `'deferred'`

### Approval Statuses
- `_const_approval_approved()` → `'approved'`

### Work Types
- `_const_work_orders()` → `'orders'`
- `_const_work_shift()` → `'shift'`
- `_const_work_hybrid()` → `'hybrid'`

### Payment Methods
- `_const_payment_cash()` → `'cash'`
- `_const_payment_bank()` → `'bank'`

### Employee Statuses
- `_const_employee_active()` → `'active'`

### Calculation Statuses
- `_const_calc_calculated()` → `'calculated'`

### Tier Types
- `_const_tier_fixed()` → `'fixed_amount'`
- `_const_tier_incremental()` → `'base_plus_incremental'`

### Numeric Constants
- `_const_days_per_month()` → `30.0`

## أمثلة عملية

### مثال 1: فلترة الطلبات
```sql
-- قبل
SELECT * FROM daily_orders 
WHERE status IS NULL OR status <> 'cancelled';

-- بعد
SELECT * FROM daily_orders 
WHERE status IS NULL OR status <> _const_order_cancelled();
```

### مثال 2: حساب الراتب الشهري
```sql
-- قبل
v_daily_rate := monthly_amount / 30.0;

-- بعد
v_daily_rate := monthly_amount / _const_days_per_month();
```

### مثال 3: فلترة الأقساط
```sql
-- قبل
WHERE ai.status IN ('pending', 'deferred')

-- بعد
WHERE ai.status IN (_const_installment_pending(), _const_installment_deferred())
```

## ملاحظات

1. **الأداء**: الدوال معرّفة بـ `IMMUTABLE` مما يعني أن PostgreSQL يستطيع تحسينها في وقت التنفيذ
2. **الصيانة**: تغيير قيمة ثابتة يتم في مكان واحد فقط
3. **الوضوح**: الأسماء الواضحة تجعل الكود أسهل للقراءة
4. **SonarCloud**: يحل مشاكل "Define a constant instead of duplicating this literal"

## التطبيق على Migrations الموجودة

لتطبيق هذه الثوابت على migrations موجودة:

1. قم بتشغيل `_constants.sql` أولاً
2. استبدل القيم المكررة بالدوال المناسبة
3. اختبر الـ migration في بيئة تطوير
4. تأكد من أن النتائج مطابقة للنسخة القديمة

## مثال كامل: تحديث Migration

```sql
-- استيراد الثوابت (في بداية الملف)
\i _constants.sql

-- استخدام الثوابت في الدالة
CREATE OR REPLACE FUNCTION preview_salary_for_month(p_month_year TEXT)
RETURNS TABLE (...)
AS $$
DECLARE
  v_days_per_month NUMERIC := _const_days_per_month();
BEGIN
  FOR v_emp IN 
    SELECT e.id FROM employees e 
    WHERE e.status = _const_employee_active()
  LOOP
    -- حساب الطلبات
    SELECT COALESCE(SUM(d.orders_count), 0) INTO v_orders
    FROM daily_orders d
    WHERE d.status IS NULL OR d.status <> _const_order_cancelled();
    
    -- حساب الأقساط
    SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance
    FROM advance_installments ai
    WHERE ai.status IN (
      _const_installment_pending(), 
      _const_installment_deferred()
    );
    
    -- حساب الخصومات
    SELECT COALESCE(SUM(ed.amount), 0) INTO v_deduction
    FROM external_deductions ed
    WHERE ed.approval_status = _const_approval_approved();
  END LOOP;
END;
$$;
```

## الخطوات التالية

1. ✅ إنشاء ملف `_constants.sql`
2. ⏳ تطبيق الثوابت على migrations الموجودة
3. ⏳ إضافة ثوابت جديدة عند الحاجة
4. ⏳ توثيق أي ثوابت إضافية في هذا الملف
