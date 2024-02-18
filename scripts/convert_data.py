#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Convert Olist E-Commerce data into easier format to process
Tables:
- customers: data/olist_customers_dataset.csv 
- geolocation: data/olist_geolocation_dataset.csv
- order items: data/olist_order_items_dataset.csv
- order payments: data/olist_order_payments_dataset.csv
- order reviews: data/olist_order_reviews_dataset.csv
- orders: data/olist_orders_dataset.csv
- products: data/olist_products_dataset.csv
- sellers: data/olist_sellers_dataset.csv
- category: data/product_category_name_translation.csv
'''
import os
import pandas as pd

PROJECT_DIR = os.path.dirname(os.path.dirname(__file__))
DATA_DIR = os.path.join(PROJECT_DIR, 'data')

print(PROJECT_DIR)
print(DATA_DIR)
