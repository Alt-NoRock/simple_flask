from flask import Flask
import logging
logging.basicConfig(filename="/var/log/flask/log.txt")

app = Flask(__name__)

@app.route("/")
def hello():
    logging.error("hello come")
    return "<h1 style='color:blue'>Hello There!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')