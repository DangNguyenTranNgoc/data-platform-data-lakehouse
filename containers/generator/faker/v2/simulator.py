#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Generate oders. Due to lack of resouces, so that many field are choiced from 
the hard-code constanst

An order include:

- order_id
- order_status
- order_purchase_timestamp
- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date
- order_estimated_delivery_date
- customer_id

Items in a order:

- order_id
- order_item_id
- product_id
- seller_id
- shipping_limit_date
- price
- freight_value:
    Example:
    The order_id = 00143d0f86d6fbd9f9b38ab440ac16f5 has 3 items (same product).
    Each item has the freight calculated accordingly to its measures and weight.
    To get the total freight value for each order you just have to sum.

    The total order_item value is: 21.33 * 3 = 63.99

    The total freight value is: 15.10 * 3 = 45.30 => cost is 28.85 reals/kgs

    The total order value (product + freight) is: 45.30 + 63.99 = 109.29

    TO SIMPLE, PICK 28.85 PER KG FOR FREIGHT VALUE => (17 * 14 * 11) / 5000 * 28.85 = 15.10

Random a item in oder:
    - Get order_id from order
    - order_item_id init to 1, will be updated if we have more than one item in order
    - Random product_id:
        => Get height, width and length
    - Update freight_value
    - Get seller_id higher
    - Get shipping_limit_date from order_estimated_delivery_date
    - Get price from product

Generate order_items:
    - Random number of item
    - Random seller
    - Based on number of item, random item

If order_status == ["invoiced", "unavailable", "created"] then order_approved_at is null
All date, time are based on ORDER_DATE range

Case order_status:
    "delivered":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_delivered_carrier_date in range from order_approved_at
        upto 48Hrs (2 days)
        - Random order_delivered_customer_date in range from order_delivered_carrier_date
        upto 120Hrs (5 days)
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "shipped":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_delivered_carrier_date in range from order_approved_at
        upto 48Hrs (2 days)
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "approved":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "invoiced":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "unavailable":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "processing":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "canceled":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_approved_at in range from order_purchase_timestamp
        upto 4Hrs
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
    "created":
        - Random order_status in range ORDER_STATUS
        - Random order_purchase_timestamp in range from ORDER_DATE
        - Random order_estimated_delivery_date after oder_purchase_timestamp and
        range from 3 to 10 days (72Hrs to 240Hrs)
