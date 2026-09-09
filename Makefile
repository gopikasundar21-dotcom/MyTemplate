# MyTemplate quality pipeline.
#
# Every check writes a report into ./reports so artifacts are easy to find and
# review after a run (locally or in CI). Windows users without `make` can run
# the mirror script instead:  pwsh ./run_checks.ps1
#
# Usage:
#   make install      Install runtime + dev dependencies and the Playwright browser
#   make lint          Ruff static analysis  -> reports/ruff.json (+ console)
#   make security      Bandit security scan  -> reports/bandit.json (+ console)
#   make test          Backend pytest + coverage -> reports/junit-backend.xml, coverage.xml, coverage_html/
#   make ui-test       Playwright UI tests   -> reports/junit-ui.xml
#   make coverage      Alias that runs the backend tests with coverage
#   make report        Print where every artifact landed
#   make ci            lint + security + test + ui-test + report (the full pipeline)
#   make clean         Remove generated reports and caches

# Use the module form so the project's virtualenv Python is respected.
PYTHON ?= python
PYTEST  = $(PYTHON) -m pytest
REPORTS = reports
APP_ENV = APPNAME_ENV=test

# The prod-config test needs a live Redis + a specific flask-caching version and
# is unrelated to application code; deselect it so the pipeline reflects real
# code health. Remove this once a Redis service is wired into CI.
DESELECT = --deselect tests/test_config.py::TestConfig::test_prod_config

.DEFAULT_GOAL := ci
.PHONY: install lint security test ui-test coverage report ci clean reports-dir \
        agent-setup agent-smoke agent-test

reports-dir:
	@mkdir -p $(REPORTS)

install:
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt -r requirements-dev.txt
	$(PYTHON) -m playwright install chromium

# --- Static analysis (Ruff) --------------------------------------------------
lint: reports-dir
	@echo ">> Ruff static analysis"
	# Machine-readable report for artifacts; never let the redirect swallow failures.
	$(PYTHON) -m ruff check . --output-format=json --output-file=$(REPORTS)/ruff.json || true
	# Human-readable pass/fail that gates the pipeline.
	$(PYTHON) -m ruff check .

# --- Security scanning (Bandit) ----------------------------------------------
security: reports-dir
	@echo ">> Bandit security scan"
	$(PYTHON) -m bandit -r appname -c pyproject.toml -f json -o $(REPORTS)/bandit.json || true
	$(PYTHON) -m bandit -r appname -c pyproject.toml

# --- Backend tests + coverage ------------------------------------------------
test: reports-dir
	@echo ">> Backend tests (pytest) + coverage"
	$(APP_ENV) $(PYTEST) tests/ $(DESELECT) \
		--junitxml=$(REPORTS)/junit-backend.xml \
		--cov=appname \
		--cov-report=term-missing \
		--cov-report=xml:$(REPORTS)/coverage.xml \
		--cov-report=html:$(REPORTS)/coverage_html

coverage: test

# --- UI tests (Playwright) ---------------------------------------------------
ui-test: reports-dir
	@echo ">> UI tests (Playwright)"
	$(APP_ENV) $(PYTEST) tests_ui/ -o testpaths=tests_ui \
		--junitxml=$(REPORTS)/junit-ui.xml

# --- Reporting ---------------------------------------------------------------
report:
	@echo ""
	@echo "Artifacts in ./$(REPORTS):"
	@echo "  Backend unit test report : $(REPORTS)/junit-backend.xml"
	@echo "  UI test report           : $(REPORTS)/junit-ui.xml"
	@echo "  Coverage (XML)           : $(REPORTS)/coverage.xml"
	@echo "  Coverage (HTML)          : $(REPORTS)/coverage_html/index.html"
	@echo "  Ruff lint report (JSON)  : $(REPORTS)/ruff.json"
	@echo "  Bandit security (JSON)   : $(REPORTS)/bandit.json"
	@echo ""

# Full pipeline. lint/security/test run first; ui-test then report always run.
ci: lint security test ui-test report

clean:
	rm -rf $(REPORTS) .pytest_cache .coverage htmlcov
	find . -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true

# --- Agent convenience aliases (referenced by AGENTS.md / AGENT_QUICKSTART) ---
agent-setup: install

agent-smoke: reports-dir
	@echo ">> Smoke test (fast backend subset)"
	$(APP_ENV) $(PYTEST) tests/ $(DESELECT) -q

agent-test: test
