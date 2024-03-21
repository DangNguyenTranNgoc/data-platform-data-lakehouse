#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from flasgger import Swagger, LazyJSONEncoder
from werkzeug.serving import WSGIRequestHandler

from faker import create_app

app = create_app(os.getenv("CONFIG_MODE"))
app.json_encoder = LazyJSONEncoder

SWAGGER_TEMPLATE ={
    "swagger": "2.0",
    "info": {
        "title": "Generator",
        "description": "API Documentation for Generator",
        "contact": {
            "name": "Admin",
            "email": "admin@sample.com"
        },
        "version": "1.0",
        "host":"Wine_Quality_Prediction",
        "basePath":"http://localhost:5000",
        "license":{
            "name":"License of API",
            "url":"API license URL"
        }
    },
    "schemes": [
        "http",
        "https"
    ]
}

swagger = Swagger(app, template=SWAGGER_TEMPLATE)

@app.route('/rules')
def get_rules():
    ''' Show all available url
    '''
    rules = [str(rule) for rule in app.url_map.iter_rules()]
    return "\n".join(rules)


if __name__ == "__main__":
    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    app.run()
