#!/usr/bin/env python
# -*- coding: utf-8 -*-
from datetime import datetime
# Temporary not used
# from flask_validator import ValidateEmail, ValidateString, ValidateCountry
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, Float, String, DateTime, ForeignKey

from faker.database import db


class Customer(db.Model):
    ''' Customer model
    ---
    '''
    __tablename__ = "customers"
    customer_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    customer_unique_id: Mapped[str] = mapped_column(String, nullable=True)
    customer_zip_code_prefix = mapped_column(String, nullable=True)
    customer_city: Mapped[str] = mapped_column(String, nullable=True)
    customer_state: Mapped[str] = mapped_column(String, nullable=True)
    customer_order = relationship("Order", back_populates="order_customer")


class Geolocation(db.Model):
    ''' Geolocation model
    ---
    '''
    __tablename__ = "geolocation"
    geolocation_zip_code_prefix: Mapped[str] = mapped_column(String, nullable=False)
    geolocation_lat: Mapped[float] = mapped_column(Float, nullable=True)
    geolocation_lng: Mapped[float] = mapped_column(Float, nullable=True)
    geolocation_city: Mapped[str] = mapped_column(String, nullable=True)
    geolocation_state: Mapped[str] = mapped_column(String, nullable=True)


class Payment(db.Model):
    ''' Payments model
    ---
    '''
    __tablename__ = "payments"
    order_id = mapped_column(ForeignKey("orders.order_id"), primary_key=True)
    payment_sequential: Mapped[int] = mapped_column(Integer, primary_key=True)
    payment_type: Mapped[str] = mapped_column(String, nullable=True)
    payment_installments: Mapped[int] = mapped_column(Integer, nullable=True)
    payment_value: Mapped[float] = mapped_column(Float, nullable=True)
    payment_order = relationship("Order", back_populates="order_payment")


class Review(db.Model):
    '''Reviews model
    ---
    '''
    __tablename__ = "reviews"
    review_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id = mapped_column(ForeignKey("orders.order_id"))
    review_score = mapped_column(Integer, default=5)
    review_comment_title = mapped_column(String, nullable=True)
    review_comment_message = mapped_column(String, nullable=True)
    review_creation_date = mapped_column(DateTime, default=datetime.now())
    review_answer_timestamp = mapped_column(DateTime, default=datetime.now())
    review_order = relationship("Order", back_populates="order_review")


class Seller(db.Model):
    ''' Seller model
    ---
    '''
    __tablename__ = "sellers"
    seller_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    seller_zip_code_prefix = mapped_column(String, nullable=True)
    seller_city: Mapped[str] = mapped_column(String, nullable=True)
    seller_state: Mapped[str] = mapped_column(String, nullable=True)
    seller_item = relationship("Item", back_populates="item_seller")


class Category(db.Model):
    ''' Category model
    ---
    '''
    __tablename__ = "category"
    product_category_name: Mapped[str] = mapped_column(String, primary_key=True)
    product_category_name_english: Mapped[str] = mapped_column(String, nullable=True)


class Product(db.Model):
    ''' Product model
    ---
    '''
    __tablename__ = "products"
    product_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    product_category_name: Mapped[str] = mapped_column(String, nullable=True)
    product_name_lenght: Mapped[float] = mapped_column(Float, nullable=True)
    product_description_lenght: Mapped[float] = mapped_column(Float, nullable=True)
    product_photos_qty: Mapped[float] = mapped_column(Float, nullable=True)
    product_weight_g: Mapped[float] = mapped_column(Float, nullable=True)
    product_length_cm: Mapped[float] = mapped_column(Float, nullable=True)
    product_height_cm:Mapped[float] = mapped_column(Float, nullable=True)
    product_width_cm: Mapped[float] = mapped_column(Float, nullable=True)
    product_item = relationship("Item", back_populates="item_product")


class Order(db.Model):
    ''' Oder model
    ---
    '''
    __tablename__ = "orders"
    order_id = mapped_column(Integer, primary_key=True, autoincrement=True)
    customer_id = mapped_column(ForeignKey("customers.customer_id"))
    order_status: Mapped[str] = mapped_column(String, nullable=True)
    order_purchase_timestamp: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_approved_at: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_delivered_carrier_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_delivered_customer_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_estimated_delivery_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    order_customer = relationship("Customer", back_populates="customer_order")
    order_payment = relationship("Payment", back_populates="payment_order")
    order_item = relationship("Item", back_populates="item_order")
    order_review = relationship("Review", back_populates="review_order")


class Item(db.Model):
    ''' Item in an order
    ---
    '''
    __tablename__ = "items"
    order_id = mapped_column(ForeignKey("orders.order_id"), primary_key=True)
    product_id = mapped_column(ForeignKey("products.product_id"), primary_key=True)
    seller_id = mapped_column(ForeignKey("sellers.seller_id"), primary_key=True)
    order_item_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    shipping_limit_date: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    price: Mapped[int] = mapped_column(Integer, nullable=True)
    freight_value: Mapped[int] = mapped_column(Integer, nullable=True)
    item_order = relationship("Order", back_populates="order_item")
    item_product = relationship("Product", back_populates="product_item")
    item_seller = relationship("Seller", back_populates="seller_item")
