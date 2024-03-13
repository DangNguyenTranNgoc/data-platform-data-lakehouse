DROP TABLE IF EXISTS "customer";
CREATE TABLE "customers" (
  "customer_id" varchar PRIMARY KEY,
  "customer_unique_id" varchar,
  "customer_zip_code_prefix" integer,
  "customer_city" varchar,
  "customer_state" varchar
);

DROP TABLE IF EXISTS "locations";
CREATE TABLE "locations" (
  "geolocation_zip_code_prefix" integer PRIMARY KEY,
  "geolocation_lat" integer,
  "geolocation_lng" integer,
  "geolocation_city" varchar,
  "geolocation_state" varchar
);

DROP TABLE IF EXISTS "orders";
CREATE TABLE "orders" (
  "order_id" varchar UNIQUE,
  "customer_id" varchar UNIQUE,
  "order_status" varchar,
  "order_purchase_timestamp" timestamp,
  "order_approved_at" timestamp,
  "order_delivered_carrier_date" timestamp,
  "order_delivered_customer_date" timestamp,
  "order_estimated_delivery_date" timestamp,
  PRIMARY KEY ("order_id", "customer_id")
);

DROP TABLE IF EXISTS "products";
CREATE TABLE "products" (
  "product_id" varchar PRIMARY KEY,
  "product_category_name" varchar,
  "product_name_lenght" integer,
  "product_description_lenght" integer,
  "product_photos_qty" integer,
  "product_weight_g" integer,
  "product_length_cm" integer,
  "product_height_cm" integer,
  "product_width_cm" integer
);

DROP TABLE IF EXISTS "sellers";
CREATE TABLE "sellers" (
  "seller_id" varchar PRIMARY KEY,
  "seller_zip_code_prefix" integer,
  "seller_city" varchar,
  "seller_state" varchar
);

DROP TABLE IF EXISTS "order_item";
CREATE TABLE "order_item" (
  "order_id" varchar UNIQUE,
  "order_item_id" varchar UNIQUE,
  "product_id" varchar UNIQUE,
  "seller_id" varchar UNIQUE,
  "shipping_limit_date" timestamp,
  "price" float,
  "freight_value" float,
  PRIMARY KEY ("order_id", "order_item_id", "product_id", "seller_id")
);

DROP TABLE IF EXISTS "order_payment";
CREATE TABLE "order_payment" (
  "order_id" varchar PRIMARY KEY,
  "payment_sequential" integer,
  "payment_type" varchar,
  "payment_installments" integer,
  "payment_value" float
);

DROP TABLE IF EXISTS "order_review";
CREATE TABLE "order_review" (
  "review_id" varchar PRIMARY KEY,
  "order_id" varchar,
  "review_score" integer,
  "review_comment_title" text,
  "review_comment_message" text,
  "review_creation_date" timestamp,
  "review_answer_timestamp" timestamp
);

DROP TABLE IF EXISTS "product_category_name_translation";
CREATE TABLE "product_category_name_translation" (
  "product_category_name" varchar PRIMARY KEY,
  "product_category_name_english" varchar
);

ALTER TABLE "customers" ADD FOREIGN KEY ("customer_zip_code_prefix") REFERENCES "locations" ("geolocation_zip_code_prefix");

ALTER TABLE "orders" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id");

ALTER TABLE "order_item" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id");

ALTER TABLE "order_item" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id");

ALTER TABLE "order_item" ADD FOREIGN KEY ("seller_id") REFERENCES "sellers" ("seller_id");

ALTER TABLE "order_payment" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id");

ALTER TABLE "products" ADD FOREIGN KEY ("product_category_name") REFERENCES "product_category_name_translation" ("product_category_name");

ALTER TABLE "order_review" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id");
