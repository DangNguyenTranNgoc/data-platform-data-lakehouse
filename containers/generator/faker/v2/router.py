#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import math
import json
import time
import random
from concurrent.futures import ThreadPoolExecutor
from kafka import KafkaProducer
from flask import Blueprint, request, jsonify
from flask import make_response, stream_with_context
from flasgger import swag_from

from faker.database import init_database
from faker.v1.simulator import gen_order
from faker.v2.controller import get_product_by_id, list_all_product
from faker.v2.controller import create_product, update_product, delete_product

KAFKA_BOOTSTRAP_SERVER = "localhost:29092"
PROJECT_DIR = os.path.dirname(os.path.dirname(__file__))

v2_blueprint = Blueprint(name='v2', import_name='v2')

@v2_blueprint.route("/healthcheck", methods=["GET"])
def healthcheck():
    ''' Just an health check function
    '''
    return jsonify({"message": "I'm healthy"})


@v2_blueprint.route("/initdb")
def database():
    ''' Init database
    '''
    init_database()
    return make_response(
        jsonify({"message": "Successfully"}),
        200
    )


@swag_from(str(os.path.join(PROJECT_DIR, "docs/product_list_v2.yml")))
@v2_blueprint.route("/products", methods=["GET"])
def list_products_api():
    ''' List all product or create new product
    '''
    products = list_all_product()
    if products:
        return make_response(
            jsonify(products),
            200
        )
    return make_response(
        jsonify({"message": "We don't have any product"}),
        404
    )


@swag_from(str(os.path.join(PROJECT_DIR, "docs/product_create_v2.yml")))
@v2_blueprint.route("/products", methods=["POST"])
def add_product_api():
    ''' Create a product or create new product
    '''
    request_form = request.get_json()
    product = create_product(
        request_form["category_name"],
        request_form["name_lenght"],
        request_form["description_lenght"],
        request_form["photos_qty"],
        request_form["weight_g"],
        request_form["length_cm"],
        request_form["height_cm"],
        request_form["width_cm"]
    )
    if product:
        return make_response(
            jsonify(product),
            200
        )
    return make_response(
        jsonify({"message": "Invalid request"}),
        400
    )


@swag_from(str(os.path.join(PROJECT_DIR, "docs/product_retrieve_v2.yml")))
@v2_blueprint.route("/products/<int:product_id>", methods=["GET"])
def retrieve_product_api(product_id):
    ''' Get a product
    '''
    # First, check if product with id is exested
    product = get_product_by_id(product_id)
    if not product:
        return make_response(
            jsonify({"message": "Product is not exist"}),
            404
        )
    # Retrive a product
    return make_response(
        jsonify(product.toDict()),
        200
    )


@swag_from(str(os.path.join(PROJECT_DIR, "docs/product_update_v2.yml")))
@v2_blueprint.route("/products/<int:product_id>", methods=["PUT"])
def update_product_api(product_id):
    ''' Update a product
    '''
    # First, check if product with id is exested
    product = get_product_by_id(product_id)
    if not product:
        return make_response(
            jsonify({"message": "Product is not exist"}),
            404
        )
    # Update a product
    request_form = request.get_json()
    
    product = update_product(
        product.product_id,
        request_form["category_name"],
        request_form["name_lenght"],
        request_form["description_lenght"],
        request_form["photos_qty"],
        request_form["weight_g"],
        request_form["length_cm"],
        request_form["height_cm"],
        request_form["width_cm"]
    )
    if product:
        return make_response(
            jsonify(product),
            200
        )
    return make_response(
        jsonify({"message": "Invalid request"}),
        400
    )


@swag_from(str(os.path.join(PROJECT_DIR, "docs/product_delete_v2.yml")))
@v2_blueprint.route("/products/<int:product_id>", methods=["DELETE"])
def delete_product_api(product_id):
    ''' Delete a product
    '''
    # Delete a product
    product = delete_product(product_id)
    if product:
        return make_response(
            jsonify(product),
            200
        )
    return make_response(
        jsonify({"message": "Product is not existed"}),
        404
    )


@v2_blueprint.route("/orders-stream/")
@v2_blueprint.route("/orders-stream/<int:minimum>/<int:maximum>")
@v2_blueprint.route("/orders-stream/<int:minimum>/<int:maximum>/<int:batch>")
def order_stream(minimum:int = 100, maximum:int = 500, batch:int = 10):
    ''' Stream order
    First, decide how many orders will be created
    Then, generate them by batch and throw it to the client
    '''
    num_orders = random.randint(minimum, maximum)
    num_batchs = math.ceil(num_orders / batch)
    last_batch = num_orders % batch
    time_sleep = random.uniform(0.1, 1.0)

    if minimum > maximum:
        return make_response(
            jsonify({"message": "[minimum] must larger than maximum"}),
            400
        )

    if (minimum / batch) < 1:
        return make_response(
            jsonify(
                {"message": "Invalid [batch] number, [minimun] divide [batch] \
                 must be greater than 1"}),
            400
        )

    def _stream():
        for _ in range(num_batchs):
            for _ in range(batch):
                yield json.dumps(gen_order())
            time.sleep(time_sleep)
        # Last batch
        for _ in range(last_batch):
            yield json.dumps(gen_order())

    response = make_response(
        stream_with_context(_stream())
    )
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Content-Type"] = "text/event-stream"
    return response


def serializer(message):
    ''' Set up Kafka producer
    '''
    return json.dumps(message).encode('utf-8')


@v2_blueprint.route("/orders-kafka-stream/")
@v2_blueprint.route("/orders-kafka-stream/<int:minimum>/<int:maximum>")
@v2_blueprint.route("/orders-kafka-stream/<int:minimum>/<int:maximum>/<int:batch>")
def order_kafka_stream(minimum:int = 100, maximum:int = 500, batch:int = 10):
    ''' Stream order
    First, decide how many orders will be created
    Then, generate them by batch and throw it to the client
    '''
    num_orders = random.randint(minimum, maximum)
    num_batchs = math.ceil(num_orders / batch)
    last_batch = num_orders % batch

    # Kafka Producer
    producer = KafkaProducer(
        bootstrap_servers=[KAFKA_BOOTSTRAP_SERVER],
        value_serializer=serializer
    )

    # Output flattened JSON record for each client record using threads
    with ThreadPoolExecutor(max_workers=16) as executor:
        for _ in range(num_batchs):
            time_sleep = random.uniform(0.1, 1.0)
            for _ in range(batch):
                producer.send('oders', json.dumps(gen_order()))
                producer.flush()
            time.sleep(time_sleep)
        # Last batch
        for _ in range(last_batch):
            time_sleep = random.uniform(0.1, 1.0)
            producer.send('oders', json.dumps(gen_order()))
            producer.flush()
            time.sleep(time_sleep)

    return make_response(
        jsonify({"message": "Successfully",
                 "total_orders": num_orders,
                 "total_batches": num_batchs}),
        200
    )
