"""RESTFUL WebAPI by Flask
"""

from flask import Flask, render_template

app = Flask(__name__)

@app.route("/")
def index():
    return "hello world"
    # render_template("index.html")

app.run()