#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$prompt: " result
        echo "$result"
    fi
}

# Function to validate module name format
validate_module_name() {
    local module_name="$1"
    if [[ ! "$module_name" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        log_error "Invalid module name format. Use format like: github.com/username/repo-name"
        return 1
    fi
    return 0
}

# Function to extract GitHub info from git remote
get_github_info() {
    local remote_url
    local github_owner
    local github_repo
    
    # Try to get the remote URL
    if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        
        if [ -n "$remote_url" ]; then
            # Handle both SSH and HTTPS GitHub URLs
            if [[ "$remote_url" =~ git@github\.com:([^/]+)/([^.]+)(\.git)?$ ]]; then
                # SSH format: git@github.com:owner/repo.git
                github_owner="${BASH_REMATCH[1]}"
                github_repo="${BASH_REMATCH[2]}"
            elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^/]+)(\.git)?/?$ ]]; then
                # HTTPS format: https://github.com/owner/repo.git
                github_owner="${BASH_REMATCH[1]}"
                github_repo="${BASH_REMATCH[2]}"
            fi
        fi
    fi
    
    # Return the extracted info (empty if not found)
    echo "$github_owner" "$github_repo"
}

# Main setup function
main() {
    log_info "🚀 Setting up your Go HTTP Server from template..."
    echo

    # Get current directory name as default service name
    current_dir=$(basename "$(pwd)")
    
    # Try to detect GitHub repository information
    read -r github_owner github_repo <<< "$(get_github_info)"
    
    # Determine default module name
    default_module_name="github.com/yourorg/$current_dir"
    if [ -n "$github_owner" ] && [ -n "$github_repo" ]; then
        default_module_name="github.com/$github_owner/$github_repo"
        log_info "Detected GitHub repository: $github_owner/$github_repo"
    else
        log_warn "Could not detect GitHub repository information from git remote"
    fi
    
    # Prompt for module information
    echo "Please provide the following information for your new service:"
    echo
    
    # Get module name
    while true; do
        module_name=$(prompt_with_default "Go module name" "$default_module_name")
        if validate_module_name "$module_name"; then
            break
        fi
    done

    # Get service name (extract from module name or use current dir)
    service_name=$(basename "$module_name")
    service_name=$(prompt_with_default "Service name" "$service_name")

    # Get service description
    service_description=$(prompt_with_default "Service description" "HTTP service built with Go")

    echo
    log_info "Configuration:"
    log_info "  Module Name: $module_name"
    log_info "  Service Name: $service_name"
    log_info "  Description: $service_description"
    echo

    # Confirm before proceeding
    read -p "Proceed with setup? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Setup cancelled."
        exit 0
    fi

    echo
    log_info "🔧 Starting setup process..."

    # Step 1: Update go.mod with new module name
    log_info "1. Updating Go module name..."
    if [ -f "go.mod" ]; then
        go mod edit -module "$module_name"
        log_success "Updated go.mod with module name: $module_name"
    else
        log_error "go.mod not found!"
        exit 1
    fi

    # Step 2: Update import paths in Go files
    log_info "2. Updating import paths in Go files..."
    old_module="github.com/c1moore/go-http-server-template"

    # Find and update all Go files
    find . -name "*.go" -type f -exec grep -l "$old_module" {} \; | while read -r file; do
        sed -i "s|$old_module|$module_name|g" "$file"
        log_info "   Updated imports in: $file"
    done
    log_success "Updated import paths"

    # Step 3: Create .env file from template
    log_info "3. Setting up environment configuration..."
    if [ -f ".env.example" ] && [ ! -f ".env" ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_info "   Please review and update .env with your specific configuration"
    elif [ -f ".env" ]; then
        log_warn ".env file already exists, skipping creation"
    else
        log_error ".env.example not found!"
    fi

    # Step 4: Update README with service-specific information
    log_info "4. Updating README with service information..."
    if [ -f "README.md" ]; then
        # Update the title and description in README
        sed -i "1s/.*/# $service_name/" README.md
        sed -i "3s/.*/A $service_description./" README.md

        # Remove the Setup section since it's no longer needed after running this script
        # Find the Setup section and delete everything from there to the end of the file
        if grep -q "## Setup (Steps to Use This Template)" README.md; then
            # Create a temporary file with everything before the Setup section
            sed '/## Setup (Steps to Use This Template)/,$d' README.md > README.tmp
            mv README.tmp README.md
            log_info "   Removed Setup section (no longer needed after automated setup)"
        fi

        log_success "Updated README.md"
    else
        log_warn "README.md not found, skipping update"
    fi

    # Step 5: Initialize Git (if not already initialized)
    log_info "5. Checking Git initialization..."
    if [ ! -d ".git" ]; then
        git init
        log_success "Initialized Git repository"
    else
        log_info "Git repository already initialized"
    fi

    # Step 6: Download dependencies
    log_info "6. Downloading Go dependencies..."
    if command -v go >/dev/null 2>&1; then
        go mod download
        go mod tidy
        log_success "Downloaded and tidied Go dependencies"
    else
        log_warn "Go not found in PATH, skipping dependency download"
        log_info "Please run 'go mod download && go mod tidy' after installing Go"
    fi

    # Step 7: Install development tools (if make is available)
    log_info "7. Installing development tools..."
    if command -v make >/dev/null 2>&1; then
        if make init 2>/dev/null; then
            log_success "Installed development tools"
        else
            log_warn "Failed to install some development tools, you may need to install them manually"
            log_info "Run 'make init' after ensuring Go is properly configured"
        fi
    else
        log_warn "Make not found, skipping development tools installation"
        log_info "Please install make and run 'make init' to install development tools"
    fi

    # Step 8: Run initial quality checks (if tools are available)
    log_info "8. Running initial quality checks..."
    if command -v make >/dev/null 2>&1 && command -v go >/dev/null 2>&1; then
        if make fmt vet 2>/dev/null; then
            log_success "Initial quality checks passed"
        else
            log_warn "Some quality checks failed, please review and fix any issues"
        fi
    else
        log_warn "Skipping quality checks (make or go not available)"
    fi

    echo
    log_success "🎉 Setup completed successfully!"
    echo
    log_info "Next steps:"
    log_info "1. Review and update the .env file with your configuration"
    log_info "2. Start development with: make run"
    log_info "3. Run quality checks with: make quality"
    log_info "4. Build the service with: make build"
    log_info "5. Start with Docker: make up"
    echo
    log_info "For more information, see the README.md file."
    echo

    # Step 9: Self-destruct
    log_info "🗑️  Cleaning up setup script..."
    script_path="$0"
    if [ -f "$script_path" ]; then
        rm "$script_path"
        log_success "Setup script removed (no longer needed)"
    fi

    log_success "Setup complete! Happy coding! 🚀"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
