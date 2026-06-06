# SonarCloud Issues Report

Total Issues: 513

## Rule: javascript:S7772
- Count: 11
  - salahmostava-sys_MuhimmatAltawseel:fix.js (Line 1): Prefer `node:fs` over `fs`.
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/fix_auth_role.js (Line 1): Prefer `node:child_process` over `child_process`.
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/fix_auth_role.js (Line 2): Prefer `node:fs` over `fs`.
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/fix_remaining_auth_uid.js (Line 1): Prefer `node:child_process` over `child_process`.
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/fix_remaining_auth_uid.js (Line 2): Prefer `node:fs` over `fs`.
  - ... and 6 more

## Rule: javascript:S7781
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:fix.js (Line 12): Prefer `String#replaceAll()` over `String#replace()`.
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/generate_fk_indexes.js (Line 47): Prefer `String#replaceAll()` over `String#replace()`.

## Rule: plsql:S1192
- Count: 218
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000010_fix_remaining_auth_rls.sql (Line 5): Define a constant instead of duplicating this literal 5 times.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000010_fix_remaining_auth_rls.sql (Line 5): Define a constant instead of duplicating this literal 5 times.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000010_fix_remaining_auth_rls.sql (Line 5): Define a constant instead of duplicating this literal 5 times.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000011_fix_auth_role_warnings.sql (Line 5): Define a constant instead of duplicating this literal 5 times.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000011_fix_auth_role_warnings.sql (Line 22): Define a constant instead of duplicating this literal 10 times.
  - ... and 213 more

## Rule: javascript:S7735
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:scripts/database/generate_rls.js (Line 65): Unexpected negated condition.

## Rule: plsql:LiteralsNonPrintableCharactersCheck
- Count: 4
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000003_fix_enum_search_path_and_duplicate_indexes.sql (Line 40): An illegal character with code point 10 was found in this literal.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000003_fix_enum_search_path_and_duplicate_indexes.sql (Line 47): An illegal character with code point 10 was found in this literal.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000003_fix_enum_search_path_and_duplicate_indexes.sql (Line 54): An illegal character with code point 10 was found in this literal.
  - salahmostava-sys_MuhimmatAltawseel:supabase/migrations/20260606000003_fix_enum_search_path_and_duplicate_indexes.sql (Line 61): An illegal character with code point 10 was found in this literal.

## Rule: typescript:S2933
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/CardErrorBoundary.tsx (Line 30): Member 'handleRetry' is never reassigned; mark it as `readonly`.

## Rule: python:S1515
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix_migrations.py (Line 26): Add a parameter to function "replace_policy" and use variable "content" as its default value;The value of "content" might change at the next loop iteration.
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix_migrations.py (Line 43): Add a parameter to function "replace_trigger" and use variable "content" as its default value;The value of "content" might change at the next loop iteration.

## Rule: typescript:S3358
- Count: 19
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/apps/components/AppEmployeesPanel.tsx (Line 60): Extract this nested ternary operation into an independent statement.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/dashboard/components/DashboardSupervisorTargetsCard.tsx (Line 36): Extract this nested ternary operation into an independent statement.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/apps/pages/AppsPage.tsx (Line 83): Extract this nested ternary operation into an independent statement.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/dashboard/components/DashboardHeader.tsx (Line 54): Extract this nested ternary operation into an independent statement.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/fuel/components/FuelSpreadsheetView.tsx (Line 435): Extract this nested ternary operation into an independent statement.
  - ... and 14 more

## Rule: typescript:S7735
- Count: 7
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/lib/utils.ts (Line 15): Unexpected negated condition.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/dashboard/lib/performanceEngine.ts (Line 468): Unexpected negated condition.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/documents/pages/DocumentsPage.tsx (Line 195): Unexpected negated condition.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/AiAnalyticsPage.tsx (Line 278): Unexpected negated condition.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/EmployeeTiers.tsx (Line 112): Unexpected negated condition.
  - ... and 2 more

