// Use DBML to define your database structure
// Docs: https://dbml.dbdiagram.io/docs

Table customers {
    customer_id varchar [primary key]
    customer_unique_id varchar
    customer_zip_code_prefix integer
    customer_city varchar
    customer_state varchar
}

Table locations {
    geolocation_zip_code_prefix integer [primary key]
    geolocation_lat integer
    geolocation_lng integer
    geolocation_city varchar
    geolocation_state varchar
}

Table orders {
    order_id varchar [primary key]
    customer_id varchar [primary key]
    order_status varchar
    order_purchase_timestamp timestamp
    order_approved_at timestamp
    order_delivered_carrier_date timestamp
    order_delivered_customer_date timestamp
    order_estimated_delivery_date timestamp
}

Table products {
    product_id varchar [primary key]
    product_category_name varchar
    product_name_lenght integer
    product_description_lenght integer
    product_photos_qty integer
    product_weight_g integer
    product_length_cm integer
    product_height_cm integer
    product_width_cm integer

}

Table sellers {
    seller_id varchar [primary key]
    seller_zip_code_prefix integer
    seller_city varchar
    seller_state varchar
}

Table order_item {
    order_id varchar [primary key, unique]
    order_item_id varchar [primary key, unique]
    product_id varchar [primary key, unique]
    seller_id varchar [primary key, unique]
    shipping_limit_date timestamp
    price float
    freight_value float
}

Table order_payment {
    order_id varchar [primary key]
    payment_sequential integer
    payment_type varchar
    payment_installments integer
    payment_value float
}

Table order_review {
    review_id varchar [primary key]
    order_id varchar
    review_score integer
    review_comment_title text
    review_comment_message text
    review_creation_date timestamp
    review_answer_timestamp timestamp
}

Table product_category_name_translation {
    product_category_name varchar [primary key]
    product_category_name_english varchar
}

ref: customers.customer_zip_code_prefix - locations.geolocation_zip_code_prefix
ref: orders.customer_id - customers.customer_id
ref: order_payment.order_id - orders.order_id
ref: order_item.order_id - orders.order_id
ref: order_item.product_id - products.product_id
ref: order_item.seller_id - sellers.seller_id
ref: products.product_category_name - product_category_name_translation.product_category_name
ref: order_review.order_id - orders.order_id
