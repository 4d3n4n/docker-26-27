ALTER TABLE products ADD COLUMN IF NOT EXISTS sku text;

UPDATE products SET sku = 'SKU-' || id WHERE sku IS NULL;

ALTER TABLE products ALTER COLUMN sku SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS products_sku_unique ON products (sku);
