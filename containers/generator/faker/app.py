#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from werkzeug.serving import WSGIRequestHandler
from faker import create_app

app = create_app(os.getenv("CONFIG_MODE"))

@app.route('/rules')
def get_rules():
    ''' Show all available url
    '''
    rules = [str(rule) for rule in app.url_map.iter_rules()]
    return "\n".join(rules)


if __name__ == "__main__":
    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    app.run()
