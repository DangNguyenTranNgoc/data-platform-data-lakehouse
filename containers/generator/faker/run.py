#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Flask
from werkzeug.serving import WSGIRequestHandler

from faker.v1.router import v1_blueprint
from faker.v2.router import v2_blueprint

app = Flask(__name__, instance_relative_config=True)
app.config.from_mapping(
    SECRET_KEY = 'F@ker',
    JSON_SORT_KEYS = False
)

app.register_blueprint(v1_blueprint, url_prefix="/v1")
app.register_blueprint(v2_blueprint, url_prefix="/v2")

@app.route('/rules')
def get_rules():
    ''' Show all available url
    '''
    rules = [str(rule) for rule in app.url_map.iter_rules()]
    return "\n".join(rules)


if __name__ == "__main__":
    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    app.run()
