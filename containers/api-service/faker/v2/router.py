#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Blueprint, jsonify, make_response

from faker.v1.simulator import gen_order

v2_blueprint = Blueprint(name='v2', import_name='v2')

@v2_blueprint.route("/healthcheck", methods=["GET"])
def healthcheck():
    ''' Just an health check function
    '''
    return jsonify({"message": "I'm healthy"})

# TODO: Will add a streamming here

