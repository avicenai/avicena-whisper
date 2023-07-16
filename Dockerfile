FROM swaggerapi/swagger-ui:v4.18.2 AS swagger-ui
FROM huggingface/transformers-pytorch-gpu

ENV POETRY_VENV=/app/.venv

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
    ffmpeg

RUN python3 -m venv $POETRY_VENV \
    && $POETRY_VENV/bin/pip install -U pip setuptools \
    && $POETRY_VENV/bin/pip install poetry==1.4.0

WORKDIR /app

COPY poetry.lock pyproject.toml ./

RUN poetry config virtualenvs.in-project true
RUN poetry install

COPY . .
COPY --from=swagger-ui /usr/share/nginx/html/swagger-ui.css swagger-ui-assets/swagger-ui.css
COPY --from=swagger-ui /usr/share/nginx/html/swagger-ui-bundle.js swagger-ui-assets/swagger-ui-bundle.js

RUN poetry install
RUN $POETRY_VENV/bin/pip install torch==1.13.0+cu117 -f https://download.pytorch.org/whl/torch

CMD gunicorn --bind 0.0.0.0:9000 --workers 1 --timeout 0 app.webservice:app -k uvicorn.workers.UvicornWorker