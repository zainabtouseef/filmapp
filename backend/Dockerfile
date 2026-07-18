FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN addgroup --system cineconnect \
    && adduser --system --ingroup cineconnect --home /app cineconnect

WORKDIR /app/backend

COPY backend/pyproject.toml /app/backend/pyproject.toml
COPY backend/app /app/backend/app
RUN pip install --no-cache-dir .

COPY backend /app/backend
COPY docs/openapi.yaml /app/docs/openapi.yaml
RUN chown -R cineconnect:cineconnect /app

USER cineconnect
EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "--timeout", "60", "--access-logfile", "-", "app.wsgi:app"]

