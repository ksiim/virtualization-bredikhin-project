# Сборка зависимостей
FROM python:3.12-slim AS builder
WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /bin/uv

ENV PATH="/app/.venv/bin:$PATH"
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Копируем только файлы зависимостей
COPY ./pyproject.toml ./uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project

# Копируем код приложения
COPY ./Makefile /app/Makefile
COPY ./src/app /app/./src/app
COPY ./src/migrations /app/src/migrations
COPY ./alembic.ini /app/src/alembic.ini


# Миграции
FROM python:3.12-slim AS migrations
WORKDIR /app
RUN apt-get update && apt-get install -y curl make && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app /app
COPY --from=builder /app/src/migrations /app/src/migrations

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app:/app"
ENV ALEMBIC_CONFIG=/app/src/alembic.ini
CMD ["alembic", "upgrade", "head"]

# Development
FROM python:3.12-slim AS dev
WORKDIR /app
RUN apt-get update && apt-get install -y curl make && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /usr/local/bin/uv
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app /app
COPY --from=builder /app/Makefile /app/Makefile
COPY --from=builder /app/src/migrations /app/migrations

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app:/app"
ENV ALEMBIC_CONFIG=/app/src/alembic.ini
CMD ["make dev-run"]

# Production
FROM python:3.12-slim AS prod
WORKDIR /app

RUN apt-get update && apt-get install -y curl make && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /usr/local/bin/uv
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app /app
COPY --from=builder /app/Makefile /app/Makefile

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app:/app"
ENV ALEMBIC_CONFIG=/app/src/alembic.ini
CMD ["uvicorn", "src.app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]