'''
import os
import json
import random
import datetime
import pandas as pd

USER_ID_RANGE = (1, 99441)
PRODUCT_RANGE = (1, 32951)
PRODUCT_PRICE = (0.85, 6735.0)
SELLER_ID_RANGE = (1, 3095)
DATE_FORMAT = r"%Y-%m-%d %H:%M:%S"

ORDER_STATUS = ["delivered", "shipped", "approved", "invoiced", "unavailable", "processing",
                "canceled", "created"]
ORDER_STATUS_W = [0.97, 0.012, 0.003, 0.003, 0.003, 0.003, 0.003, 0.003]
ORDER_DATE = ("2018-10-18 00:00:00", "2018-12-18 00:00:00")
ORDER_ITEMS_RANGE = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
ORDER_ITEMS_W = [0.99,
                 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001,
                 0.0002, 0.0002, 0.0002, 0.0002, 0.0002]

PAYMENT_TYPES = ['credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined']
PAYMENT_TYPES_W = [0.74, 0.19, 0.05, 0.015, 0.005]
PAYMENT_RANGE = [1, 2, 3, 4, 5]
PAYMENT_RANGE_W = [0.95, 0.03, 0.015, 0.004, 0.001]
PAYMENT_RATE = (1,
                (0.7, 0.3),
                (0.4, 0.3, 0.3),
                (0.2, 0.5, 0.2, 0.1),
                (0.2, 0.2, 0.3, 0.1, 0.2))
PAYMENT_INSTALL = [1, 2, 3, 4, 10, 5, 8, 6, 7, 9]
PAYMENT_INSTALL_W = [0.51, 0.12, 0.1, 0.07, 0.05, 0.05, 0.04, 0.04, 0.04, 0.02]

SHIPPING_COST = 28.85

PROJECT_DIR = os.path.dirname(os.path.dirname(__file__))
DATA_DIR = os.path.join(PROJECT_DIR, 'data')

PRODUCT_DF = pd.read_csv(os.path.join(DATA_DIR, 'olist_products_dataset.csv'))
ORDER_DF = pd.read_csv(os.path.join(DATA_DIR, 'olist_orders_dataset.csv'))


def get_product_from_id(product_id: int):
    ''' Query product with product id
    '''
    try:
        return PRODUCT_DF.iloc[product_id]
    except IndexError as error:
        print(f"[ERROR]: Invalid product id [{product_id}]")
        raise error


def gen_item(*, order_id: int,
             shipping_limit_date,
             order_item_id: int = 1) -> dict:
    ''' Gen a single item in order
    '''
    item = {
        "order_id": order_id,
        "order_item_id": order_item_id,
        "product_id": 0,
        "seller_id": 0,
        "shipping_limit_date": shipping_limit_date,
        "price": 0.0,
        "freight_value": 0.0
    }

    item["product_id"] = random.randint(*PRODUCT_RANGE)
    item["seller_id"] = random.randint(*SELLER_ID_RANGE)
    product = get_product_from_id(item["product_id"])
    item["price"] = round(random.uniform(*PRODUCT_PRICE), 2)
    item["freight_value"] = round(
    (
        (
            product['product_length_cm'] * \
              product['product_height_cm'] * \
                  product['product_width_cm']
        ) / 5000
    ) * SHIPPING_COST,
    2)

    return item


def gen_items(*, order_id: int, shipping_limit_date) -> list:
    ''' Gen a shopping cart with a (or multiple) product
    '''
    if isinstance(shipping_limit_date, datetime.datetime):
        shipping_limit_date = shipping_limit_date.strftime(DATE_FORMAT)
    num_of_product = random.choices(
                        ORDER_ITEMS_RANGE,
                        weights=ORDER_ITEMS_W, k=1
                    )[0]
    items = []
    for i in range(num_of_product):
        item = gen_item(order_id=order_id,
                        shipping_limit_date=shipping_limit_date,
                        order_item_id=i+1)
        if item:
            items.append(item)
    return items


def _random_date_between_2_date(
    start_date:str,
    end_date:str) -> datetime.datetime:
    ''' Return a random day between two date
    '''
    if isinstance(start_date, str) and isinstance(end_date, str):
        sdate = datetime.datetime.strptime(start_date, DATE_FORMAT)
        edate = datetime.datetime.strptime(end_date, DATE_FORMAT)
    elif isinstance(start_date, datetime.datetime):
        sdate = start_date
        edate = end_date
    else:
        return None
    
    return sdate + random.random() * (edate - sdate)


def _random_date_between_date_and_period(
        start_date, period:int)  -> datetime.datetime:
    if isinstance(start_date, str):
        sdate = datetime.datetime.strptime(start_date, DATE_FORMAT)
    elif isinstance(start_date, datetime.datetime):
        sdate = start_date
    else:
        return None
    sdate = datetime.datetime.strptime(start_date, DATE_FORMAT)
    edate = sdate + datetime.timedelta(days=period)
    return sdate + random.random() * (edate - sdate)


def _random_date_between_date_and_hours(
        start_date, period:int) -> datetime.datetime:
    if isinstance(start_date, str):
        sdate = datetime.datetime.strptime(start_date, DATE_FORMAT)
    elif isinstance(start_date, datetime.datetime):
        sdate = start_date
    else:
        return None
    edate = sdate + datetime.timedelta(hours=period)
    return sdate + random.random() * (edate - sdate)


def _random_date_between_period_hours(
        start_date:datetime.datetime,
        from_period:int,
        end_period:int
) -> datetime.datetime:
    sdate = start_date + datetime.timedelta(hours=from_period)
    return _random_date_between_date_and_hours(
        sdate, end_period)


def _get_latest_id_in_order_db() -> int:
    return ORDER_DF.index.max()


def _random_order() -> dict:
    ''' Random all data for an order
    '''
    order_id = _get_latest_id_in_order_db() + 1
    customer_id = random.randint(*USER_ID_RANGE)
    order_status = random.choices(
        ORDER_STATUS,
        weights=ORDER_STATUS_W,
        k=1
    )[0]
    order_purchase_timestamp = _random_date_between_2_date(*ORDER_DATE)
    # Approve date after purchase upto 4Hrs
    order_approved_at = _random_date_between_date_and_hours(
        order_purchase_timestamp, 4)
    # Delivery carrier date after approved 2 days (48 Hrs)
    order_delivered_carrier_date = _random_date_between_date_and_hours(
        order_approved_at, 48
    )
    # Actual order delivery date to the customer after 
    # order_delivered_carrier_date 5 days (120 Hrs)
    order_delivered_customer_date = _random_date_between_date_and_hours(
        order_delivered_carrier_date, 120
    )
    # Estimate date is delivery date that was informed to
    # customer at the purchase moment, after order_purchase_timestamp
    # from 5 to 10 days
    order_estimated_delivery_date = _random_date_between_period_hours(
        order_purchase_timestamp, 120, 240
    )
    return {
        "order_id": order_id,
        "customer_id": customer_id,
        "order_status": order_status,
        "order_purchase_timestamp": order_purchase_timestamp\
                                        .strftime(DATE_FORMAT),
        "order_approved_at": order_approved_at\
                                        .strftime(DATE_FORMAT),
        "order_delivered_carrier_date": order_delivered_carrier_date\
                                        .strftime(DATE_FORMAT),
        "order_delivered_customer_date": order_delivered_customer_date\
                                        .strftime(DATE_FORMAT),
        "order_estimated_delivery_date": order_estimated_delivery_date\
                                        .strftime(DATE_FORMAT),
    }


def _random_payment(order_id:int, seq:int, value:float):
    payment_type = random.choices(
        PAYMENT_TYPES,
        PAYMENT_TYPES_W,
        k=1
    )[0]
    payment_installments = random.choices(
        PAYMENT_INSTALL,
        PAYMENT_INSTALL_W,
        k=1
    )[0]
    return {
        "order_id": order_id,
        "payment_sequential": seq,
        "payment_type": payment_type,
        "payment_installments": payment_installments,
        "payment_value": value
    }


def gen_payment(order_id:int, total_value:float) -> dict:
    ''' Generate a payment(s) for an order
    '''
    num_pay = random.choices(PAYMENT_RANGE, weights=PAYMENT_RANGE_W, k=1)[0]
    if num_pay == 1:
        return _random_payment(order_id, 1, total_value)
    # When "customer" pay many times
    # First, calculate the value for each pay
    values = [round(rate*total_value, 2) for rate in PAYMENT_RATE[num_pay - 1]]
    # Then, correct the error numbers to the last
    values[-1] = round(total_value - sum(values[:-1]), 2)
    payments = []
    for i in range(num_pay):
        payments.append(_random_payment(order_id, i+1, values[i]))
    return payments


def cal_items_values(items: list) -> float:
    ''' Calculate the total values of items
    '''
    total_freights = sum([item["freight_value"] for item in items])
    total_values = sum([item["price"] for item in items])
    return total_values + total_freights


def _remove_fields_for_canceled_order(order: dict) -> dict:
    NUMBER_OF_NULL = [2, 3]
    NUMBER_OF_NULL_RATE = [0.8, 0.2]
    num_of_remove = random.choices(
        NUMBER_OF_NULL,
        weights=NUMBER_OF_NULL_RATE,
        k=1
    )[0]
    order["order_delivered_customer_date"] = ""
    if num_of_remove == 2:
        order["order_delivered_carrier_date"] = ""
    else:
        order["order_delivered_carrier_date"] = ""
        order["order_approved_at"] = ""


def gen_order() -> dict:
    ''' Generate an order
    At first, generate an order.
    Then, based on order's status, apply rules on it.
    After that, generate the item(s) of order and based on it, generate
    payment(s)
    '''
    order = _random_order()
    order["items"] = gen_items(
        order_id=order["order_id"],
        shipping_limit_date=order["order_estimated_delivery_date"])
    order["total_Values"] = cal_items_values(order["items"])
    order["payments"] = gen_payment(order_id=order["order_id"],
                               total_value=order["total_Values"])
    if order["order_status"] == "shipped":
        order["order_delivered_customer_date"] = ""
    elif order["order_status"] == "approved" \
        or order["order_status"] == "invoiced" \
        or order["order_status"] == "unavailable" \
        or order["order_status"] == "processing":
        order["order_delivered_customer_date"] = ""
        order["order_delivered_carrier_date"] = ""
    elif order["order_status"] == "canceled":
        order["order_delivered_customer_date"] = ""
    elif order["order_status"] == "created":
        _remove_fields_for_canceled_order(order)
    return order

# Test gen 1000 oders
# orders = []
# [orders.append(gen_order()) for i in range(1000)]
# df = pd.DataFrame(orders)
# df.to_csv(os.path.join(DATA_DIR, "test_gen_1k_oder.csv"), index=False)

