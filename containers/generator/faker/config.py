#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os

class Config:
    ''' Config base class
    '''
    SQLALCHEMY_TRACK_MODIFICATIONS = True
    JSON_SORT_KEYS = False


class DevelopmentConfig(Config):
    ''' Config class for development env
    '''
    DEVELOPMENT = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv("DEVELOPMENT_DATABASE_URL")


class TestingConfig(Config):
    ''' Config class for testing env
    '''
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.getenv("TEST_DATABASE_URL")


class StagingConfig(Config):
    ''' Config class for staging env
    '''
    DEVELOPMENT = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv("STAGING_DATABASE_URL")


class ProductionConfig(Config):
    ''' Config class for product env
    '''
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv("PRODUCTION_DATABASE_URL")


config = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "staging": StagingConfig,
    "production": ProductionConfig
}
