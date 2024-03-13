#!/usr/bin/env python
# -*- coding: utf-8 -*-
from datetime import datetime
# Temporary not used
# from flask_validator import ValidateEmail, ValidateString, ValidateCountry
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer, Float, String, DateTime

from faker.database import db


class Customer(db.Model):
    ''' Customer model
    ---
    '''
    __tablename__ = "customers"
    customer_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    customer_unique_id: Mapped[str] = mapped_column(String, nullable=False)
    customer_zip_code_prefix: Mapped[str] = mapped_column(String, nullable=True)
    customer_city: Mapped[str] = mapped_column(String, nullable=True)
    customer_state: Mapped[str] = mapped_column(String, nullable=True)


class Geolocation(db.Model):
    ''' Geolocation model
    ---
    '''
    __tablename__ = "geolocation"
    geolocation_zip_code_prefix = mapped_column(Integer, primary_key=True)
    geolocation_lat: Mapped[float] = mapped_column(Float, nullable=False)
    geolocation_lng: Mapped[float] = mapped_column(Float, nullable=False)
    geolocation_city: Mapped[str] = mapped_column(String, nullable=False)
    geolocation_state: Mapped[str] = mapped_column(String, nullable=False)


class Payment(db.Model):
    ''' Payments model
    ---
    '''
    __tablename__ = "payments"
    order_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    payment_sequential: Mapped[int] = mapped_column(Integer, primary_key=True)
    payment_type: Mapped[str] = mapped_column(String, nullable=False)
    payment_installments: Mapped[int] = mapped_column(Integer, nullable=False)
    payment_value: Mapped[float] = mapped_column(Float, nullable=False)


class Review(db.Model):
    '''Reviews model
    ---
    '''
    __tablename__ = "reviews"
    review_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(Integer, nullable=True)
    review_score = mapped_column(Integer, default=5)
    review_comment_title = mapped_column(String, nullable=True)
    review_comment_message = mapped_column(String, nullable=True)
    review_creation_date = mapped_column(DateTime, default=datetime.now())
    review_answer_timestamp = mapped_column(DateTime, default=datetime.now())


class Seller(db.Model):
    ''' Seller model
    ---
    '''
    __tablename__ = "sellers"
    seller_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    seller_zip_code_prefix: Mapped[int] = mapped_column(Integer, nullable=False)
    seller_city: Mapped[str] = mapped_column(String, nullable=False)
    seller_state: Mapped[str] = mapped_column(String, nullable=False)


class Category(db.Model):
    ''' Category model
    ---
    '''
    __tablename__ = "category"
    product_category_name: Mapped[str] = mapped_column(String, primary_key=True)
    product_category_name_english: Mapped[str] = mapped_column(String, nullable=False)


class Product(db.Model):
    ''' Product model
    ---
    '''
    __tablename__ = "products"
    product_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    product_category_name: Mapped[str] = mapped_column(String, nullable=False)
    product_name_lenght: Mapped[float] = mapped_column(Float, nullable=False)
    product_description_lenght: Mapped[float] = mapped_column(Float, nullable=True)
    product_photos_qty: Mapped[float] = mapped_column(Float, nullable=True)
    product_weight_g: Mapped[float] = mapped_column(Float, nullable=True)
    product_length_cm: Mapped[float] = mapped_column(Float, nullable=True)
    product_height_cm:Mapped[float] = mapped_column(Float, nullable=True)
    product_width_cm: Mapped[float] = mapped_column(Float, nullable=True)


class Order(db.Model):
    ''' Oder model
    ---
    '''
    __tablename__ = "orders"
    order_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    customer_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_status: Mapped[str] = mapped_column(String, nullable=False)
    order_purchase_timestamp: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    order_approved_at: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_delivered_carrier_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_delivered_customer_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_estimated_delivery_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)


class Item(db.Model):
    ''' Item in an order
    ---
    '''
    __tablename__ = "items"
    order_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_item_id: Mapped[int] = mapped_column(Integer, nullable=False)
    product_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    seller_id: Mapped[int] = mapped_column(Integer, nullable=False)
    shipping_limit_date: Mapped[int] = mapped_column(Integer, nullable=False)
    price: Mapped[int] = mapped_column(Integer, nullable=False)
    freight_value: Mapped[int] = mapped_column(Integer, nullable=False)