## Rule: javascript:S7776
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:api/_lib.js (Line 40): `ALLOWED_ORIGINS` should be a `Set`, and use `ALLOWED_ORIGINS.has()` to check existence or non-existence.

## Rule: typescript:S4325
- Count: 88
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/providers/LanguageContext.tsx (Line 11): This assertion is unnecessary since the receiver accepts the original type of the expression.
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/providers/MobileSidebarContext.tsx (Line 11): This assertion is unnecessary since the receiver accepts the original type of the expression.
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/providers/ThemeContext.tsx (Line 15): This assertion is unnecessary since the receiver accepts the original type of the expression.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/attendance/components/DailyAttendance.tsx (Line 254): This assertion is unnecessary since the receiver accepts the original type of the expression.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/orders/hooks/useSpreadsheetGrid.ts (Line 297): This assertion is unnecessary since the receiver accepts the original type of the expression.
  - ... and 83 more

## Rule: typescript:S6754
- Count: 3
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/providers/TemporalContext.tsx (Line 24): useState call is not destructured into value + setter pair
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/SalarySchemes.tsx (Line 234): useState call is not destructured into value + setter pair
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/SalarySchemes.tsx (Line 296): useState call is not destructured into value + setter pair

## Rule: css:S7924
- Count: 4
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/styles/index.css (Line 356): Text does not meet the minimal contrast requirement with its background.
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/styles/index.css (Line 363): Text does not meet the minimal contrast requirement with its background.
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/styles/index.css (Line 370): Text does not meet the minimal contrast requirement with its background.
  - salahmostava-sys_MuhimmatAltawseel:frontend/app/styles/index.css (Line 377): Text does not meet the minimal contrast requirement with its background.

## Rule: typescript:S107
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/advances/hooks/useAdvanceTable.ts (Line 36): Function 'useAdvanceTable' has too many parameters (10). Maximum allowed is 7.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/lib/alertsBuilder.ts (Line 274): Function 'buildAlertsFromResponses' has too many parameters (8). Maximum allowed is 7.

## Rule: typescript:S4323
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/dashboard/lib/aiInsightsEngine.ts (Line 406): Replace this union type with a type alias.

## Rule: typescript:S4624
- Count: 6
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/dashboard/lib/performanceEngine.ts (Line 294): Refactor this code to not use nested template literals.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/employees/components/EmployeeKPIs.tsx (Line 284): Refactor this code to not use nested template literals.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/orders/utils/spreadsheetFileOps.ts (Line 181): Refactor this code to not use nested template literals.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/orders/utils/spreadsheetFileOps.ts (Line 214): Refactor this code to not use nested template literals.
  - salahmostava-sys_MuhimmatAltawseel:supabase/functions/ai-chat/index.ts (Line 205): Refactor this code to not use nested template literals.
  - ... and 1 more

## Rule: typescript:S6847
- Count: 3
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/employees/components/EmployeeTable.tsx (Line 214): Non-interactive elements should not be assigned mouse or keyboard event listeners.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/leaves/components/AddLeaveModal.tsx (Line 69): Non-interactive elements should not be assigned mouse or keyboard event listeners.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/performance/components/AddReviewModal.tsx (Line 131): Non-interactive elements should not be assigned mouse or keyboard event listeners.

## Rule: typescript:S6819
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/employees/components/EmployeeTable.tsx (Line 214): Use <details>, <fieldset>, <optgroup>, or <address> instead of the "group" role to ensure accessibility across all devices.

## Rule: typescript:S6772
- Count: 7
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/maintenance/pages/MaintenancePage.tsx (Line 83): Ambiguous spacing after previous element span
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 111): Ambiguous spacing before next element span
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/platform-accounts/components/PlatformAccountDialog.tsx (Line 100): Ambiguous spacing before next element strong
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/platform-accounts/components/PlatformAssignDialog.tsx (Line 103): Ambiguous spacing before next element span
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/platform-accounts/components/PlatformAssignDialog.tsx (Line 111): Ambiguous spacing before next element span
  - ... and 2 more

