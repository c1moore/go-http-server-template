.PHONY: build run up down tidy fmt lint lint-fix vet test cover clean quality

.DEFAULT_GOAL := help

help:
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''

init:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/vektra/mockery/v3@v3.5.1
	go install golang.org/x/vuln/cmd/govulncheck@latest

build:
	go build -o bin/server cmd/server.go

run:
	go run cmd/server.go

up:
	docker compose up -d --build

down:
	docker compose down

tidy:
	go mod tidy

fmt:
	go fmt ./...

lint:
	golangci-lint run

lint-fix:
	golangci-lint run --fix

vet:
	go vet ./...

deps:
	govulncheck ./...

test:
	go test ./... -v -race -coverprofile=coverage.out

cover:
	go tool cover -html=coverage.out

clean:
	rm -rf bin/

quality:
	@echo "Running quality checks..."
	@echo ""
	@failed_steps=""; \
	total_steps=7; \
	current_step=0; \
	\
	run_step() { \
		local step_name="$$1"; \
		local target_name="$$2"; \
		current_step=$$((current_step + 1)); \
		printf "[%d/%d] %-25s" $$current_step $$total_steps "$$step_name..."; \
		if output=$$($(MAKE) $$target_name 2>&1); then \
			echo " ✅ Success"; \
		else \
			echo " ❌ Failed"; \
			echo ""; \
			echo "=== $$step_name output ==="; \
			echo "$$output"; \
			echo "========================"; \
			echo ""; \
			failed_steps="$$failed_steps $$step_name"; \
		fi; \
	}; \
	\
	run_step "Formatting" "fmt"; \
	run_step "Vet checks" "vet"; \
	run_step "Vulnerability checks" "deps"; \
	run_step "Linting" "lint"; \
	run_step "Tidy checks" "tidy"; \
	run_step "Tests" "test"; \
	run_step "Build" "build"; \
	\
	echo ""; \
	if [ -z "$$failed_steps" ]; then \
		echo "🎉 All quality checks passed!"; \
		exit 0; \
	else \
		echo "💥 Quality checks failed in:$$failed_steps"; \
		exit 1; \
	fi
