#!/usr/bin/env python
# -*- coding: utf-8 -*-
from typing import Optional

from faker.database import db
from faker.v2.models import Product

def get_product_by_id(product_id) -> Product | None:
    ''' Find a product with product_id
    '''
    product = Product.query.get(product_id)
    return product


def list_all_product() -> list | None:
    ''' List all product in DB
    '''
    products = Product.query.all()
    return [product.toDict() for product in products]


def create_product(
        category_name:str, name_lenght:int,
        description_lenght:int, photos_qty:int,
        weight_g:float, length_cm:float,
        height_cm:float, width_cm:float
) -> Product | None:
    ''' Create a product
    '''
    new_product = Product(
        product_category_name=category_name,
        product_name_lenght=name_lenght,
        product_description_lenght=description_lenght,
        product_photos_qty=photos_qty,
        product_weight_g=weight_g,
        product_length_cm=length_cm,
        product_height_cm=height_cm,
        product_width_cm=width_cm
    )
    db.session.add(new_product)
    db.session.commit()

    return Product.query.get(new_product.product_id)


def update_product(
        product_id:int,
        category_name:Optional[str]=None, name_lenght:Optional[int]=None,
        description_lenght:Optional[int]=None, photos_qty:Optional[int]=None,
        weight_g:Optional[float]=None, length_cm:Optional[float]=None,
        height_cm:Optional[float]=None, width_cm:Optional[float]=None
) -> Product | None:
    ''' Update a product
    '''
    product = Product.query.get(product_id)
    if not product:
        return None
    if category_name:
        product.product_category_name = category_name
    if name_lenght:
        product.product_name_lenght = name_lenght
    if description_lenght:
        product.product_description_lenght = description_lenght
    if photos_qty:
        product.product_photos_qty = photos_qty
    if weight_g:
        product.product_weight_g = weight_g
    if length_cm:
        product.product_length_cm = length_cm
    if height_cm:
        product.product_height_cm = height_cm
    if width_cm:
        product.product_width_cm = width_cm
    db.session.commit()

    return Product.query.get(product_id)


def delete_product(product_id:int) -> Product | None:
    ''' Delete a product with id
    '''
    product = Product.query.get(product_id)
    if not product:
        return None
    db.session.delete(product)
    db.session.commit()

    return product
