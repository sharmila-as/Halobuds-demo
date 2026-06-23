// ============================================
// HALO BUDS - Supabase Configuration
// ============================================
// Replace with your actual Supabase project credentials

const SUPABASE_CONFIG = {
  url: 'https://kxyrutlhhltwicunchwx.supabase.co',           // e.g., https://xyzabc.supabase.co
  anonKey: 'sb_publishable_OlQC2qzD20XS0nb3pUM6XA_3FcV5ISb',  // Your public anon key
};

const RAZORPAY_CONFIG = {
  keyId: 'YOUR_RAZORPAY_KEY_ID',      // e.g., rzp_test_xxxxxxxx
};

// DO NOT expose your secret keys here - use Supabase Edge Functions for that

// Initialize Supabase client
const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);

// ============================================
// AUTH HELPERS
// ============================================
const Auth = {
  async signUp(email, password, fullName) {
    const { data, error } = await supabaseClient.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } }
    });
    return { data, error };
  },

  async signIn(email, password) {
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    return { data, error };
  },

  async signOut() {
    const { error } = await supabaseClient.auth.signOut();
    return { error };
  },

  async getUser() {
    const { data: { user } } = await supabaseClient.auth.getUser();
    return user;
  },

  async getProfile() {
    const user = await this.getUser();
    if (!user) return null;
    const { data } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();
    return data;
  },

  async resetPassword(email) {
    const { error } = await supabaseClient.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/pages/reset-password.html`
    });
    return { error };
  },

  async updatePassword(newPassword) {
    const { error } = await supabaseClient.auth.updateUser({ password: newPassword });
    return { error };
  },

  onAuthStateChange(callback) {
    return supabaseClient.auth.onAuthStateChange(callback);
  }
};

// ============================================
// PRODUCT HELPERS
// ============================================
const Products = {
  async getAll({ category, search, sort = 'created_at', featured, bestseller, newArrival, limit = 20, offset = 0 } = {}) {
    let query = supabaseClient
      .from('products')
      .select('*, categories(name, slug)')
      .eq('is_active', true);

    if (category) query = query.eq('category_id', category);
    if (featured) query = query.eq('is_featured', true);
    if (bestseller) query = query.eq('is_bestseller', true);
    if (newArrival) query = query.eq('is_new_arrival', true);
    if (search) query = query.ilike('name', `%${search}%`);

    const sortMap = {
      'price_asc': { column: 'price', ascending: true },
      'price_desc': { column: 'price', ascending: false },
      'rating': { column: 'rating', ascending: false },
      'newest': { column: 'created_at', ascending: false },
      'popular': { column: 'review_count', ascending: false },
    };
    const s = sortMap[sort] || { column: 'created_at', ascending: false };
    query = query.order(s.column, { ascending: s.ascending });
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;
    return { data, error, count };
  },

  async getBySlug(slug) {
    const { data, error } = await supabaseClient
      .from('products')
      .select('*, categories(name, slug), product_variants(*)')
      .eq('slug', slug)
      .eq('is_active', true)
      .single();
    return { data, error };
  },

  async getById(id) {
    const { data, error } = await supabaseClient
      .from('products')
      .select('*, categories(name, slug), product_variants(*)')
      .eq('id', id)
      .single();
    return { data, error };
  },

  async getReviews(productId) {
    const { data, error } = await supabaseClient
      .from('reviews')
      .select('*, profiles(full_name, avatar_url)')
      .eq('product_id', productId)
      .eq('is_approved', true)
      .order('created_at', { ascending: false });
    return { data, error };
  }
};

// ============================================
// CATEGORY HELPERS
// ============================================
const Categories = {
  async getAll() {
    const { data, error } = await supabaseClient
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order');
    return { data, error };
  },

  async getBySlug(slug) {
    const { data, error } = await supabaseClient
      .from('categories')
      .select('*')
      .eq('slug', slug)
      .single();
    return { data, error };
  }
};

// ============================================
// CART HELPERS
// ============================================
const Cart = {
  async get() {
    const user = await Auth.getUser();
    if (!user) return this.getLocal();

    const { data, error } = await supabaseClient
      .from('cart_items')
      .select('*, products(*, categories(name)), product_variants(*)')
      .eq('user_id', user.id);
    return { data: data || [], error };
  },

  async add(productId, quantity = 1, variantId = null, customization = {}) {
    const user = await Auth.getUser();
    if (!user) return this.addLocal(productId, quantity, variantId, customization);

    const { data, error } = await supabaseClient
      .from('cart_items')
      .upsert({
        user_id: user.id,
        product_id: productId,
        variant_id: variantId,
        quantity,
        customization
      }, { onConflict: 'user_id,product_id,variant_id' });

    this.updateCartBadge();
    return { data, error };
  },

  async updateQuantity(itemId, quantity) {
    const user = await Auth.getUser();
    if (!user) return this.updateLocalQuantity(itemId, quantity);

    if (quantity <= 0) return this.remove(itemId);

    const { data, error } = await supabaseClient
      .from('cart_items')
      .update({ quantity })
      .eq('id', itemId);
    return { data, error };
  },

  async remove(itemId) {
    const user = await Auth.getUser();
    if (!user) return this.removeLocal(itemId);

    const { error } = await supabaseClient
      .from('cart_items')
      .delete()
      .eq('id', itemId);
    this.updateCartBadge();
    return { error };
  },

  async clear() {
    const user = await Auth.getUser();
    if (!user) { localStorage.removeItem('hb_cart'); this.updateCartBadge(); return; }
    await supabaseClient.from('cart_items').delete().eq('user_id', user.id);
    this.updateCartBadge();
  },

  async getCount() {
    const { data } = await this.get();
    return data ? data.reduce((sum, item) => sum + item.quantity, 0) : 0;
  },

  async updateCartBadge() {
    const count = await this.getCount();
    document.querySelectorAll('.cart-badge').forEach(el => {
      el.textContent = count;
      el.style.display = count > 0 ? 'flex' : 'none';
    });
  },

  // Local storage cart for guests
  getLocal() {
    const cart = JSON.parse(localStorage.getItem('hb_cart') || '[]');
    return { data: cart, error: null };
  },

  addLocal(productId, quantity, variantId, customization) {
    const cart = JSON.parse(localStorage.getItem('hb_cart') || '[]');
    const existingIdx = cart.findIndex(i => i.product_id === productId && i.variant_id === variantId);
    if (existingIdx > -1) {
      cart[existingIdx].quantity += quantity;
    } else {
      cart.push({ id: Date.now().toString(), product_id: productId, variant_id: variantId, quantity, customization });
    }
    localStorage.setItem('hb_cart', JSON.stringify(cart));
    this.updateCartBadge();
    return { data: cart, error: null };
  },

  updateLocalQuantity(itemId, quantity) {
    const cart = JSON.parse(localStorage.getItem('hb_cart') || '[]');
    const idx = cart.findIndex(i => i.id === itemId);
    if (idx > -1) {
      if (quantity <= 0) cart.splice(idx, 1);
      else cart[idx].quantity = quantity;
    }
    localStorage.setItem('hb_cart', JSON.stringify(cart));
    return { error: null };
  },

  removeLocal(itemId) {
    const cart = JSON.parse(localStorage.getItem('hb_cart') || '[]');
    const filtered = cart.filter(i => i.id !== itemId);
    localStorage.setItem('hb_cart', JSON.stringify(filtered));
    this.updateCartBadge();
    return { error: null };
  },

  async mergeLocalToCloud() {
    const localCart = JSON.parse(localStorage.getItem('hb_cart') || '[]');
    if (localCart.length === 0) return;
    for (const item of localCart) {
      await this.add(item.product_id, item.quantity, item.variant_id, item.customization);
    }
    localStorage.removeItem('hb_cart');
  }
};

// ============================================
// WISHLIST HELPERS
// ============================================
const Wishlist = {
  async get() {
    const user = await Auth.getUser();
    if (!user) return { data: JSON.parse(localStorage.getItem('hb_wishlist') || '[]'), error: null };

    const { data, error } = await supabaseClient
      .from('wishlist')
      .select('*, products(*, categories(name))')
      .eq('user_id', user.id);
    return { data: data || [], error };
  },

  async toggle(productId) {
    const user = await Auth.getUser();
    if (!user) {
      const list = JSON.parse(localStorage.getItem('hb_wishlist') || '[]');
      const idx = list.indexOf(productId);
      if (idx > -1) list.splice(idx, 1);
      else list.push(productId);
      localStorage.setItem('hb_wishlist', JSON.stringify(list));
      return { added: idx === -1 };
    }

    const { data: existing } = await supabaseClient
      .from('wishlist')
      .select('id')
      .eq('user_id', user.id)
      .eq('product_id', productId)
      .single();

    if (existing) {
      await supabaseClient.from('wishlist').delete().eq('id', existing.id);
      return { added: false };
    } else {
      await supabaseClient.from('wishlist').insert({ user_id: user.id, product_id: productId });
      return { added: true };
    }
  },

  async isInWishlist(productId) {
    const user = await Auth.getUser();
    if (!user) {
      const list = JSON.parse(localStorage.getItem('hb_wishlist') || '[]');
      return list.includes(productId);
    }
    const { data } = await supabaseClient
      .from('wishlist')
      .select('id')
      .eq('user_id', user.id)
      .eq('product_id', productId)
      .single();
    return !!data;
  }
};

// ============================================
// ORDER HELPERS
// ============================================
const Orders = {
  async create(orderData) {
    const user = await Auth.getUser();
    const { data, error } = await supabaseClient
      .from('orders')
      .insert({ ...orderData, user_id: user?.id })
      .select()
      .single();
    return { data, error };
  },

  async addItems(orderId, items) {
    const { data, error } = await supabaseClient
      .from('order_items')
      .insert(items.map(i => ({ ...i, order_id: orderId })));
    return { data, error };
  },

  async getMyOrders() {
    const user = await Auth.getUser();
    if (!user) return { data: [], error: null };
    const { data, error } = await supabaseClient
      .from('orders')
      .select('*, order_items(*, products(name, images))')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    return { data: data || [], error };
  },

  async getById(orderId) {
    const { data, error } = await supabaseClient
      .from('orders')
      .select('*, order_items(*, products(name, images)), order_status_history(*)')
      .eq('id', orderId)
      .single();
    return { data, error };
  },

  async getByNumber(orderNumber) {
    const { data, error } = await supabaseClient
      .from('orders')
      .select('*, order_items(*), order_status_history(*)')
      .eq('order_number', orderNumber)
      .single();
    return { data, error };
  },

  async updatePayment(orderId, paymentData) {
    const { data, error } = await supabaseClient
      .from('orders')
      .update(paymentData)
      .eq('id', orderId)
      .select()
      .single();
    return { data, error };
  }
};

// ============================================
// BANNERS HELPERS
// ============================================
const Banners = {
  async getActive() {
    const { data, error } = await supabaseClient
      .from('banners')
      .select('*')
      .eq('is_active', true)
      .order('sort_order');
    return { data: data || [], error };
  }
};

// ============================================
// SETTINGS HELPERS
// ============================================
const Settings = {
  cache: {},

  async get(key) {
    if (this.cache[key]) return this.cache[key];
    const { data } = await supabaseClient
      .from('settings')
      .select('value')
      .eq('key', key)
      .single();
    if (data) this.cache[key] = data.value;
    return data?.value;
  }
};

// ============================================
// UTILITY FUNCTIONS
// ============================================
const Utils = {
  formatPrice(amount) {
    return '₹' + Number(amount).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  },

  formatDate(dateStr) {
    return new Date(dateStr).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
  },

  slugify(text) {
    return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  },

  showToast(message, type = 'success') {
    const existing = document.querySelector('.hb-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.className = `hb-toast hb-toast--${type}`;
    toast.innerHTML = `
      <span class="hb-toast__icon">${type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}</span>
      <span>${message}</span>
    `;
    document.body.appendChild(toast);
    setTimeout(() => toast.classList.add('hb-toast--show'), 10);
    setTimeout(() => { toast.classList.remove('hb-toast--show'); setTimeout(() => toast.remove(), 300); }, 3000);
  },

  getQueryParam(name) {
    return new URLSearchParams(window.location.search).get(name);
  },

  debounce(fn, delay) {
    let timer;
    return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), delay); };
  },

  getOrderStatusLabel(status) {
    const labels = {
      pending: 'Order Placed',
      confirmed: 'Confirmed',
      processing: 'Processing',
      crafting: 'Being Handcrafted',
      quality_check: 'Quality Check',
      packed: 'Packed',
      shipped: 'Shipped',
      out_for_delivery: 'Out for Delivery',
      delivered: 'Delivered',
      cancelled: 'Cancelled',
      refunded: 'Refunded'
    };
    return labels[status] || status;
  },

  getOrderStatusColor(status) {
    const colors = {
      pending: '#f59e0b',
      confirmed: '#8b5cf6',
      processing: '#8b5cf6',
      crafting: '#ec4899',
      quality_check: '#3b82f6',
      packed: '#3b82f6',
      shipped: '#10b981',
      out_for_delivery: '#10b981',
      delivered: '#059669',
      cancelled: '#ef4444',
      refunded: '#6b7280'
    };
    return colors[status] || '#6b7280';
  }
};

// Initialize cart badge on load
document.addEventListener('DOMContentLoaded', () => {
  Cart.updateCartBadge();
});
