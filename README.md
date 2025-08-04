# Go HTTP Server Template

A production-ready template for building HTTP servers in Go with modern best practices, clean architecture, and comprehensive tooling.

## Project Overview

This template provides a solid foundation for building scalable HTTP services in Go. It implements clean architecture principles with a focus on maintainability, testability, and operational excellence. The template includes configuration management, structured logging, health checks, containerization, and a comprehensive development workflow.

### Key Features

- **Clean Architecture**: Organized with `cmd/` and `internal/` structure following Go project layout standards
- **Production Ready**: Graceful shutdown, health checks, structured logging, and containerization
- **Developer Experience**: Comprehensive Makefile, quality gates, and CI/CD pipeline
- **Configuration Management**: Environment-based config with validation
- **Observability**: Structured logging with zerolog and health endpoints

## Architectural Patterns & Design

### Clean Architecture

The project follows Go's standard project layout and clean architecture principles:

```
├── cmd/                    # Application entry points
│   └── server.go          # Main HTTP server
├── internal/              # Private application code
│   ├── config/            # Configuration management
│   └── health/            # Health check handlers
└── ...
```

### Key Design Patterns

- **Dependency Injection**: Configuration and logger passed through the application
- **Middleware Pattern**: HTTP middleware for logging, recovery, and cross-cutting concerns
- **Handler Pattern**: Clean separation of HTTP transport and business logic
- **Environment-based Configuration**: 12-factor app compliance with environment variables
- **Graceful Shutdown**: Proper resource cleanup on application termination

### HTTP Layer Architecture

The HTTP layer is built using Gin framework with:
- Router groups for logical endpoint organization
- Middleware for cross-cutting concerns (logging, recovery)
- Clean separation between transport (HTTP) and business logic

## Technology Stack

### Core Dependencies

