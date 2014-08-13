#!/usr/bin/env python
# encoding: utf-8

from server import create_app

if __name__ == '__main__':
    MAIN = create_app()
    MAIN.run()