## Rule: typescript:S6582
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/AiAnalyticsPage.tsx (Line 434): Prefer using an optional chain expression instead, as it's more concise and easier to read.
  - salahmostava-sys_MuhimmatAltawseel:supabase/functions/admin-update-user/index.ts (Line 35): Prefer using an optional chain expression instead, as it's more concise and easier to read.

## Rule: typescript:S6478
- Count: 3
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/EmployeeTiers.tsx (Line 708): Move this component definition out of the parent component and pass data as props.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/ui/calendar.tsx (Line 45): Move this component definition out of the parent component and pass data as props.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/ui/calendar.tsx (Line 46): Move this component definition out of the parent component and pass data as props.

## Rule: typescript:S6606
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/SalarySchemes.tsx (Line 404): Prefer using nullish coalescing operator (`??`) instead of a ternary expression, as it is simpler to read.

## Rule: typescript:S6844
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/SettingsHubOptimized.tsx (Line 215): The href attribute requires a valid value to be accessible. Provide a valid, navigable address as the href value. If you cannot provide a valid href, but still need the element to resemble a link, use a button and change it with appropriate styles.

## Rule: typescript:S6853
- Count: 7
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 142): A form label must be associated with a control.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 153): A form label must be associated with a control.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 159): A form label must be associated with a control.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 165): A form label must be associated with a control.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/pages/VehicleAssignment.tsx (Line 232): A form label must be associated with a control.
  - ... and 2 more

## Rule: typescript:S6825
- Count: 4
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTable.tsx (Line 465): aria-hidden="true" must not be set on focusable elements.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTable.tsx (Line 532): aria-hidden="true" must not be set on focusable elements.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTable.tsx (Line 580): aria-hidden="true" must not be set on focusable elements.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/orders/OrdersGridTable.tsx (Line 234): aria-hidden="true" must not be set on focusable elements.

## Rule: typescript:S6848
- Count: 4
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTableCells.tsx (Line 42): Avoid non-native interactive elements. If using native HTML is not possible, add an appropriate role and support for tabbing, mouse, keyboard, and touch inputs to an interactive content element.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTableCells.tsx (Line 94): Avoid non-native interactive elements. If using native HTML is not possible, add an appropriate role and support for tabbing, mouse, keyboard, and touch inputs to an interactive content element.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/components/SalaryTableCells.tsx (Line 97): Avoid non-native interactive elements. If using native HTML is not possible, add an appropriate role and support for tabbing, mouse, keyboard, and touch inputs to an interactive content element.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/orders/OrdersCellPopover.tsx (Line 97): Avoid non-native interactive elements. If using native HTML is not possible, add an appropriate role and support for tabbing, mouse, keyboard, and touch inputs to an interactive content element.

## Rule: typescript:S1874
- Count: 7
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/hooks/useBatchPdfExport.ts (Line 91): The signature '(...text: string[]): void' of 'iDoc.write' is deprecated.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/hooks/useSalaryPrint.ts (Line 81): The signature '(...text: string[]): void' of 'win.document.write' is deprecated.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/hooks/useSalaryPrint.ts (Line 118): The signature '(...text: string[]): void' of 'win.document.write' is deprecated.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salarySlipActions.ts (Line 55): The signature '(...text: string[]): void' of 'iframeDoc.write' is deprecated.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salarySlipActions.ts (Line 67): The signature '(...text: string[]): void' of 'win.document.write' is deprecated.
  - ... and 2 more

## Rule: typescript:S7778
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/buildSalarySlipFields.ts (Line 54): Do not call `Array#push()` multiple times.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/buildSalarySlipFields.ts (Line 61): Do not call `Array#push()` multiple times.