- **[Gin](https://github.com/gin-gonic/gin)**: High-performance HTTP web framework
- **[Zerolog](https://github.com/rs/zerolog)**: Fast, structured logging library
- **[Env](https://github.com/caarlos0/env)**: Environment variable parsing with struct tags
- **[Godotenv](https://github.com/joho/godotenv)**: Load environment variables from `.env` files
- **[Validator](https://github.com/go-playground/validator)**: Struct validation with tags

### Development Tools

- **[golangci-lint](https://golangci-lint.run/)**: Fast Go linters runner
- **[Mockery](https://github.com/vektra/mockery)**: Mock generation for interfaces
- **[govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)**: Vulnerability scanner

### Infrastructure

- **Docker**: Multi-stage builds with Alpine Linux
- **Docker Compose**: Local development environment
- **Chamber**: Secrets management (AWS Parameter Store/Secrets Manager)
- **GitHub Actions**: CI/CD pipeline

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── pull-request.yaml    # CI/CD pipeline
├── cmd/
│   └── server.go               # Application entry point
├── internal/
│   ├── config/
│   │   └── config.go           # Configuration management
│   └── health/
│       ├── controller.go       # HTTP handlers
│       ├── service.go          # Business logic
├── bin/                        # Built binaries (gitignored)
├── .env.example               # Environment variables template
├── .mockery.yml               # Mock generation configuration
├── docker-compose.yml         # Local development setup
├── Dockerfile                 # Production container image
├── Makefile                   # Development commands
├── go.mod                     # Go module definition
└── README.md                  # This file
```

### Directory Conventions

- `cmd/`: Application entry points and main packages
- `internal/`: Private application code that cannot be imported by other projects
- `internal/config/`: Configuration structures and loading logic
- `internal/health/`: Health check endpoints and logic
- `bin/`: Compiled binaries (created by build process)

## Development Tools & Commands

### Prerequisites

```bash
# Install development dependencies
make init
```

This installs:
- `golangci-lint`: Code linting
- `mockery`: Mock generation
- `govulncheck`: Vulnerability scanning

### Core Commands

```bash
# Build the application
make build

# Run the application locally
make run

# Run with Docker Compose
make up
make down

# Code quality
make fmt          # Format code
make lint         # Run linter
make lint-fix     # Fix linting issues
make vet          # Run go vet
make test         # Run tests
make deps         # Check vulnerabilities

# Comprehensive quality check
make quality      # Runs all quality checks

# Cleanup
make clean        # Remove built binaries
make tidy         # Clean up go.mod
```

### Quality Gate

The `make quality` command runs a comprehensive quality check:
1. Code formatting (`gofmt`)
2. Vet checks (`go vet`)
3. Vulnerability scanning (`govulncheck`)
4. Linting (`golangci-lint`)
5. Module tidiness (`go mod tidy`)
6. Tests (`go test`)
7. Build verification

## Testing Strategy

### Framework

Tests should use the **testify** framework:
- `testify/assert`: Assertions for test conditions
- `testify/require`: Assertions that stop test execution on failure

### Mock Generation

Mocks are generated using **Mockery** with testify-compatible templates:

```bash
# Generate mocks for interfaces
mockery --all
```

Configuration in `.mockery.yml`:
- Generates testify-compatible mocks
- Places mocks in `mocks/` subdirectories
- Uses `Mock{{.InterfaceName}}` naming convention

### Test Structure

While no test files exist yet in the template, follow these conventions:

```go
package mypackage_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestMyFunction(t *testing.T) {
    // Use require for setup that must succeed
    config, err := LoadTestConfig()
    require.NoError(t, err)

    // Use assert for test conditions
    result := MyFunction(config)
    assert.Equal(t, expectedValue, result)
}
```

### Running Tests

```bash
# Run all tests with race detection
make test

# Run tests with coverage
make cover
```

## Style Guidelines

### Code Formatting

- Use `gofmt` for consistent formatting
- Run `make fmt` to format all code
- CI enforces formatting compliance

### Linting

- `golangci-lint` enforces code quality standards
- Configuration follows Go community best practices
- Run `make lint` to check compliance
- Use `make lint-fix` to auto-fix issues where possible

### Code Organization

- Follow Go's standard project layout
- Use meaningful package names
- Keep packages focused and cohesive
- Prefer composition over inheritance
- Use interfaces for abstraction boundaries

### Naming Conventions

- Use Go's standard naming conventions
- Exported functions/types start with capital letters
- Use camelCase for multi-word names
- Prefer short, descriptive names
- Use consistent naming across the codebase

### Documentation

- Document all exported functions and types
- Use Go's standard comment format
- Include examples for complex functionality
- Keep comments up-to-date with code changes

## API Endpoint Architecture & Implementation Patterns

### Router Organization

Endpoints are organized using Gin's router groups:

```go
// Group related endpoints
healthGroup := router.Group("/health")
health.InitRoutes(healthGroup)

// Example of additional groups
apiV1 := router.Group("/api/v1")
// Initialize v1 routes...
```

### Handler Pattern

The template follows a clean handler pattern:

```go
// controller.go - HTTP layer
func InitRoutes(r *gin.RouterGroup) {
    r.GET("/ready", readinessHandler)
    r.GET("/live", livenessHandler)
}

func readinessHandler(c *gin.Context) {
    // Call business logic
    result, err := getHealth()
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    c.JSON(200, result)
}
```

```go
// service.go - Business logic
func getHealth() (HealthResult, error) {
    // Business logic implementation
    return HealthResult{}, nil
}
```

### Middleware Usage

The server uses middleware for cross-cutting concerns:

```go
router.Use(gin.Recovery())                    // Panic recovery
router.Use(gin.WrapH(hlog.NewHandler(logger)(nil))) // Structured logging
```

### Health Endpoints

Standard health check endpoints:
- `GET /health/live`: Liveness probe (always returns 200)
- `GET /health/ready`: Readiness probe (checks dependencies)

### Error Handling

- Use structured error responses
- Log errors with appropriate levels
- Return meaningful HTTP status codes
- Include error context for debugging

## Setup (Steps to Use This Template)

### Automated Setup (Recommended)

This template includes an automated setup script that handles all the initialization steps:

1. **Create a new repository from this template** on GitHub
2. **Clone your new repository** locally
3. **Run the setup script**:

```bash
./setup.sh
```

The setup script will:
- Automatically detect your GitHub repository information
- Update the Go module name and import paths
- Create your `.env` file from the template
- Update the README with your service information
- Download dependencies and install development tools
- Run initial quality checks
- Clean up by deleting itself

### Manual Setup (Alternative)

If you prefer to set up manually or need to customize the process:

```bash
# Update module name in go.mod
go mod edit -module github.com/yourorg/my-service

# Update import paths in code
find . -name "*.go" -exec sed -i 's|github.com/c1moore/go-http-server-template|github.com/yourorg/my-service|g' {} +
```

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
vim .env
```

Required environment variables:
- `SERVER_PORT`: HTTP server port (default: 8080)
- `SERVER_LOG_LEVEL`: Log level (debug, info, warn, error)
- `SERVER_ENV`: Environment (local, dev, staging, prod)
- `SERVER_ADDRESS`: Bind address (optional, defaults to all interfaces)

### 3. Development Setup

```bash
# Install development dependencies
make init

# Download Go modules
go mod download

# Run quality checks
make quality

# Start development server
make run
```

### 4. Docker Development

```bash
# Start with Docker Compose
make up

# Check health
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready

# Stop services
make down
```

### 5. Add Your Business Logic

1. **Create new packages** in `internal/` for your domain logic
2. **Add route handlers** following the transport/business logic pattern
3. **Update configuration** in `internal/config/` as needed
4. **Write tests** using testify framework
5. **Generate mocks** for interfaces using mockery

### 6. Customize Configuration

```go
// Add new config fields to internal/config/config.go
type Config struct {
    Server   ServerConfig   `envPrefix:"SERVER_"`
    Database DatabaseConfig `envPrefix:"DB_"`     // Add your config
}

type DatabaseConfig struct {
    URL string `env:"URL" validate:"required"`
}
```

### 7. Production Deployment

```bash
# Build production image
docker build -t my-service:latest .

# Run with production config
docker run -p 8080:8080 \
  -e SERVER_ENV=prod \
  -e SERVER_LOG_LEVEL=info \
  my-service:latest
```

The template is now ready for your specific use case. Follow the established patterns for consistency and maintainability.
