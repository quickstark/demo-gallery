#!/bin/bash

# =============================================================================
# React App Production Deployment Script for CircleCI
# =============================================================================
# This script handles the complete deployment workflow:
# 1. Environment variable setup
# 2. Git operations (add, commit, push)
# 3. CircleCI context update (environment variables)
# 4. Deployment monitoring
#
# Usage: ./scripts/deploy.sh [env-file] [--force]
#        --force: Force update CircleCI context even if unchanged

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_ENV_FILE=".env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CIRCLECI_CONFIG_FILE=".circleci/config.yml"

# CircleCI Configuration
CIRCLECI_ORG="${CIRCLECI_ORG:-}"  # Set your CircleCI organization
CIRCLECI_PROJECT="${CIRCLECI_PROJECT:-demo-gallery}"
CIRCLECI_CONTEXT="${CIRCLECI_CONTEXT:-app-config}"

# Helper functions
print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    while true; do
        read -p "$prompt" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) 
                if [[ "$default" == "y" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if CircleCI CLI is installed
    if ! command -v circleci &> /dev/null; then
        print_warning "CircleCI CLI is not installed"
        echo "Install it from: https://circleci.com/docs/2.0/local-cli/"
        echo
        echo "Quick install:"
        echo "  brew install circleci  # macOS"
        echo "  curl -fLSs https://circle.ci/cli | bash  # Linux"
        
        if prompt_yes_no "Continue without CircleCI CLI? (limited functionality)"; then
            CIRCLECI_CLI_AVAILABLE="false"
        else
            exit 1
        fi
    else
        CIRCLECI_CLI_AVAILABLE="true"
        
        # Validate CircleCI config if CLI is available
        if [[ -f "$CIRCLECI_CONFIG_FILE" ]]; then
            print_step "Validating CircleCI configuration..."
            if circleci config validate "$CIRCLECI_CONFIG_FILE" &>/dev/null; then
                print_success "CircleCI configuration is valid"
            else
                print_warning "CircleCI configuration has issues:"
                circleci config validate "$CIRCLECI_CONFIG_FILE"
            fi
        fi
    fi
    
    # Check for CircleCI API token
    if [[ -z "$CIRCLECI_API_TOKEN" ]]; then
        print_warning "CIRCLECI_API_TOKEN not set"
        echo "Get your API token from: https://app.circleci.com/settings/user/tokens"
        echo
        read -sp "Enter CircleCI API token (or press Enter to skip): " token
        echo
        if [[ -n "$token" ]]; then
            export CIRCLECI_API_TOKEN="$token"
            print_success "CircleCI API token set for this session"
        else
            print_warning "Some features will be limited without API token"
        fi
    fi
    
    print_success "Prerequisites check completed"
    echo
}

select_env_file() {
    local env_file="$1"
    
    if [[ -z "$env_file" ]]; then
        echo -e "${YELLOW}Available environment files:${NC}" >&2
        local files=()
        for file in .env* env.*; do
            if [[ -f "$file" && "$file" != ".env.example" ]]; then
                files+=("$file")
                echo "  - $file" >&2
            fi
        done
        
        if [[ ${#files[@]} -eq 0 ]]; then
            print_warning "No environment files found" >&2
            if prompt_yes_no "Create .env from .env.example?"; then
                if [[ -f ".env.example" ]]; then
                    cp .env.example .env
                    print_success "Created .env from template" >&2
                    echo -e "${YELLOW}Please edit .env with your actual values before continuing${NC}" >&2
                    exit 0
                else
                    print_error "No .env.example template found" >&2
                    exit 1
                fi
            else
                exit 1
            fi
        fi
        
        echo >&2
        read -p "Enter environment file path [$DEFAULT_ENV_FILE]: " env_file >&2
        env_file="${env_file:-$DEFAULT_ENV_FILE}"
    fi
    
    if [[ ! -f "$env_file" ]]; then
        print_error "Environment file '$env_file' not found" >&2
        exit 1
    fi
    
    echo "$env_file"
}

validate_env_file() {
    local env_file="$1"
    
    print_step "Validating environment file: $env_file"
    
    # Count total variables and placeholders
    local total_vars=0
    local placeholder_vars=0
    local empty_vars=0
    local required_vars=(
        "VITE_API_URL"
        "VITE_ENVIRONMENT"
    )
    local optional_vars=(
        "VITE_USE_AUTH"
        "VITE_AUTH_USERNAME"
        "VITE_AUTH_PASSWORD"
        "VITE_DATADOG_APPLICATION_ID"
        "VITE_DATADOG_CLIENT_TOKEN"
        "VITE_DATADOG_SITE"
        "VITE_DATADOG_SERVICE"
        "VITE_RELEASE"
    )
    
    # Check required variables
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$env_file"; then
            print_error "Missing required variable: $var"
            exit 1
        fi
    done
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes
            value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
            
            ((total_vars++))
            
            if [[ -z "$value" ]]; then
                ((empty_vars++))
                print_warning "Empty value for: $key"
            elif [[ "$value" =~ ^(your-|test-|placeholder) ]]; then
                ((placeholder_vars++))
                print_warning "Placeholder value for: $key"
            fi
        fi
    done < "$env_file"
    
    echo
    echo -e "${CYAN}Environment File Summary:${NC}"
    echo -e "  Total variables: $total_vars"
    echo -e "  Valid values: $((total_vars - placeholder_vars - empty_vars))"
    echo -e "  Placeholder values: $placeholder_vars"
    echo -e "  Empty values: $empty_vars"
    echo
    
    if [[ $placeholder_vars -gt 0 ]]; then
        print_warning "Some variables have placeholder values"
        if ! prompt_yes_no "Continue with deployment anyway?"; then
            print_error "Please update your environment file with actual values"
            exit 1
        fi
    fi
    
    print_success "Environment file validation completed"
    echo
}

check_git_status() {
    print_step "Checking git status..."
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "You have uncommitted changes:"
        echo
        git status --porcelain
        echo
        
        if prompt_yes_no "Would you like to add and commit all changes?"; then
            return 0  # Proceed with git operations
        else
            print_warning "Proceeding without committing changes"
            return 1
        fi
    else
        print_success "Working directory is clean"
        return 1  # No git operations needed
    fi
}

perform_git_operations() {
    print_step "Performing git operations..."
    
    # Add all changes
    print_step "Adding all changes..."
    git add .
    
    # Show what will be committed
    echo -e "${YELLOW}Files to be committed:${NC}"
    git diff --cached --name-status
    echo
    
    # Get commit message
    local default_message="Deploy: Update React app with latest changes"
    read -p "Enter commit message [$default_message]: " commit_message
    commit_message="${commit_message:-$default_message}"
    
    # Commit changes
    print_step "Committing changes..."
    git commit -m "$commit_message"
    
    # Check current branch
    local current_branch=$(git branch --show-current)
    print_step "Current branch: $current_branch"
    
    # Push changes
    if prompt_yes_no "Push changes to origin/$current_branch?" "y"; then
        print_step "Pushing to origin/$current_branch..."
        git push origin "$current_branch"
        print_success "Changes pushed successfully"
    else
        print_warning "Skipping git push - you'll need to push manually"
    fi
    
    echo
}

update_circleci_context() {
    local env_file="$1"
    local force_update="$2"
    
    print_step "Updating CircleCI context variables..."
    
    if [[ -z "$CIRCLECI_API_TOKEN" ]]; then
        print_warning "Cannot update CircleCI context without API token"
        echo
        echo -e "${YELLOW}Manual update required:${NC}"
        echo "1. Go to: https://app.circleci.com/settings/organization/github/${CIRCLECI_ORG}/contexts"
        echo "2. Click on context: ${CIRCLECI_CONTEXT}"
        echo "3. Update the following environment variables:"
        echo
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ ! "$line" =~ ^[[:space:]]*# && "$line" =~ ^([^=]+)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                echo "   - $key"
            fi
        done < "$env_file"
        echo
        return
    fi
    
    # Create context if it doesn't exist
    print_step "Checking CircleCI context: ${CIRCLECI_CONTEXT}..."
    
    # Update environment variables
    local updated_count=0
    local failed_count=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes
            value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
            
            # Update context variable using CircleCI API
            if curl -s -X PUT \
                -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"value\": \"${value}\"}" \
                "https://circleci.com/api/v2/context/${CIRCLECI_CONTEXT}/environment-variable/${key}" \
                >/dev/null 2>&1; then
                ((updated_count++))
                echo -e "  ${GREEN}✓${NC} Updated: $key"
            else
                ((failed_count++))
                echo -e "  ${RED}✗${NC} Failed: $key"
            fi
        fi
    done < "$env_file"
    
    echo
    print_success "Context update completed: $updated_count successful, $failed_count failed"
    echo
}

trigger_circleci_pipeline() {
    print_step "Triggering CircleCI pipeline..."
    
    if [[ -z "$CIRCLECI_API_TOKEN" ]]; then
        print_warning "Cannot trigger pipeline without API token"
        echo "Pipeline will be triggered automatically on git push"
        return
    fi
    
    local current_branch=$(git branch --show-current)
    
    # Trigger pipeline using CircleCI API
    local response=$(curl -s -X POST \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"branch\": \"${current_branch}\"}" \
        "https://circleci.com/api/v2/project/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}/pipeline")
    
    if echo "$response" | grep -q "created_at"; then
        local pipeline_id=$(echo "$response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
        print_success "Pipeline triggered successfully"
        echo "Pipeline ID: $pipeline_id"
        echo "View at: https://app.circleci.com/pipelines/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}"
    else
        print_warning "Could not trigger pipeline via API"
        echo "Pipeline will be triggered by git push"
    fi
    echo
}

monitor_deployment() {
    print_step "Monitoring deployment..."
    
    # Provide CircleCI links
    echo -e "${CYAN}CircleCI Links:${NC}"
    echo "  📊 Pipelines: https://app.circleci.com/pipelines/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}"
    echo "  ⚙️  Contexts: https://app.circleci.com/settings/organization/github/${CIRCLECI_ORG}/contexts"
    echo "  🔐 Project Settings: https://app.circleci.com/settings/project/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}"
    echo
    
    if [[ "$CIRCLECI_CLI_AVAILABLE" == "true" ]]; then
        if prompt_yes_no "Would you like to follow the build logs?"; then
            echo "Opening CircleCI dashboard in browser..."
            open "https://app.circleci.com/pipelines/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}" 2>/dev/null || \
            xdg-open "https://app.circleci.com/pipelines/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}" 2>/dev/null || \
            echo "Please open: https://app.circleci.com/pipelines/github/${CIRCLECI_ORG}/${CIRCLECI_PROJECT}"
        fi
    fi
}

show_deployment_checklist() {
    print_header "Pre-Deployment Checklist"
    
    echo -e "${CYAN}CircleCI Configuration:${NC}"
    echo "  [ ] CircleCI project is connected to GitHub repository"
    echo "  [ ] CircleCI contexts are configured:"
    echo "      - docker-hub (DOCKER_USERNAME, DOCKER_PASSWORD)"
    echo "      - tailscale (TAILSCALE_OAUTH_CLIENT_ID, TAILSCALE_OAUTH_CLIENT_SECRET)"
    echo "      - deployment (DEPLOY_HOST, DEPLOY_USER, SSH_PRIVATE_KEY, etc.)"
    echo "      - app-config (Your VITE_* environment variables)"
    echo
    echo -e "${CYAN}Docker Hub:${NC}"
    echo "  [ ] Docker Hub account created"
    echo "  [ ] Access token generated (not password)"
    echo "  [ ] Repository will be created as: ${DOCKER_USERNAME:-your-username}/demo-gallery"
    echo
    echo -e "${CYAN}Server Configuration:${NC}"
    echo "  [ ] Tailscale installed and configured on Linux server"
    echo "  [ ] SSH key pair generated for deployment"
    echo "  [ ] Docker installed on target server"
    echo "  [ ] Traefik/Nginx configured (if using)"
    echo
    
    if ! prompt_yes_no "Have you completed the checklist?" "y"; then
        print_warning "Please complete the setup before deploying"
        echo "Refer to DEPLOYMENT_NOTES.md for detailed instructions"
        exit 0
    fi
    echo
}

show_post_deployment_info() {
    print_header "Deployment Process Started!"
    
    echo -e "${GREEN}🎉 Your React application deployment has been initiated!${NC}"
    echo
    echo -e "${CYAN}What happens next:${NC}"
    echo "  1. CircleCI will run tests and build the application"
    echo "  2. Docker image will be built and pushed to Docker Hub"
    echo "  3. Tailscale VPN connection will be established"
    echo "  4. Application will be deployed to your Linux server"
    echo "  5. Health checks will verify the deployment"
    echo
    echo -e "${CYAN}API Configuration:${NC}"
    if grep -q "VITE_USE_AUTH=false" "$1" 2>/dev/null; then
        echo "  🔓 Running in PUBLIC mode (no authentication)"
        echo "  ⚠️  Make sure your API is configured to bypass authentication"
    else
        echo "  🔐 Running with authentication enabled"
        echo "  ⚠️  Ensure Authelia is configured to accept Proxy-Authorization headers"
    fi
    echo
    echo -e "${CYAN}Monitoring:${NC}"
    echo "  • Watch CircleCI for build progress"
    echo "  • Check Docker Hub for image upload"
    echo "  • SSH to server and check: docker ps"
    echo "  • Test application at: http://your-server:3001"
    echo
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "  • Build fails: Check CircleCI logs"
    echo "  • Auth issues: Review AUTHELIA_SETUP.md"
    echo "  • CORS errors: Check CORS_AUTH_FIX.md"
    echo "  • Container issues: docker logs demo-gallery"
    echo
}

main() {
    cd "$PROJECT_ROOT"
    
    # Parse command line arguments
    local env_file=""
    local force_update="false"
    local skip_checklist="false"
    
    for arg in "$@"; do
        case $arg in
            --force|-f)
                force_update="true"
                shift
                ;;
            --skip-checklist)
                skip_checklist="true"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [env-file] [options]"
                echo ""
                echo "Options:"
                echo "  env-file         Path to environment file (default: .env)"
                echo "  --force,-f       Force update CircleCI context even if unchanged"
                echo "  --skip-checklist Skip the pre-deployment checklist"
                echo "  --help,-h        Show this help message"
                echo ""
                echo "Environment Variables:"
                echo "  CIRCLECI_API_TOKEN  CircleCI API token for automation"
                echo "  CIRCLECI_ORG        GitHub organization name"
                echo "  CIRCLECI_PROJECT    Project name in CircleCI"
                echo "  CIRCLECI_CONTEXT    Context name for env vars (default: app-config)"
                exit 0
                ;;
            *)
                if [[ -z "$env_file" && ! "$arg" =~ ^- ]]; then
                    env_file="$arg"
                fi
                ;;
        esac
    done
    
    print_header "React App Production Deployment"
    
    # Get organization if not set
    if [[ -z "$CIRCLECI_ORG" ]]; then
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote_url" =~ github.com[:/]([^/]+)/ ]]; then
            CIRCLECI_ORG="${BASH_REMATCH[1]}"
            print_step "Detected GitHub organization: $CIRCLECI_ORG"
        else
            read -p "Enter GitHub organization/username: " CIRCLECI_ORG
        fi
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Show pre-deployment checklist
    if [[ "$skip_checklist" != "true" ]]; then
        show_deployment_checklist
    fi
    
    # Select and validate environment file
    env_file=$(select_env_file "$env_file")
    validate_env_file "$env_file"
    
    # Check git status and perform operations if needed
    if check_git_status; then
        perform_git_operations
    fi
    
    # Update CircleCI context variables
    update_circleci_context "$env_file" "$force_update"
    
    # Trigger CircleCI pipeline
    trigger_circleci_pipeline
    
    # Monitor deployment
    monitor_deployment
    
    # Show post-deployment information
    show_post_deployment_info "$env_file"
}

# Handle script interruption
trap 'echo -e "\n${RED}Deployment interrupted${NC}"; exit 1' INT TERM

# Run main function
main "$@"


