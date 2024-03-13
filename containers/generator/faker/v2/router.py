#!/usr/bin/env python
# -*- coding: utf-8 -*-
import math
import json
import time
import random
from concurrent.futures import ThreadPoolExecutor

from kafka import KafkaProducer
from flask import Blueprint, jsonify, make_response, stream_with_context

from faker.database import init_database
from faker.v2.controller import find_product_by_id
from faker.v2.simulator import gen_order

KAFKA_BOOTSTRAP_SERVER = "localhost:29092"

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
    is_table_created = False
    is_data_imported = False
    init_database()
    return make_response(
        jsonify({"message": "Successfully"}),
        200
    )


@v2_blueprint.route("/product/<int:product_id>")
def get_product(product_id:int):
    ''' Product api
    '''
    product = find_product_by_id(product_id)
    if product:
        return jsonify(product.toDict())
    return jsonify({"message": "Product id is not existed"}, 404)


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
        for b in range(num_batchs):
            for i in range(batch):
                yield json.dumps(gen_order())
            time.sleep(time_sleep)
        # Last batch
        for i in range(last_batch):
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

    # Kafka Producer
    producer = KafkaProducer(
        bootstrap_servers=[KAFKA_BOOTSTRAP_SERVER],
        value_serializer=serializer
    )

    # Output flattened JSON record for each client record using threads
    with ThreadPoolExecutor(max_workers=16) as executor:
        for b in range(num_batchs):
            time_sleep = random.uniform(0.1, 1.0)
            for i in range(batch):
                producer.send('oders', json.dumps(gen_order()))
                producer.flush()
            time.sleep(time_sleep)
        # Last batch
        for i in range(last_batch):
            time_sleep = random.uniform(0.1, 1.0)
            producer.send('oders', json.dumps(gen_order()))
            producer.flush()
            time.sleep(time_sleep)

    return make_response(
        jsonify({"message": "Successfully",
                 "total_orders": num_orders),
        200
    )
