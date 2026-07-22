-- Storage bucket rows are data and are intentionally absent from schema squashes.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/gif']),
  ('employee-documents', 'employee-documents', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('advance-attachments', 'advance-attachments', false, 5242880, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'image/webp']),
  ('invoice-attachments', 'invoice-attachments', false, 8388608, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'image/webp']),
  ('vehicle-documents', 'vehicle-documents', false, 8388608, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'image/webp'])
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
