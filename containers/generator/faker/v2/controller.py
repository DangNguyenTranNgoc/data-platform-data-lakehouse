#!/usr/bin/env python
# -*- coding: utf-8 -*-
from faker.database import db
from faker.v2.models import Product

def find_product_by_id(product_id):
    ''' Find a product with product_id
    '''
    product = Product.query.get(product_id)
    return product


def create_product():
    ''' Create a product
    ---
    product_id
    product_category_name
    product_name_lenght
    product_description_lenght
    product_photos_qty
    product_weight_g
    product_length_cm
    product_height_cm
    product_width_cm
    ---
    Ex: 1,perfumaria,40.0,287.0,1.0,225.0,16.0,10.0,14.0
    '''
    new_product = Product(
        product_category_name="abc",
        product_name_lenght=24,
        product_description_lenght=95,
        product_photos_qty=3,
        product_weight_g=185.4,
        product_length_cm=11,
        product_height_cm=12,
        product_width_cm=13
    )
    db.session.add(new_product)
    db.session.commit()
