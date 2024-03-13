#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import pandas as pd
import time
import yaml
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from sqlalchemy import inspect
from sqlalchemy.orm import DeclarativeBase, MappedAsDataclass


class BaseSQLClass(DeclarativeBase, MappedAsDataclass):
    ''' Base class
    '''
    def toDict(self):
        ''' Convert class to dictionary
        How to serialize SqlAlchemy PostgreSQL Query to JSON => https://stackoverflow.com/a/46180522
        '''
        return { c.key: getattr(self, c.key) for c in inspect(self).mapper.column_attrs }


db = SQLAlchemy(model_class=BaseSQLClass)
migrate = Migrate()

PROJECT_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(PROJECT_DIR, 'data')
DATA_SCHEMA = os.path.join(DATA_DIR, "ecom_schema.yml")


def init_database():
    ''' Init database with schema and sample data
    '''
    # Tables are created by command: "flask db upgrade"
    # So, we just need to import csv data into db
    # First read schema
    with open(DATA_SCHEMA, 'r', encoding='utf-8') as f:
        ecom_shema = yaml.safe_load(f)

    # Then, import data
    for table, schema in ecom_shema.items():
        data = pd.read_csv(os.path.join(DATA_DIR, schema['csv']))
        data.to_sql(con=db.engine,
                    index=False,
                    index_label=schema['index_colums'],
                    name=table,
                    if_exists="replace")
