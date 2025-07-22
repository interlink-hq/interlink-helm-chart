# Makefile for interlink Helm chart
CHART_DIR := interlink
EXAMPLES_DIR := $(CHART_DIR)/examples
HELM := helm

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  lint         - Run helm lint on the chart"
	@echo "  test         - Run all tests (lint + template validation)"
	@echo "  test-templates - Test helm templates against all examples"
	@echo "  test-examples  - Test individual example files"
	@echo "  clean        - Clean generated files"
	@echo "  publish      - Publish chart using chartpress"
	@echo "  reset        - Reset chart to development state"

# Lint the chart
.PHONY: lint
lint:
	@echo "Running helm lint..."
	$(HELM) lint $(CHART_DIR)/

# Test helm templates against all examples
.PHONY: test-templates
test-templates:
	@echo "Testing helm templates against examples..."
	@for example in $(EXAMPLES_DIR)/*.yaml; do \
		echo "Testing $$example..."; \
		$(HELM) template test-release $(CHART_DIR) --values $$example > /dev/null || exit 1; \
		echo "✓ $$example passed"; \
	done
	@echo "All template tests passed!"

# Test individual examples
.PHONY: test-edge-rest
test-edge-rest:
	@echo "Testing edge with REST example..."
	$(HELM) template test-edge-rest $(CHART_DIR) --values $(EXAMPLES_DIR)/edge_with_rest.yaml

.PHONY: test-edge-socket
test-edge-socket:
	@echo "Testing edge with socket example..."
	$(HELM) template test-edge-socket $(CHART_DIR) --values $(EXAMPLES_DIR)/edge_with_socket.yaml

.PHONY: test-extra-volumes
test-extra-volumes:
	@echo "Testing extra volumes example..."
	$(HELM) template test-extra-volumes $(CHART_DIR) --values $(EXAMPLES_DIR)/test-extra-volumes.yaml

.PHONY: test-examples
test-examples: test-edge-rest test-edge-socket test-extra-volumes

# Dry run installations
.PHONY: dry-run-edge-rest
dry-run-edge-rest:
	@echo "Dry run: edge with REST..."
	$(HELM) install --dry-run --debug test-edge-rest $(CHART_DIR) --values $(EXAMPLES_DIR)/edge_with_rest.yaml

.PHONY: dry-run-edge-socket
dry-run-edge-socket:
	@echo "Dry run: edge with socket..."
	$(HELM) install --dry-run --debug test-edge-socket $(CHART_DIR) --values $(EXAMPLES_DIR)/edge_with_socket.yaml

.PHONY: dry-run-extra-volumes
dry-run-extra-volumes:
	@echo "Dry run: extra volumes..."
	$(HELM) install --dry-run --debug test-extra-volumes $(CHART_DIR) --values $(EXAMPLES_DIR)/test-extra-volumes.yaml

.PHONY: dry-run-all
dry-run-all: dry-run-edge-rest dry-run-edge-socket dry-run-extra-volumes

# Run all tests
.PHONY: test
test: lint test-templates
	@echo "All tests passed! ✓"

# Chart publishing
.PHONY: publish
publish:
	@echo "Publishing chart..."
	chartpress --push

.PHONY: reset
reset:
	@echo "Resetting chart to development state..."
	chartpress --reset

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	@rm -f $(CHART_DIR)/charts/*.tgz 2>/dev/null || true
	@rm -rf $(CHART_DIR)/charts/*/. 2>/dev/null || true

# Development helpers
.PHONY: template-default
template-default:
	@echo "Templating with default values..."
	$(HELM) template test-default $(CHART_DIR)

.PHONY: install-local
install-local:
	@echo "Installing chart locally for testing..."
	$(HELM) install --create-namespace -n interlink-test test-local $(CHART_DIR)

.PHONY: uninstall-local
uninstall-local:
	@echo "Uninstalling local test chart..."
	$(HELM) uninstall test-local -n interlink-test || true
	kubectl delete namespace interlink-test || true

# Validation helpers
.PHONY: validate-values
validate-values:
	@echo "Validating values.yaml syntax..."
	@python3 -c "import yaml; yaml.safe_load(open('$(CHART_DIR)/values.yaml'))" && echo "✓ values.yaml is valid"

.PHONY: validate-examples
validate-examples:
	@echo "Validating example YAML files..."
	@for example in $(EXAMPLES_DIR)/*.yaml; do \
		echo "Validating $$example..."; \
		python3 -c "import yaml; yaml.safe_load(open('$$example'))" && echo "✓ $$example is valid"; \
	done