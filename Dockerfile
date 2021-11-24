FROM python:3.8

WORKDIR /app

COPY requirements.lock /app
RUN pip install -r requirements.lock

COPY src/ /app

# This is enabled because https is abstracted away by IAP!
ENV OAUTHLIB_INSECURE_TRANSPORT 1

EXPOSE 8080

CMD gunicorn -b 0.0.0.0:8080 main:app
