#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Flask

from faker.config import config
from faker.database import db, migrate
from faker.v1.router import v1_blueprint
from faker.v2.router import v2_blueprint

def create_app(config_mode):
    ''' Create app function
    '''
    app = Flask(__name__)
    app.config.from_object(config[config_mode])

    app.register_blueprint(v1_blueprint, url_prefix="/v1")
    app.register_blueprint(v2_blueprint, url_prefix="/v2")

    db.init_app(app)
    migrate.init_app(app, db)

    return app
