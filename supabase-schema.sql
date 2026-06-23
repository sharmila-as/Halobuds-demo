-- ============================================
-- HALO BUDS - Complete Supabase Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE (extends Supabase auth.users)
-- ============================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('female', 'male', 'other', 'prefer_not_to_say')),
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ADDRESSES TABLE
-- ============================================
CREATE TABLE addresses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  label TEXT DEFAULT 'Home',
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  country TEXT DEFAULT 'India',
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  short_description TEXT,
  price DECIMAL(10,2) NOT NULL,
  compare_price DECIMAL(10,2),
  category_id UUID REFERENCES categories(id),
  images TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_bestseller BOOLEAN DEFAULT FALSE,
  is_new_arrival BOOLEAN DEFAULT TRUE,
  allow_customization BOOLEAN DEFAULT FALSE,
  customization_options JSONB DEFAULT '{"allow_name": false, "allow_message": false, "allow_photo": false, "allow_instructions": true}',
  stock_quantity INTEGER DEFAULT 0,
  sku TEXT,
  weight_grams INTEGER,
  materials TEXT,
  care_instructions TEXT,
  processing_days INTEGER DEFAULT 3,
  rating DECIMAL(3,2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PRODUCT VARIANTS TABLE
-- ============================================
CREATE TABLE product_variants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '{}',
  price_modifier DECIMAL(10,2) DEFAULT 0,
  stock_quantity INTEGER DEFAULT 0,
  sku TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BANNERS TABLE
-- ============================================
CREATE TABLE banners (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  image_url TEXT NOT NULL,
  mobile_image_url TEXT,
  button_text TEXT,
  button_link TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CART ITEMS TABLE
-- ============================================
CREATE TABLE cart_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  variant_id UUID REFERENCES product_variants(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  customization JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id, variant_id)
);

-- ============================================
-- WISHLIST TABLE
-- ============================================
CREATE TABLE wishlist (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- ============================================
-- COUPONS TABLE
-- ============================================
CREATE TABLE coupons (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed')) NOT NULL,
  discount_value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount_amount DECIMAL(10,2),
  usage_limit INTEGER,
  usage_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ORDERS TABLE
-- ============================================
CREATE TABLE orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_number TEXT NOT NULL UNIQUE,
  user_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'crafting', 'quality_check', 'packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled', 'refunded')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded', 'cod')),
  payment_method TEXT CHECK (payment_method IN ('razorpay', 'upi', 'cod')),
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  
  -- Pricing
  subtotal DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  shipping_amount DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  
  -- Coupon
  coupon_id UUID REFERENCES coupons(id),
  coupon_code TEXT,
  
  -- Shipping address (snapshot)
  shipping_address JSONB NOT NULL,
  
  -- Tracking
  tracking_number TEXT,
  tracking_url TEXT,
  courier_name TEXT,
  estimated_delivery DATE,
  
  -- Notes
  customer_notes TEXT,
  admin_notes TEXT,
  
  -- Timestamps
  confirmed_at TIMESTAMPTZ,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ORDER ITEMS TABLE
-- ============================================
CREATE TABLE order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),
  product_name TEXT NOT NULL,
  product_image TEXT,
  variant_name TEXT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  customization JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ORDER STATUS HISTORY TABLE
-- ============================================
CREATE TABLE order_status_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL,
  note TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- REVIEWS TABLE
-- ============================================
CREATE TABLE reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  order_id UUID REFERENCES orders(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title TEXT,
  content TEXT,
  images TEXT[] DEFAULT '{}',
  is_verified BOOLEAN DEFAULT FALSE,
  is_approved BOOLEAN DEFAULT FALSE,
  admin_reply TEXT,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id, order_id)
);

-- ============================================
-- NEWSLETTER SUBSCRIBERS TABLE
-- ============================================
CREATE TABLE newsletter_subscribers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INSTAGRAM GALLERY TABLE
-- ============================================
CREATE TABLE instagram_gallery (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  image_url TEXT NOT NULL,
  caption TEXT,
  link TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- FAQS TABLE
-- ============================================
CREATE TABLE faqs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category TEXT DEFAULT 'general',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SETTINGS TABLE
-- ============================================
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update product rating on review change
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products SET
    rating = (SELECT AVG(rating) FROM reviews WHERE product_id = COALESCE(NEW.product_id, OLD.product_id) AND is_approved = TRUE),
    review_count = (SELECT COUNT(*) FROM reviews WHERE product_id = COALESCE(NEW.product_id, OLD.product_id) AND is_approved = TRUE)
  WHERE id = COALESCE(NEW.product_id, OLD.product_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_rating_on_review
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- Generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
  order_num TEXT;
BEGIN
  order_num := 'HB' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 9999 + 1)::TEXT, 4, '0');
  RETURN order_num;
