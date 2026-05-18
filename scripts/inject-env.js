// Vercel build script — runs before deployment.
// Replaces placeholders in dyp-supabase.js with real env var values.
// Set SUPABASE_URL and SUPABASE_ANON_KEY in Vercel Dashboard → Settings → Environment Variables.

const fs   = require('fs');
const path = require('path');

const target = path.join(__dirname, '..', 'js', 'dyp-supabase.js');
let src = fs.readFileSync(target, 'utf-8');

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;

if (!url) { console.error('ERROR: SUPABASE_URL env var is not set.'); process.exit(1); }
if (!key) { console.error('ERROR: SUPABASE_ANON_KEY env var is not set.'); process.exit(1); }

src = src
  .replace('__SUPABASE_URL__', url)
  .replace('__SUPABASE_ANON_KEY__', key);

fs.writeFileSync(target, src);
console.log('Supabase config injected.');
