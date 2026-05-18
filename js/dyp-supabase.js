// ─────────────────────────────────────────────────────────────
// DYP — Supabase client & auth helpers
// Replace SUPABASE_URL and SUPABASE_ANON_KEY with your project values.
// Find them: Supabase Dashboard → Settings → API
// ─────────────────────────────────────────────────────────────

const SUPABASE_URL      = 'https://fvlpmzehjiwcrdffkdmm.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_qqnDvG63Ojr3-p2OU3Vomw_5WWkb7Fv';

const { createClient } = window.supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ── Session helpers ──────────────────────────────────────────

async function getSession() {
  const { data: { session } } = await sb.auth.getSession();
  return session;
}

async function getCurrentUser() {
  const session = await getSession();
  return session?.user ?? null;
}

async function getUserProfile(userId) {
  const { data, error } = await sb.from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) return null;
  return data;
}

// Redirect to login if not authenticated; returns user or null
async function requireAuth(redirectTo = '/login') {
  const user = await getCurrentUser();
  if (!user) {
    window.location.href = redirectTo;
    return null;
  }
  return user;
}

// Redirect to admin-login if not authenticated admin; returns {user, profile} or null
async function requireAdmin(redirectTo = '/admin-login') {
  const user = await getCurrentUser();
  if (!user) {
    window.location.href = redirectTo;
    return null;
  }
  const profile = await getUserProfile(user.id);
  if (!profile || profile.role !== 'admin') {
    await sb.auth.signOut();
    window.location.href = redirectTo + '?error=unauthorized';
    return null;
  }
  return { user, profile };
}

async function signOut(redirectTo = '/') {
  await sb.auth.signOut();
  window.location.href = redirectTo;
}

// ── Auth-aware nav update ────────────────────────────────────

async function updateAuthNav() {
  const user = await getCurrentUser();
  const loginLink  = document.getElementById('nav-login');
  const signupLink = document.getElementById('nav-signup');
  const userMenu   = document.getElementById('nav-user-menu');
  const userName   = document.getElementById('nav-user-name');
  const logoutBtn  = document.getElementById('nav-logout');

  if (user) {
    if (loginLink)  loginLink.style.display  = 'none';
    if (signupLink) signupLink.style.display = 'none';
    if (userMenu)   userMenu.style.display   = 'flex';
    if (userName) {
      const profile = await getUserProfile(user.id);
      userName.textContent = profile?.full_name?.split(' ')[0] || user.email.split('@')[0];
    }
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => signOut('/'));
    }
  } else {
    if (loginLink)  loginLink.style.display  = '';
    if (signupLink) signupLink.style.display = '';
    if (userMenu)   userMenu.style.display   = 'none';
  }
}

// ── Logo upload to Supabase Storage ─────────────────────────

async function uploadLogo(file, userId) {
  const ext  = file.name.split('.').pop();
  const path = `${userId}/${Date.now()}.${ext}`;

  const { data, error } = await sb.storage
    .from('logos')
    .upload(path, file, { upsert: true });

  if (error) return null;

  const { data: urlData } = sb.storage
    .from('logos')
    .getPublicUrl(path);

  return urlData?.publicUrl ?? null;
}

// ── Sanitize text input (strip HTML tags) ───────────────────
function sanitize(str) {
  return String(str ?? '').replace(/[<>"'&]/g, c => ({
    '<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;','&':'&amp;'
  }[c]));
}