END;
$$ LANGUAGE plpgsql;

-- Auto-set order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_order
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION set_order_number();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Addresses policies
CREATE POLICY "Users can manage own addresses" ON addresses FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all addresses" ON addresses FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Cart policies
CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (auth.uid() = user_id);

-- Wishlist policies
CREATE POLICY "Users can manage own wishlist" ON wishlist FOR ALL USING (auth.uid() = user_id);

-- Orders policies
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can manage all orders" ON orders FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Order items policies
CREATE POLICY "Users can view own order items" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE id = order_items.order_id AND user_id = auth.uid())
);
CREATE POLICY "Admins can manage order items" ON order_items FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Order history policies
CREATE POLICY "Users can view own order history" ON order_status_history FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE id = order_status_history.order_id AND user_id = auth.uid())
);
CREATE POLICY "Admins can manage order history" ON order_status_history FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Reviews policies
CREATE POLICY "Anyone can view approved reviews" ON reviews FOR SELECT USING (is_approved = TRUE);
CREATE POLICY "Users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage reviews" ON reviews FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Newsletter policies
CREATE POLICY "Anyone can subscribe" ON newsletter_subscribers FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "Admins can manage subscribers" ON newsletter_subscribers FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- Public read policies for catalog
CREATE POLICY "Anyone can view active categories" ON categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Anyone can view active products" ON products FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Anyone can view banners" ON banners FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Anyone can view gallery" ON instagram_gallery FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Anyone can view faqs" ON faqs FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Anyone can view settings" ON settings FOR SELECT USING (TRUE);

-- Admin write policies for catalog
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage products" ON products FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage banners" ON banners FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage gallery" ON instagram_gallery FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage faqs" ON faqs FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage settings" ON settings FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Admins can manage coupons" ON coupons FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
);
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT USING (is_active = TRUE);

-- ============================================
-- STORAGE BUCKETS (run via Supabase Dashboard)
-- ============================================
-- Create these buckets in Supabase Storage:
-- 1. 'products' - public bucket for product images
-- 2. 'banners' - public bucket for banner images  
-- 3. 'avatars' - public bucket for user avatars
-- 4. 'reviews' - public bucket for review images
-- 5. 'custom-orders' - private bucket for custom order uploads
-- 6. 'gallery' - public bucket for instagram gallery

-- ============================================
-- SEED DATA
-- ============================================

-- Insert default settings
INSERT INTO settings (key, value) VALUES
('store_info', '{"name": "Halo Buds", "tagline": "Fully Handmade & Customized", "email": "hello@halobuds.in", "phone": "+91 98765 43210", "address": "Chennai, Tamil Nadu, India", "currency": "INR", "currency_symbol": "₹"}'),
('shipping', '{"free_shipping_above": 999, "standard_shipping": 99, "express_shipping": 199, "cod_charge": 50, "cod_available": true}'),
('razorpay', '{"key_id": "YOUR_RAZORPAY_KEY_ID", "enabled": true}'),
('social', '{"instagram": "https://instagram.com/halobuds", "facebook": "https://facebook.com/halobuds", "pinterest": "https://pinterest.com/halobuds", "whatsapp": "+919876543210"}');

-- Insert categories
INSERT INTO categories (name, slug, description, icon, sort_order) VALUES
('Hair Accessories', 'hair-accessories', 'Handcrafted halos, headbands & clips', '🌸', 1),
('Floral Crowns', 'floral-crowns', 'Fresh & dried floral crowns for every occasion', '🌺', 2),
('Baby & Kids', 'baby-kids', 'Gentle, safe accessories for little ones', '🎀', 3),
('Bridal Collection', 'bridal-collection', 'Bespoke pieces for your special day', '💍', 4),
('Gift Sets', 'gift-sets', 'Curated sets perfect for gifting', '🎁', 5),
('Scrunchies', 'scrunchies', 'Handmade silk & satin scrunchies', '🎗️', 6),
('Custom Orders', 'custom-orders', 'Fully personalized creations just for you', '✨', 7);

