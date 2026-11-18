# Everyday commands; CI runs exactly `make ci` (docs/development.md).
# Uses `fvm flutter` when FVM is installed, plain `flutter` otherwise.
FLUTTER ?= $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo flutter)
DART    ?= $(shell command -v fvm >/dev/null 2>&1 && echo "fvm dart" || echo dart)
COVERAGE_MIN ?= 80
# Server of the end-to-end tests (make integration).
WAYLIGHT_URL ?= https://demo.getwaylight.app

.DEFAULT_GOAL := help
.PHONY: help deps gen format format-check lint test coverage check-generated ci integration run clean

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

deps: ## Install the packages
	$(FLUTTER) pub get

gen: ## Generate code (translations)
	$(FLUTTER) gen-l10n

format: ## Format all Dart files
	$(DART) format lib test tool integration_test

format-check: ## Fail if a file is not formatted
	$(DART) format --output=none --set-exit-if-changed lib test tool integration_test

lint: ## Static analysis; every info fails
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

test: ## Unit, widget and architecture tests
	$(FLUTTER) test

coverage: ## Tests with coverage and the minimum of $(COVERAGE_MIN) %
	$(FLUTTER) test --coverage
	$(DART) run tool/check_coverage.dart coverage/lcov.info $(COVERAGE_MIN)

check-generated: gen ## Fail if generated files are not committed
	@git diff --exit-code -- lib/l10n/generated || { echo "Run 'make gen' and commit the result."; exit 1; }

ci: deps check-generated format-check lint coverage ## Everything CI checks, before every pull request

integration: ## End-to-end tests on the connected device against WAYLIGHT_URL
	$(FLUTTER) test integration_test --dart-define=WAYLIGHT_URL=$(WAYLIGHT_URL)

run: ## Start the app on the connected device
	$(FLUTTER) run

clean: ## Remove build output
	$(FLUTTER) clean
	rm -rf coverage
