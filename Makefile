COMPOSE ?= docker-compose
TEST_COMPOSE ?= docker-compose -f docker-compose.test.yml
UV_RUN=uv run
MSG ?= $(word 2,$(MAKECMDGOALS))


.PHONY: prod-run
prod-run: ## Запустить сервер в продакшен режиме
	$(UV_RUN) uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --workers 4

.PHONY: prod-up
prod-up:
	$(COMPOSE) -f docker-compose.prod.yml up --build -d


.PHONY: dev-run
dev-run: ## Запустить сервер в режиме разработки (с перезагрузкой)
	$(UV_RUN) uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --reload

.PHONY: dev-up
dev-up: ## Запустить сервер в режиме разработки с зависимостями
	$(COMPOSE) up --build -d

.PHONY: lint
lint: ## Запустить линтер (ruff)
	$(UV_RUN) ruff check ./src --fix

.PHONY: prod-migrate
prod-migrate:
	$(COMPOSE) -f docker-compose.prod.yml --profile migrations up --build migrations


.PHONY: migration
migration:
	@if [ -z "$(MSG)" ]; then echo "ERROR: MSG is empty. Usage: make migration \"Your migrate message\" or make migration \"Your message\""; exit 1; fi
	$(COMPOSE) run --rm --build migrations alembic revision --autogenerate -m "$(MSG)"

%:
	@: