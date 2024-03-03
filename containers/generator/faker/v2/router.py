#!/usr/bin/env python
# -*- coding: utf-8 -*-
import math
import json
import time
import random
from flask import Blueprint, jsonify, make_response, Response, stream_with_context

from faker.v1.simulator import gen_order

v2_blueprint = Blueprint(name='v2', import_name='v2')

@v2_blueprint.route("/healthcheck", methods=["GET"])
def healthcheck():
    ''' Just an health check function
    '''
    return jsonify({"message": "I'm healthy"})


@v2_blueprint.route("/orders-stream/<int:minimum>/<int:maximum>/<int:batch>",
                    methods=["GET"],
                    defaults={"minimum": 100, "maximum": 500, "batch": 10})
def orders_stream(minimum:int, maximum:int, batch:int):
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
