#!/usr/bin/env python
# -*- coding: utf-8 -*-
from typing import Optional

from faker.database import db
from faker.v2.models import Product, Customer, Geolocation, Seller

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
    ---
    '''
    product = Product.query.get(product_id)
    if not product:
        return None
    db.session.delete(product)
    db.session.commit()

    return product


def find_customer_by_id(customer_id) -> Customer | None:
    ''' Find customer by customer's id
    '''
    return Customer.query.get(customer_id)


def list_all_customers() -> list | None:
    ''' List all customer
    '''
    customers = Customer.query.all()
    return [customer.toDict() for customer in customers]


def add_new_customer(
        unique_id:str,
        zip_code_prefix:Optional[str]=None,
        city:Optional[str]=None,
        state:Optional[str]=None
) -> Customer | None:
    ''' Add a new customer into DB
    '''
    # If we only have zip code prefix, get city and state from location
    if not city and not state and zip_code_prefix:
        location = Geolocation.query.get(zip_code_prefix)
        city = location.geolocation_city
        state = location.geolocation_state
    # Create new customer
    new_customer = Customer(
        customer_unique_id=unique_id,
        customer_zip_code_prefix=zip_code_prefix,
        customer_city=city,
        customer_state=state
    )
    db.session.add(new_customer)
    db.session.commit()

    return Customer.query.get(new_customer.customer_id)


def update_customer(
        customer_id:int,
        unique_id:Optional[str]=None,
        zip_code_prefix:Optional[str]=None,
        city:Optional[str]=None,
        state:Optional[str]=None
) -> Customer | None:
    ''' Update customer data
    customer_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    customer_unique_id: Mapped[str] = mapped_column(String, nullable=True)
    customer_zip_code_prefix = mapped_column(String, nullable=True)
    customer_city: Mapped[str] = mapped_column(String, nullable=True)
    customer_state: Mapped[str] = mapped_column(String, nullable=True)
    '''
    customer = Customer.query.get(customer_id)
    if not customer:
        return None
    if unique_id:
        customer.customer_unique_id = unique_id
    if zip_code_prefix:
        customer.customer_zip_code_prefix = zip_code_prefix
    if (zip_code_prefix and not city) or \
        (zip_code_prefix and not state):
        location = Geolocation.query \
            .filter(Geolocation.geolocation_zip_code_prefix == zip_code_prefix) \
            .first()
        if location:
            city = location.geolocation_city
            state = location.geolocation_state
    if city:
        customer.customer_city = city
    if state:
        customer.customer_state = state
    db.session.commit()

    return Customer.query.get(customer.customer_id)


def delete_customer(customer_id) -> Customer | None:
    ''' Delete a customer with id
    '''
    customer = Customer.query.get(customer_id)
    if not customer:
        return None
    db.session.delete(customer)
    db.session.commit()

    return customer


def find_seller_by_id(seller_id) -> Seller | None:
    ''' Find seller by seller's id
    '''
    return Seller.query.get(seller_id)


def list_all_sellers() -> list | None:
    ''' List all seller
    '''
    sellers = Seller.query.all()
    return [seller.toDict() for seller in sellers]


def add_new_seller(
        zip_code_prefix:Optional[str]=None,
        city:Optional[str]=None,
        state:Optional[str]=None
) -> Seller | None:
    ''' Add a new seller into DB
    '''
    # If we only have zip code prefix, get city and state from location
    if not city and not state and zip_code_prefix:
        location = Geolocation.query.get(zip_code_prefix)
        city = location.geolocation_city
        state = location.geolocation_state
    # Create new seller
    new_seller = Seller(
        seller_zip_code_prefix=zip_code_prefix,
        seller_city=city,
        seller_state=state
    )
    db.session.add(new_seller)
    db.session.commit()

    return Seller.query.get(new_seller.seller_id)


def update_seller(
        seller_id:int,
        zip_code_prefix:Optional[str]=None,
        city:Optional[str]=None,
        state:Optional[str]=None
) -> Seller | None:
    ''' Update seller data
    '''
    seller = Seller.query.get(seller_id)
    if not seller:
        return None
    if zip_code_prefix:
        seller.seller_zip_code_prefix = zip_code_prefix
    if (zip_code_prefix and not city) or \
        (zip_code_prefix and not state):
        seller.seller_zip_code_prefix = zip_code_prefix
        location = Geolocation.query \
            .filter(Geolocation.geolocation_zip_code_prefix == zip_code_prefix) \
            .first()
        if location:
            city = location.geolocation_city
            state = location.geolocation_state
    if city:
        seller.seller_city = city
    if state:
        seller.seller_state = state
    db.session.commit()

    return Seller.query.get(seller.seller_id)


def delete_seller(seller_id) -> Seller | None:
    ''' Delete a Seller with id
    '''
    seller = Seller.query.get(seller_id)
    if not seller:
        return None
    db.session.delete(seller)
    db.session.commit()

    return seller

