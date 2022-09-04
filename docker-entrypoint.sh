#! /bin/bash
pipenv install
pipenv run python -m gunicorn -b 0.0.0.0:5000 src.simple_flask.app:app