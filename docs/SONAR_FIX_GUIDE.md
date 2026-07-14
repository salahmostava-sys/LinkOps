# دليل إصلاح مشاكل SonarQube

## نظرة عامة

تم إنشاء مجموعة من الأدوات لإصلاح مشاكل SonarQube تلقائياً في المشروع.

## الملفات المتوفرة

### 1. `_constants.sql`
ملف يحتوي على دوال ثوابت SQL لتجنب تكرار القيم الثابتة.

**الموقع**: `supabase/migrations/_constants.sql`

**الدوال المتوفرة**:
- `_const_order_cancelled()` - حالة الطلب الملغي
- `_const_work_orders()` - نوع العمل: طلبات
- `_const_work_shift()` - نوع العمل: شفت
- `_const_work_hybrid()` - نوع العمل: هجين
- `_const_approval_approved()` - حالة الموافقة
- `_const_installment_pending()` - حالة القسط: معلق
- `_const_installment_deferred()` - حالة القسط: مؤجل
- `_const_payment_cash()` - طريقة الدفع: نقدي
- `_const_payment_bank()` - طريقة الدفع: بنك
- `_const_calc_calculated()` - حالة الحساب
- `_const_calc_source_v6()` - مصدر الحساب v6
- `_const_calc_source_v7()` - مصدر الحساب v7
- `_const_calc_method_*()` - طرق الحساب المختلفة
- `_const_tier_fixed()` - نوع الشريحة: ثابت
- `_const_tier_incremental()` - نوع الشريحة: تصاعدي
- `_const_employee_active()` - حالة الموظف: نشط
- `_const_days_per_month()` - عدد الأيام في الشهر (30)

### 2. `fix-sonar-sql-constants.ps1`
سكريبت PowerShell لإصلاح ملفات SQL تلقائياً.

**الموقع**: `scripts/fix-sonar-sql-constants.ps1`

## كيفية الاستخدام

### الخطوة 1: معاينة التغييرات (Dry Run)

قبل تطبيق أي تغييرات، يمكنك معاينة ما سيتم تغييره:

```powershell
cd d:\MuhimmatAltawseel
.\scripts\fix-sonar-sql-constants.ps1 -DryRun
```

هذا سيعرض:
- الملفات التي ستتأثر
- عدد التغييرات في كل ملف
- نوع كل تغيير

### الخطوة 2: تطبيق التغييرات

بعد التأكد من التغييرات، قم بتطبيقها:

```powershell
.\scripts\fix-sonar-sql-constants.ps1
```

### الخطوة 3: مراجعة التغييرات

استخدم Git لمراجعة التغييرات:

```bash
git diff supabase/migrations/
```

### الخطوة 4: اختبار التغييرات

قبل الـ commit، تأكد من:

1. **اختبار Migrations محلياً**:
```bash
npx supabase db reset
```

2. **تشغيل الاختبارات**:
```bash
npm run test
```

3. **التحقق من عدم وجود أخطاء**:
```bash
npm run lint
```

## أمثلة التغييرات

### قبل:
```sql
WHERE status = 'cancelled'
  AND work_type = 'shift'
  AND approval_status = 'approved'
  AND e.status = 'active'
  AND is_active = true
```

### بعد:
```sql
WHERE status = _const_order_cancelled()
  AND work_type = _const_work_shift()
  AND approval_status = _const_approval_approved()
  AND e.status = _const_employee_active()
  AND is_active IS TRUE
```

## التغييرات التي يطبقها السكريبت

### 1. استبدال القيم الثابتة
- `'cancelled'` → `_const_order_cancelled()`
- `'orders'` → `_const_work_orders()`
- `'shift'` → `_const_work_shift()`
- `'approved'` → `_const_approval_approved()`
- `'pending'` → `_const_installment_pending()`
- `'cash'` → `_const_payment_cash()`
- `30.0` → `_const_days_per_month()`
- وغيرها...

### 2. إصلاح مقارنات Boolean
- `= true` → `IS TRUE`
- `= false` → `IS FALSE`
- `<> true` → `IS NOT TRUE`
- `!= false` → `IS NOT FALSE`

## الملفات المُصلحة يدوياً

تم إصلاح هذه الملفات يدوياً كأمثلة:
- ✅ `20260415220000_shift_salary_always_full_month.sql`
- ✅ `20260415210000_shift_salary_fallback_full_month.sql`
- ✅ `20260415200000_debug_and_fix_shift_salary.sql`

## الملفات المتبقية

يمكن للسكريبت إصلاح هذه الملفات تلقائياً:
- `20260415100000_fix_calc_tier_with_scheme_id.sql`
- `20260413100000_fix_salary_rpc_flat_rate_and_scheme.sql`
- `20260413090000_fix_salary_preview_skip_unlinked_platforms.sql`
- `20260411050000_finance_transactions.sql`
- `20260411040000_fix_preview_salary_read_scheme.sql`
- وملفات أخرى كثيرة...

## معلومات إضافية

### الإحصائيات الحالية
- **إجمالي المشاكل**: ~300 مشكلة
- **تم حلها**: 3 ملفات (يدوياً)
- **المتبقية**: ~297 مشكلة

### أنواع المشاكل
- **CRITICAL** (حرجة): تكرار القيم الثابتة
- **MAJOR** (رئيسية): nested ternaries, accessibility
- **MINOR** (ثانوية): boolean comparisons, deprecated APIs

## التحذيرات

⚠️ **مهم جداً**:

1. **عمل Backup قبل التطبيق**:
```bash
git add .
git commit -m "backup before sonar fixes"
```

2. **اختبار في بيئة التطوير أولاً**:
   - لا تطبق على production مباشرة
   - اختبر كل migration بعد التعديل

3. **مراجعة التغييرات**:
   - بعض الاستبدالات قد تحتاج تعديل يدوي
   - تأكد من السياق (context) صحيح

4. **الاعتماديات**:
   - كل migration يستخدم الثوابت يحتاج `_constants.sql`
   - تأكد من تشغيل `_constants.sql` أولاً

## الخطوات التالية

### المرحلة 1: SQL Migrations ✅ (جاري)
- [x] إنشاء `_constants.sql`
- [x] إصلاح 3 ملفات يدوياً
- [x] إنشاء سكريبت تلقائي
- [ ] تطبيق على باقي الملفات
- [ ] اختبار شامل

### المرحلة 2: Frontend Issues ⏳
- [ ] إصلاح nested ternaries
- [ ] إصلاح accessibility issues
- [ ] استبدال deprecated APIs
- [ ] تحسين type safety

### المرحلة 3: Code Quality ⏳
- [ ] تقليل cognitive complexity
- [ ] تحسين function parameters
- [ ] refactoring components

## الدعم

إذا واجهت أي مشاكل:
1. راجع ملف `SONAR_FIXES.md` للتفاصيل
2. تحقق من logs السكريبت
3. استخدم `-DryRun` للمعاينة أولاً

## المساهمة

عند إضافة ثوابت جديدة:
1. أضفها في `_constants.sql`
2. حدّث السكريبت `fix-sonar-sql-constants.ps1`
3. حدّث هذا الملف

---

**آخر تحديث**: 2025
**الحالة**: جاري العمل
