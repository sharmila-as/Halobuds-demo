# 🌸 Halo Buds — E-Commerce Website

**Fully Handmade & Customized Floral Accessories**

A complete e-commerce website built with HTML5, CSS3, Vanilla JS, Supabase, and Razorpay.

---

## 🗂️ Project Structure

```
halobuds/
├── index.html                  # Homepage
├── css/
│   └── main.css                # Full design system
├── js/
│   └── config.js               # Supabase client + helper modules
├── pages/                      # Customer-facing pages
│   ├── shop.html
│   ├── product.html
│   ├── cart.html
│   ├── checkout.html
│   ├── order-confirmation.html
│   ├── order-detail.html
│   ├── track-order.html
│   ├── search.html
│   ├── wishlist.html
│   ├── custom-order.html
│   ├── account.html
│   ├── login.html
│   ├── register.html
│   ├── forgot-password.html
│   ├── reset-password.html
│   ├── about.html
│   ├── contact.html
│   └── faq.html
├── admin/                      # Admin panel
│   ├── index.html              # Dashboard
│   ├── orders.html
│   ├── products.html
│   ├── categories.html
│   ├── banners.html
│   ├── customers.html
│   ├── reviews.html
│   ├── messages.html
│   ├── custom-requests.html
│   ├── css/
│   │   └── admin.css
│   └── js/
│       └── admin.js
└── supabase-schema.sql         # Full database schema
```

---

## 🚀 Setup Instructions

### Step 1 — Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your **Project URL** and **anon public key** (Settings → API)

### Step 2 — Run the Database Schema

1. Go to **Supabase Dashboard → SQL Editor**
2. Paste the contents of `supabase-schema.sql` and run it
3. This creates all tables, RLS policies, triggers, and seed data

### Step 3 — Configure API Keys

Replace placeholders in **two files**:

**`js/config.js`** (lines 3–4):
```js
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';
```

**`admin/js/admin.js`** (lines 4–5):
```js
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';
```

**`pages/checkout.html`** — find `RAZORPAY_KEY` constant and replace:
```js
const RAZORPAY_KEY = 'rzp_live_YOUR_KEY_HERE';
```

### Step 4 — Create Storage Buckets

In **Supabase Dashboard → Storage**, create these buckets:

| Bucket Name     | Public? | Purpose                        |
|-----------------|---------|--------------------------------|
| `products`      | ✅ Yes  | Product images                 |
| `banners`       | ✅ Yes  | Homepage hero banner images    |
| `avatars`       | ✅ Yes  | User profile photos            |
| `reviews`       | ✅ Yes  | Review photos                  |
| `gallery`       | ✅ Yes  | Instagram-style gallery        |
| `custom-orders` | ❌ No   | Reference images (private)     |

### Step 5 — Set Up Admin Access

1. Register a new account on the site (via `/pages/register.html`)
2. In **Supabase → SQL Editor**, run:

```sql
UPDATE profiles
SET is_admin = TRUE
WHERE id = 'YOUR_USER_UUID_HERE';
```

Find your UUID in **Supabase → Authentication → Users**.

3. Access the admin panel at `/admin/index.html`

### Step 6 — Configure Email (for Auth)

In **Supabase → Authentication → Email Templates**, customise:
- **Confirm signup** email
- **Reset password** email (the link should go to `/pages/reset-password.html`)

Set your **Site URL** in Supabase → Authentication → URL Configuration:
```
https://yourdomain.com
```

Add redirect URLs:
```
https://yourdomain.com/pages/reset-password.html
http://localhost:3000/pages/reset-password.html
```

---

## 💳 Razorpay Setup

