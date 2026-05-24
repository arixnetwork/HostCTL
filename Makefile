.PHONY: all build clean test lint proto docker-up docker-down dev help

APP_NAME = hostctl
BUILD_DIR = build
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS = -ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildTime=$(BUILD_TIME)"

all: build

build: ## Build the hostctl binary
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME) ./cmd/hostctl
	@echo "Built $(BUILD_DIR)/$(APP_NAME) ($(VERSION))"

build-linux: ## Build for Linux AMD64
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME)-linux-amd64 ./cmd/hostctl

build-linux-arm: ## Build for Linux ARM64
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME)-linux-arm64 ./cmd/hostctl

build-darwin: ## Build for macOS
	@mkdir -p $(BUILD_DIR)
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME)-darwin-amd64 ./cmd/hostctl

agent: ## Build the host agent binary
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME)-agent ./cmd/hostctl
	@echo "Built agent: $(BUILD_DIR)/$(APP_NAME)-agent"

clean: ## Clean build artifacts
	rm -rf $(BUILD_DIR)
	rm -rf cover.out

test: ## Run all tests
	go test -v -race -count=1 ./...

test-coverage: ## Run tests with coverage
	go test -v -race -coverprofile=cover.out -covermode=atomic ./...
	go tool cover -html=cover.out -o cover.html

lint: ## Run linters
	golangci-lint run ./...
	@echo "Lint passed"

proto: ## Generate gRPC code from protos
	protoc --go_out=. --go-grpc_out=. proto/agent.proto

dev: ## Run in development mode
	HOSTCTL_SERVER_PORT=8080 \
	HOSTCTL_DATABASE_HOST=localhost \
	HOSTCTL_DATABASE_PORT=5432 \
	HOSTCTL_DATABASE_DBNAME=hostctl \
	HOSTCTL_REDIS_HOST=localhost \
	go run ./cmd/hostctl server

docker-build: ## Build Docker images
	docker build -t hostctl/api:$(VERSION) -f deploy/docker/Dockerfile .
	docker build -t hostctl/agent:$(VERSION) -f deploy/docker/agent.Dockerfile .

docker-up: ## Start development environment with Docker Compose
	docker compose -f deploy/compose/docker-compose.yml up -d

docker-down: ## Stop development environment
	docker compose -f deploy/compose/docker-compose.yml down

db-migrate: ## Run database migrations
	psql -h localhost -U hostctl -d hostctl -f internal/database/schema.sql

help: ## Show this help
	@printf "\nUsage: make <target>\n\nTargets:\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

.DEFAULT_GOAL := help