-- Insert sample products
INSERT INTO products (name, slug, description, short_description, price, compare_price, category_id, images, tags, is_featured, is_bestseller, is_new_arrival, allow_customization, customization_options, stock_quantity, materials, processing_days, rating, review_count) VALUES
('Lavender Dream Halo', 'lavender-dream-halo', 'A breathtaking handcrafted halo adorned with dried lavender sprigs, baby''s breath, and delicate purple blooms. Each piece is uniquely made with love, making it perfect for bridal showers, photoshoots, or everyday elegance.', 'Dried lavender & baby''s breath halo crown', 1299, 1799, (SELECT id FROM categories WHERE slug='floral-crowns'), ARRAY['https://images.unsplash.com/photo-1519741497674-611481863552?w=800', 'https://images.unsplash.com/photo-1595411892234-3e6d9a80c0e9?w=800'], ARRAY['lavender', 'halo', 'bridal', 'dried flowers'], true, true, true, true, '{"allow_name": true, "allow_message": true, "allow_photo": false, "allow_instructions": true}', 25, 'Dried lavender, baby''s breath, wire base, floral tape', 3, 4.9, 127),

('Silk Bow Scrunchie Set', 'silk-bow-scrunchie-set', 'A luxurious set of 3 handmade silk scrunchies in coordinating lavender, blush pink, and ivory. Each features a handtied bow detail that adds an elegant touch to any hairstyle.', 'Set of 3 silk bow scrunchies', 699, 999, (SELECT id FROM categories WHERE slug='scrunchies'), ARRAY['https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=800'], ARRAY['scrunchie', 'silk', 'set', 'bow'], true, true, false, true, '{"allow_name": false, "allow_message": true, "allow_photo": false, "allow_instructions": true}', 50, 'Mulberry silk, satin ribbon', 2, 4.8, 89),

('Princess Baby Headband', 'princess-baby-headband', 'A soft, gentle headband perfect for your little princess. Made with hypoallergenic materials and adorned with handcrafted fabric flowers in the softest shades of lavender and pink.', 'Soft floral headband for babies', 499, 699, (SELECT id FROM categories WHERE slug='baby-kids'), ARRAY['https://images.unsplash.com/photo-1555252585-b0e7811eeeef?w=800'], ARRAY['baby', 'headband', 'princess', 'soft'], false, true, true, true, '{"allow_name": true, "allow_message": true, "allow_photo": false, "allow_instructions": true}', 30, 'Cotton, fabric flowers, elastic', 2, 4.9, 56),

('Bridal Bliss Crown', 'bridal-bliss-crown', 'Your dream bridal crown, handcrafted with the finest materials. Featuring cascading white roses, eucalyptus, and pearls, this halo transforms any bride into a goddess.', 'Luxury handcrafted bridal crown', 2499, 3499, (SELECT id FROM categories WHERE slug='bridal-collection'), ARRAY['https://images.unsplash.com/photo-1525088553748-01d6e210e00b?w=800'], ARRAY['bridal', 'crown', 'wedding', 'luxury'], true, false, true, true, '{"allow_name": true, "allow_message": true, "allow_photo": true, "allow_instructions": true}', 15, 'Silk flowers, pearls, wire, eucalyptus', 7, 5.0, 34),

('Mother-Daughter Gift Set', 'mother-daughter-gift-set', 'The perfect gift to celebrate the most beautiful bond. This curated set includes matching floral halos in two sizes — one for mama, one for her mini. Comes beautifully packaged in a gift box.', 'Matching mama & mini floral halo set', 1899, 2499, (SELECT id FROM categories WHERE slug='gift-sets'), ARRAY['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800'], ARRAY['gift', 'mother', 'daughter', 'matching', 'set'], true, true, false, true, '{"allow_name": true, "allow_message": true, "allow_photo": false, "allow_instructions": true}', 20, 'Dried flowers, fabric blooms, wire', 4, 4.9, 78),

('Wildflower Hair Clips Set', 'wildflower-hair-clips-set', 'A charming set of 4 handmade hair clips featuring miniature wildflowers. Each clip is individually crafted and perfect for everyday wear or special occasions.', 'Set of 4 handcrafted wildflower clips', 599, 849, (SELECT id FROM categories WHERE slug='hair-accessories'), ARRAY['https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=800'], ARRAY['clips', 'wildflower', 'set', 'everyday'], false, false, true, false, '{"allow_name": false, "allow_message": false, "allow_photo": false, "allow_instructions": true}', 40, 'Fabric flowers, metal clips, resin', 2, 4.7, 43);

