.PHONY: format lint type test test-integration

format:
	../.venv/bin/ruff format .

lint:
	../.venv/bin/ruff check .
	../.venv/bin/ruff format --check .

type:
	../.venv/bin/mypy app

test:
	../.venv/bin/pytest tests/unit --cov=app --cov-report=term-missing

test-integration:
	RUN_INTEGRATION_TESTS=1 ../.venv/bin/pytest tests
