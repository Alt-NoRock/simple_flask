from flask import Flask
from flask import request, render_template
from werkzeug.exceptions import HTTPException, InternalServerError

import logging
# logging.basicConfig(filename="/var/log/flask/log.txt")

app = Flask(__name__)


@app.route("/")
def hello():
    return render_template("index.html")


@app.route("/flag")
def get_flag():
    token = request.args.get('token')
    logging.error("%s", request.full_path)
    logging.error("%s", request.args)
    return "<h1 style='color:blue'>Hello There!</h1>"


@app.get("/error")
def error():
    raise ValueError("an error")


@app.errorhandler(Exception)
def handle_all_error(e: Exception):
    print("error:", e)
    return e if isinstance(e, HTTPException) else InternalServerError()


if __name__ == "__main__":
    app.run(host='0.0.0.0')