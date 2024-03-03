#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Blueprint, jsonify, make_response

from faker.v1.simulator import gen_order

v1_blueprint = Blueprint(name='v1', import_name='v1')

@v1_blueprint.route("/healthcheck", methods=["GET"])
def healthcheck():
    ''' Just an health check function
    '''
    return jsonify({"message": "I'm healthy"})


@v1_blueprint.route("/orders", methods=["GET"])
def orders():
    ''' Generate an order
    '''
    response = make_response(
        jsonify(gen_order()),
        200
    )
    return response

