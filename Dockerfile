ARG PYTHON_VERSION=3.12

FROM python:$PYTHON_VERSION-slim AS build

ENV PYTHONUNBUFFERED=1

WORKDIR /code

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl unzip gcc python3-dev libpq-dev \
    && curl -L https://github.com/Gozargah/Marzban-scripts/raw/master/install_latest_xray.sh | bash \
    && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /code/
RUN python3 -m pip install --upgrade pip setuptools \
    && pip wheel --no-cache-dir --wheel-dir=/wheels -r /code/requirements.txt

FROM python:$PYTHON_VERSION-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHON_LIB_PATH=/usr/local/lib/python${PYTHON_VERSION%.*}/site-packages

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r /code/requirements.txt \
    && pip install --no-cache-dir 'setuptools>=69,<82' \
    && rm -rf /wheels

COPY --from=build /usr/local/share/xray /usr/local/share/xray
COPY --from=build /usr/local/bin/xray /usr/local/bin/xray

COPY . /code

RUN ln -s /code/marzban-cli.py /usr/bin/marzban-cli \
    && chmod +x /usr/bin/marzban-cli

CMD ["bash", "-c", "alembic upgrade head; python main.py"]