1. Create an account at [razorpay.com](https://razorpay.com)
2. Get your **Key ID** from Dashboard → Settings → API Keys
3. Replace `RAZORPAY_KEY` in `pages/checkout.html`
4. For production, also set up a **webhook** to update `payment_status` in orders

---

## 🎨 Design System

### Colour Palette
| Variable              | Hex       | Usage                    |
|-----------------------|-----------|--------------------------|
| `--purple-brand`      | `#6B3FA0` | Primary brand colour     |
| `--purple-deep`       | `#4A2878` | Dark purple (headers)    |
| `--purple-mid`        | `#8B5CF6` | Accents                  |
| `--purple-pale`       | `#F3ECFF` | Light backgrounds        |
| `--pink-blush`        | `#FFB7C5` | Highlights               |
| `--cream`             | `#FDFBFF` | Page background          |

### Typography
| Font                  | Weight        | Usage                    |
|-----------------------|---------------|--------------------------|
| Cormorant Garamond    | 300, 400, 600 | Headings, display        |
| Jost                  | 300–600       | Body, UI                 |
| Great Vibes           | 400           | Script eyebrows          |

---

## 🛒 Key Features

**Customer Side**
- Product catalogue with filters, search, sorting
- Product detail with image gallery, variants, customisation options
- Cart (localStorage for guests, Supabase for logged-in)
- Cart/wishlist merge on login
- Coupon codes (HALO10, WELCOME15, SAVE20 pre-seeded)
- Checkout with Razorpay (card, UPI, net banking, COD)
- Order tracking
- Account dashboard (profile, orders, addresses, wishlist)
- Custom order request form with photo upload
- Reviews with rating (submitted, moderated before display)
- Newsletter signup

**Admin Panel**
- Dashboard with revenue, order stats, low stock alerts
- Orders management (view, update status, add tracking)
- Product CRUD (name, price, images, tags, stock, flags)
- Category management
- Homepage banner management
- Customer list with order history
- Review moderation (approve/reject)
- Contact messages inbox
- Custom order requests management

---

## 🗃️ Database Tables

| Table                    | Purpose                            |
|--------------------------|------------------------------------|
| `profiles`               | Extended user profiles             |
| `addresses`              | Saved shipping addresses           |
| `categories`             | Product categories                 |
| `products`               | Product catalogue                  |
| `product_variants`       | Size/colour variants               |
| `banners`                | Homepage hero banners              |
| `cart_items`             | Server-side cart (authenticated)   |
| `wishlist`               | User wishlists                     |
| `coupons`                | Discount codes                     |
| `orders`                 | Order records                      |
| `order_items`            | Line items per order               |
| `order_status_history`   | Status change audit log            |
| `reviews`                | Product reviews                    |
| `newsletter_subscribers` | Email subscribers                  |
| `instagram_gallery`      | Homepage gallery images            |
| `faqs`                   | FAQ content (DB-driven optional)   |
| `settings`               | Site-wide settings                 |
| `custom_order_requests`  | Custom order inquiry forms         |
| `contact_messages`       | Contact form submissions           |

---

## 🌐 Deploying

The site is pure static HTML/CSS/JS — deploy to any static host:

**Netlify (recommended)**
```bash
# Drop the halobuds/ folder into netlify.com/drop
```

**Vercel**
```bash
npx vercel ./halobuds
```

**GitHub Pages**
```bash
git init && git add . && git commit -m "Initial commit"
# Push to GitHub, enable Pages in repo settings
```

Make sure to update `SUPABASE_URL` and all redirect URLs to your production domain.

---

## ✅ Pre-Launch Checklist

- [ ] Supabase schema deployed
- [ ] `SUPABASE_URL` and `SUPABASE_ANON_KEY` updated in both config files
- [ ] Razorpay key set in `checkout.html`
- [ ] Storage buckets created
- [ ] Admin account promoted (`is_admin = true`)
- [ ] Email templates configured in Supabase
- [ ] Site URL and redirect URLs set in Supabase Auth settings
- [ ] Products added (categories first, then products)
- [ ] At least one banner added for homepage slider
- [ ] Test order placed end-to-end
- [ ] WhatsApp number updated in `contact.html` and `custom-order.html`
- [ ] Business email updated in `contact.html`

---

## 📞 Support

For questions about setup or customisation, contact the development team.

Built with 💜 for Halo Buds.
