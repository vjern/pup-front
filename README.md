# Pup Front

A no-framework front end application with Python and Vanilla JS / CSS.

## Add new endpoints

Add endpoints in [src/main.py](src/main.py).

## Add new pages

Each new page must have its own template in src/templates. The page's template should inherit from [src/templates/base.html](src/templates/base.html):

```
{% extends base.html %}
```

You can specify a dedicated sylesheet and/or script to go with your page:

```c#
{% set title = 'new page' %}
{% set script = 'index.js' %}  # implicit prefix: /static/scripts
{% set style = 'index.css' %}  # implicit prefix: /static/styles
```

Then place your content in the `body` block:

```html
{% block body %}
<h1> My New Page </h1>
<p> Lorem Ipsum </p>
{% endblock %}
```