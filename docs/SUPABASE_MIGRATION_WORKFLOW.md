# Supabase migration workflow

This repository treats migrations already applied to the linked project as immutable.
The rule prevents a tidy local folder from silently diverging from production history.

## Daily changes

1. Run `supabase migration list` before creating database changes.
2. If the latest owning migration is still unapplied, extend that file instead of adding
   another correction file.
3. If it is already applied, create one forward-only migration containing the complete
   change for that object.
4. Keep all definitions of the same function, view, trigger, policy, or index in one new
   migration for the current pull request.
5. Run:

   ```powershell
   npm run test:migrations
   npm run audit:migrations
   npx supabase db push --dry-run
   ```

The migration guard reads `supabase/migration-policy.json`. It rejects changes to versions
at or below `immutableThrough`, backdated additions, duplicate timestamps, and repeated SQL
object definitions across newly added migration files.

After a successful production migration, update `immutableThrough` in the same deployment
commit (or an immediate follow-up commit) to the newest applied version.

## Reducing the existing file count

Historical migrations are an audit log, not runtime code. Their count does not add query
load to Supabase. Reduce them only as a full baseline operation:

1. Create a production restore point.
2. Export the canonical `public` and `private` schemas with the official Supabase CLI.
3. Generate the baseline from that export. Do not concatenate historical SQL or select
   definitions with a regular expression.
4. Restore one disposable database from all historical migrations.
5. Restore a second disposable database from the baseline only.
6. Compare tables, columns, constraints, functions, views, triggers, RLS policies, grants,
   indexes, publications, and generated TypeScript types.
7. Restore DML omitted by `supabase migration squash`, including seed rows, cron jobs,
   storage setup, and Vault configuration.
8. Run application tests and smoke tests against the baseline database.
9. Archive old files and repair remote history only after the schemas are identical and a
   separate production approval has been given.

Until these gates pass, consolidated output belongs in
`supabase/migrations_consolidated_draft`, never in `supabase/migrations`.