## Rule: typescript:S6551
- Count: 14
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salaryDomain.ts (Line 181): 'row.employee_id || ''' will use Object's default stringification format ('[object Object]') when stringified.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salaryDomain.ts (Line 445): 'emp.name || ''' will use Object's default stringification format ('[object Object]') when stringified.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salaryDomain.ts (Line 446): 'emp.job_title || 'مندوب توصيل'' will use Object's default stringification format ('[object Object]') when stringified.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salaryDomain.ts (Line 447): 'emp.national_id || '•'' will use Object's default stringification format ('[object Object]') when stringified.
  - salahmostava-sys_MuhimmatAltawseel:frontend/modules/salaries/lib/salaryDomain.ts (Line 450): 'emp.iban' will use Object's default stringification format ('[object Object]') when stringified.
  - ... and 9 more

## Rule: typescript:S6571
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/services/supabase/types.ts (Line 2992): 'never' is overridden by other types in this union type.

## Rule: typescript:S6850
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/ui/alert.tsx (Line 31): Headings must have content and the content must be accessible by a screen reader.
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/ui/card.tsx (Line 19): Headings must have content and the content must be accessible by a screen reader.

## Rule: typescript:S6747
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:frontend/shared/components/ui/command.tsx (Line 42): Unknown property 'cmdk-input-wrapper' found

## Rule: powershelldre:S8620
- Count: 53
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-mechanical.ps1 (Line 19): Remove trailing whitespace from this line
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-mechanical.ps1 (Line 23): Remove trailing whitespace from this line
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-mechanical.ps1 (Line 26): Remove trailing whitespace from this line
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-mechanical.ps1 (Line 27): Remove trailing whitespace from this line
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-mechanical.ps1 (Line 30): Remove trailing whitespace from this line
  - ... and 48 more

## Rule: powershelldre:S8677
- Count: 3
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-sql-constants.ps1 (Line 86): Replace 'Write-Host' with a pipeline-compatible cmdlet such as 'Write-Output'.
  - salahmostava-sys_MuhimmatAltawseel:scripts/system-audit.ps1 (Line 17): Replace 'Write-Host' with a pipeline-compatible cmdlet such as 'Write-Output'.
  - salahmostava-sys_MuhimmatAltawseel:scripts/system-audit.ps1 (Line 18): Replace 'Write-Host' with a pipeline-compatible cmdlet such as 'Write-Output'.

## Rule: powershelldre:S8626
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-sql-constants.ps1 (Line 124): '$matches' is a PowerShell automatic variable; use a different variable name.
  - salahmostava-sys_MuhimmatAltawseel:scripts/fix-sonar-sql-constants.ps1 (Line 148): '$matches' is a PowerShell automatic variable; use a different variable name.

## Rule: javascript:S6397
- Count: 1
  - salahmostava-sys_MuhimmatAltawseel:scripts/gen-types.mjs (Line 19): Replace this character class by the character itself.

## Rule: plsql:OrderByExplicitAscCheck
- Count: 9
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/maintenance_system_tests.sql (Line 40): Add ASC in order to make the order explicit.
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/maintenance_system_tests.sql (Line 58): Add ASC in order to make the order explicit.
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/maintenance_system_tests.sql (Line 189): Add ASC in order to make the order explicit.
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/maintenance_system_tests.sql (Line 189): Add ASC in order to make the order explicit.
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/phase_1_5_validation_checks.sql (Line 29): Add ASC in order to make the order explicit.
  - ... and 4 more

## Rule: plsql:S1138
- Count: 2
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/phase_1_5_validation_checks.sql (Line 163): Refactor this SQL query to eliminate the use of EXISTS.
  - salahmostava-sys_MuhimmatAltawseel:supabase/oneoff/phase_1_5_validation_checks.sql (Line 170): Refactor this SQL query to eliminate the use of EXISTS.

