# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI OPA Policy Development Makefile
# ═══════════════════════════════════════════════════════════════════════════════
#
# Wzorce: kubescape/regolibrary + styrainc/enterprise-opa + conftest/conftest
#
# Usage:
#   make check          — syntax check all policies
#   make test           — run all Rego tests
#   make test-verbose   — run tests with verbose output
#   make build          — build OPA bundle
#   make check-legacy   — check existing nexus_ai tax rules
#   make clean          — remove build artifacts
#   make all            — check + test + build
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: check test test-verbose build check-legacy clean all

# ── Directories ──────────────────────────────────────────────────────────────
POLICIES_DIR  := policies
TAX_DIR       := $(POLICIES_DIR)/tax
BUILD_DIR     := $(POLICIES_DIR)/build
LEGACY_RULES  := nexus_ai/tax/rules.rego

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN := \033[0;32m
BLUE  := \033[0;34m
RED   := \033[0;31m
NC    := \033[0m

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK: Syntax validation
# ═══════════════════════════════════════════════════════════════════════════════
check:
	@echo "$(BLUE)[CHECK]$(NC) Running opa check --strict on policies/tax/..."
	@if opa check $(TAX_DIR)/ --strict 2>&1; then \
		echo "$(GREEN)  ✓ All policies pass syntax check$(NC)"; \
	else \
		echo "$(RED)  ✗ Syntax check failed$(NC)"; \
		exit 1; \
	fi

check-legacy:
	@echo "$(BLUE)[CHECK]$(NC) Running opa check --strict on $(LEGACY_RULES)..."
	@if opa check $(LEGACY_RULES) --strict 2>&1; then \
		echo "$(GREEN)  ✓ Legacy rules pass syntax check$(NC)"; \
	else \
		echo "$(RED)  ✗ Legacy rules syntax check failed$(NC)"; \
		exit 1; \
	fi

check-all: check check-legacy
	@echo "$(GREEN)✓ All checks passed$(NC)"

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Rule validation
# ═══════════════════════════════════════════════════════════════════════════════
test:
	@echo "$(BLUE)[TEST]$(NC) Running opa test..."
	@opa test $(POLICIES_DIR)/ -v 2>&1

test-verbose:
	@echo "$(BLUE)[TEST]$(NC) Running opa test (verbose)..."
	@opa test $(POLICIES_DIR)/ -v --explain full 2>&1

test-coverage:
	@echo "$(BLUE)[TEST]$(NC) Running opa test with coverage..."
	@opa test $(POLICIES_DIR)/ --coverage 2>&1

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD: OPA Bundle
# ═══════════════════════════════════════════════════════════════════════════════
build: check
	@echo "$(BLUE)[BUILD]$(NC) Building OPA bundle..."
	@mkdir -p $(BUILD_DIR)
	@REVISION="v$$(date +%Y.%m.%d)-$$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')"; \
	opa build \
		--bundle $(TAX_DIR) \
		--output $(BUILD_DIR)/nexusai-tax-policies-$$REVISION.tar.gz \
		--revision $$REVISION 2>&1
	@echo "$(GREEN)  ✓ Bundle built: $(BUILD_DIR)/nexusai-tax-policies-*.tar.gz$(NC)"

# ═══════════════════════════════════════════════════════════════════════════════
# ALL: Full CI pipeline
# ═══════════════════════════════════════════════════════════════════════════════
all: check test build
	@echo "$(GREEN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  All checks passed — bundle ready for deployment            ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════╝$(NC)"

# ═══════════════════════════════════════════════════════════════════════════════
# CLEAN
# ═══════════════════════════════════════════════════════════════════════════════
clean:
	@echo "$(BLUE)[CLEAN]$(NC) Removing build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)  ✓ Clean$(NC)"

# ═══════════════════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════════════════
help:
	@echo "NexusAI OPA Policy Development Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make check          — Syntax check all Rego policies (--strict)"
	@echo "  make check-legacy   — Check existing nexus_ai/tax/rules.rego"
	@echo "  make check-all      — Check all policies (new + legacy)"
	@echo "  make test           — Run all Rego tests"
	@echo "  make test-verbose   — Run tests with full explanation"
	@echo "  make test-coverage  — Run tests with coverage report"
	@echo "  make build          — Build OPA bundle for deployment"
	@echo "  make all            — check + test + build (full CI)"
	@echo "  make clean          — Remove build artifacts"
	@echo "  make help           — This help"
