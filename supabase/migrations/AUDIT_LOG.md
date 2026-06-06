# Migrations Audit Log

## Recent 13 Migrations Audit (System Health Fixes)

Due to recent instability and an infinite recursion issue in the RLS (Row Level Security) policies, 13 consecutive migrations were applied to the database. This log serves to document the sequence of events and prevent similar issues from reoccurring.

### The Infinite Recursion RLS Issue
- **Root Cause**: A policy was created that queried the same table it was trying to protect, or relied on a view/function that queried the protected table, resulting in a recursive loop during evaluation.
- **Impact**: Database queries hung or timed out, causing failures in both `dev` and `production` environments when data was accessed.
- **Resolution**: The final migration reverted the problematic logic, ensuring that policies only reference external context (e.g., `auth.uid()`) or use security-definer functions that bypass RLS where necessary, breaking the infinite loop.

### Actions Taken
1. All 13 migrations have been committed to source control.
2. We verified the database state using `supabase db push --dry-run` to ensure the local schema exactly matches the migrations history.
3. RLS policies must be manually tested across all user roles (`admin`, `hr`, `finance`, `viewer`) before deploying any future policy changes.

**Warning**: Do NOT introduce `SELECT` statements inside RLS policies that target the same table without extreme caution or without using a separate lookup table.
