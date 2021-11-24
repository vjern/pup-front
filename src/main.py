from functools import partial

from flask import Flask, render_template


app = Flask(__name__, template_folder='templates', static_folder='static')
app.get = partial(app.route, methods=['GET'])
app.post = partial(app.route, methods=['POST'])


@app.get('/')
def index():
    return render_template(
        'index.html'
    )