-- Insert sample banners
INSERT INTO banners (title, subtitle, description, image_url, button_text, button_link, sort_order) VALUES
('Handcrafted with Love', 'Each piece tells a story', 'Discover our collection of bespoke floral accessories, made with heart and soul for every milestone moment.', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1600', 'Shop Collection', '/pages/shop.html', 1),
('Mother & Daughter Magic', 'Matching moments, forever treasured', 'Our new matching sets celebrate the most beautiful bond. Handcrafted in soft lavender and blush.', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=1600', 'Shop Sets', '/pages/shop.html?category=gift-sets', 2),
('Bridal Dreams', 'Your perfect crown awaits', 'Bespoke bridal accessories, handcrafted just for your special day. Every bride deserves to bloom.', 'https://images.unsplash.com/photo-1525088553748-01d6e210e00b?w=1600', 'Explore Bridal', '/pages/shop.html?category=bridal-collection', 3);

-- Insert FAQs
INSERT INTO faqs (question, answer, category, sort_order) VALUES
('How long does it take to make a custom order?', 'Custom orders typically take 3-7 business days depending on the complexity. Bridal pieces may take up to 10 days. We''ll confirm the timeline when you place your order.', 'orders', 1),
('Are the flowers real or artificial?', 'We use a mix of dried natural flowers and high-quality silk/fabric flowers depending on the piece. Product descriptions specify which type is used. All materials are carefully selected for longevity.', 'products', 2),
('Do you ship across India?', 'Yes! We ship pan-India via reliable courier partners. Free shipping on orders above ₹999. Delivery takes 3-5 business days after dispatch.', 'shipping', 3),
('Can I request a completely custom design?', 'Absolutely! We love creating one-of-a-kind pieces. Share your inspiration photos, color preferences, and occasion details during checkout. Our artisans will bring your vision to life.', 'custom', 4),
('What is your return policy?', 'Since all our pieces are handmade and many are customized, we generally don''t accept returns. However, if your item arrives damaged, we''ll replace or refund it within 48 hours of delivery. Please photograph any damage immediately.', 'returns', 5),
('Are your products safe for babies?', 'Our baby collection uses only hypoallergenic, non-toxic materials. However, all hair accessories should be used under adult supervision. Never leave accessories on an unsupervised infant.', 'safety', 6),
('Do you offer bulk orders for events?', 'Yes! We offer special pricing for wedding favors, baby shower gifts, and corporate gifting. Contact us at hello@halobuds.in for bulk order inquiries.', 'orders', 7),
('How should I care for my halo?', 'Store your halo flat in the gift box away from direct sunlight and moisture. Dried flower pieces are delicate — handle gently. A light spritz of hairspray can help preserve dried blooms.', 'care', 8);

-- Insert gallery items
INSERT INTO instagram_gallery (image_url, caption, link, sort_order) VALUES
('https://images.unsplash.com/photo-1519741497674-611481863552?w=600', 'Lavender dreams 💜', 'https://instagram.com/halobuds', 1),
('https://images.unsplash.com/photo-1595411892234-3e6d9a80c0e9?w=600', 'Every bride deserves to bloom 🌸', 'https://instagram.com/halobuds', 2),
('https://images.unsplash.com/photo-1555252585-b0e7811eeeef?w=600', 'Mini princess 👑', 'https://instagram.com/halobuds', 3),
('https://images.unsplash.com/photo-1525088553748-01d6e210e00b?w=600', 'Bridal magic ✨', 'https://instagram.com/halobuds', 4),
('https://images.unsplash.com/photo-1594736797933-d0501ba2fe65?w=600', 'Silk & softness 🎀', 'https://instagram.com/halobuds', 5),
('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600', 'Mother & daughter 💕', 'https://instagram.com/halobuds', 6),
('https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=600', 'Wildflower collection 🌼', 'https://instagram.com/halobuds', 7),
('https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600', 'Handcrafted with love 🤍', 'https://instagram.com/halobuds', 8);

-- Insert sample reviews (approved)
INSERT INTO reviews (product_id, user_id, rating, title, content, is_verified, is_approved) 
SELECT 
  p.id,
  (SELECT id FROM profiles LIMIT 1),
  5,
  'Absolutely gorgeous!',
  'I ordered the Lavender Dream Halo for my daughter''s birthday photoshoot and it was PERFECT. The quality is incredible and it arrived beautifully packaged. Will definitely order again!',
  true,
  true
FROM products p WHERE p.slug = 'lavender-dream-halo'
ON CONFLICT DO NOTHING;
