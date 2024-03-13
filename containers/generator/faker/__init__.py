#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Flask

from faker.database import db, migrate

from .config import config

def create_app(config_mode):
    app = Flask(__name__)
    app.config.from_object(config[config_mode])

    db.init_app(app)
    migrate.init_app(app, db)

    return app
