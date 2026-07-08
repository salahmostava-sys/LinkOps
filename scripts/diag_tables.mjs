import pg from 'pg';
const { Client } = pg;
const client = new Client({
  host: 'aws-1-ap-south-1.pooler.supabase.com',
  port: 5432,
  user: 'cli_login_postgres.plxpehtkabmfkdlgjyin',
  password: 'neSIvtFYOSVkqpdNaEWPxMkAyKqNWiLg',
  database: 'postgres',
  ssl: { rejectUnauthorized: false }
});
await client.connect();
const r1 = await client.query(`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' LIMIT 5`);
console.log('information_schema tables:', r1.rows);
const r2 = await client.query(`SELECT tablename FROM pg_tables WHERE schemaname='public' LIMIT 5`);
console.log('pg_tables:', r2.rows);
const r3 = await client.query(`SELECT current_schema(), current_user, session_user`);
console.log('session info:', r3.rows);
await client.end();
