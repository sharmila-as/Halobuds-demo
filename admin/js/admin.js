// admin/js/admin.js — Shared admin utilities

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// ─── Config (same as main site) ──────────────────────────────────────────────
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ─── Auth Guard ───────────────────────────────────────────────────────────────
export async function requireAdmin() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) { window.location.href = '../pages/login.html?redirect=../admin/index.html'; return null; }

  const { data: profile } = await supabase.from('profiles').select('is_admin,first_name,last_name').eq('id', user.id).single();
  if (!profile?.is_admin) {
    document.body.innerHTML = `<div style="display:flex;align-items:center;justify-content:center;min-height:100vh;font-family:Jost,sans-serif;text-align:center;"><div><div style="font-size:3rem;margin-bottom:1rem">🚫</div><h2 style="font-size:1.5rem;color:#1a1a2e;margin-bottom:.5rem">Access Denied</h2><p style="color:#666">You don't have admin permissions.</p><a href="../index.html" style="color:#6B3FA0;text-decoration:none;margin-top:1rem;display:inline-block">← Back to Site</a></div></div>`;
    return null;
  }

  return { user, profile };
}

// ─── Sidebar active state ─────────────────────────────────────────────────────
export function setActiveSidebarLink() {
  const current = location.pathname.split('/').pop();
  document.querySelectorAll('.admin-nav a').forEach(a => {
    const href = a.getAttribute('href');
    if (href && href.endsWith(current)) a.classList.add('active');
  });
}

// ─── Admin sign out ───────────────────────────────────────────────────────────
export async function adminSignOut() {
  await supabase.auth.signOut();
  window.location.href = '../pages/login.html';
}

// ─── Utilities ────────────────────────────────────────────────────────────────
export function formatPrice(n) {
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(n);
}

export function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

export function formatDateTime(d) {
  if (!d) return '—';
  return new Date(d).toLocaleString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function getStatusBadge(status) {
  const map = {
    pending: 'badge-pending', confirmed: 'badge-confirmed', processing: 'badge-processing',
    shipped: 'badge-shipped', delivered: 'badge-delivered', cancelled: 'badge-cancelled',
    unread: 'badge-pending', read: 'badge-confirmed', resolved: 'badge-delivered',
    approved: 'badge-delivered', rejected: 'badge-cancelled'
  };
  const labels = {
    pending: 'Pending', confirmed: 'Confirmed', processing: 'Processing',
    shipped: 'Shipped', delivered: 'Delivered', cancelled: 'Cancelled',
    unread: 'Unread', read: 'Read', resolved: 'Resolved',
    approved: 'Approved', rejected: 'Rejected'
  };
  return `<span class="badge ${map[status]||'badge-pending'}">${labels[status]||status}</span>`;
}

export function showToast(msg, type = 'success') {
  const t = document.createElement('div');
  t.className = `admin-toast admin-toast-${type}`;
  t.textContent = msg;
  document.body.appendChild(t);
  requestAnimationFrame(() => t.classList.add('show'));
  setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 300); }, 3000);
}

export function debounce(fn, delay = 300) {
  let timer;
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), delay); };
}

// Confirm dialog wrapper
export function confirm(msg) {
  return new Promise(resolve => {
    if (window.confirm(msg)) resolve(true); else resolve(false);
  });
}
