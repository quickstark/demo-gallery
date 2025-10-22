#!/bin/bash

# =============================================================================
# CircleCI Context Setup Script
# =============================================================================
# This script helps set up CircleCI contexts with environment variables
# from your .env file
#
# Usage: ./scripts/setup-circleci.sh [env-file]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ENV_FILE="${1:-.env}"
CIRCLECI_ORG="${CIRCLECI_ORG:-}"
CIRCLECI_PROJECT="${CIRCLECI_PROJECT:-demo-gallery}"

# Context names
CONTEXTS=(
    "docker-hub"
    "tailscale"
    "deployment"
    "app-config"
    "app-config-dev"
    "deployment-dev"
)

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check for CircleCI API token
    if [[ -z "$CIRCLECI_API_TOKEN" ]]; then
        print_error "CIRCLECI_API_TOKEN not set"
        echo
        echo "To get your API token:"
        echo "1. Go to: https://app.circleci.com/settings/user/tokens"
        echo "2. Click 'Create New Token'"
        echo "3. Give it a name (e.g., 'CLI Access')"
        echo "4. Copy the token"
        echo
        read -sp "Enter CircleCI API token: " token
        echo
        if [[ -n "$token" ]]; then
            export CIRCLECI_API_TOKEN="$token"
            print_success "API token set"
        else
            print_error "API token is required"
            exit 1
        fi
    fi
    
    # Get organization if not set
    if [[ -z "$CIRCLECI_ORG" ]]; then
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote_url" =~ github.com[:/]([^/]+)/ ]]; then
            CIRCLECI_ORG="${BASH_REMATCH[1]}"
            print_success "Detected GitHub organization: $CIRCLECI_ORG"
        else
            read -p "Enter GitHub organization/username: " CIRCLECI_ORG
        fi
    fi
    
    # Check if env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    print_success "Prerequisites checked"
    echo
}

create_context() {
    local context_name="$1"
    
    print_step "Creating context: $context_name"
    
    # Check if context exists
    local response=$(curl -s -X GET \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        "https://circleci.com/api/v2/context?owner-slug=github/${CIRCLECI_ORG}&page-token=")
    
    if echo "$response" | grep -q "\"name\":\"${context_name}\""; then
        print_success "Context already exists: $context_name"
        return 0
    fi
    
    # Create new context
    response=$(curl -s -X POST \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${context_name}\", \"owner\": {\"slug\": \"github/${CIRCLECI_ORG}\", \"type\": \"organization\"}}" \
        "https://circleci.com/api/v2/context")
    
    if echo "$response" | grep -q "\"id\""; then
        print_success "Context created: $context_name"
    else
        print_warning "Could not create context: $context_name"
        echo "  You may need to create it manually in CircleCI"
    fi
}

get_context_id() {
    local context_name="$1"
    
    local response=$(curl -s -X GET \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        "https://circleci.com/api/v2/context?owner-slug=github/${CIRCLECI_ORG}")
    
    echo "$response" | grep -B1 "\"name\":\"${context_name}\"" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1
}

setup_docker_hub_context() {
    print_header "Setting up Docker Hub Context"
    
    local context_id=$(get_context_id "docker-hub")
    if [[ -z "$context_id" ]]; then
        create_context "docker-hub"
        context_id=$(get_context_id "docker-hub")
    fi
    
    if [[ -z "$context_id" ]]; then
        print_error "Could not get context ID for docker-hub"
        return
    fi
    
    echo "Enter Docker Hub credentials:"
    read -p "Docker Hub username: " docker_username
    read -sp "Docker Hub access token (not password): " docker_password
    echo
    
    # Set DOCKER_USERNAME
    curl -s -X PUT \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"value\": \"${docker_username}\"}" \
        "https://circleci.com/api/v2/context/${context_id}/environment-variable/DOCKER_USERNAME" >/dev/null
    
    # Set DOCKER_PASSWORD
    curl -s -X PUT \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"value\": \"${docker_password}\"}" \
        "https://circleci.com/api/v2/context/${context_id}/environment-variable/DOCKER_PASSWORD" >/dev/null
    
    print_success "Docker Hub context configured"
    echo
}

setup_tailscale_context() {
    print_header "Setting up Tailscale Context"
    
    local context_id=$(get_context_id "tailscale")
    if [[ -z "$context_id" ]]; then
        create_context "tailscale"
        context_id=$(get_context_id "tailscale")
    fi
    
    if [[ -z "$context_id" ]]; then
        print_error "Could not get context ID for tailscale"
        return
    fi
    
    echo "Enter Tailscale OAuth credentials:"
    echo "Get these from: https://login.tailscale.com/admin/settings/oauth"
    read -p "OAuth Client ID: " client_id
    read -sp "OAuth Client Secret: " client_secret
    echo
    
    # Set TAILSCALE_OAUTH_CLIENT_ID
    curl -s -X PUT \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"value\": \"${client_id}\"}" \
        "https://circleci.com/api/v2/context/${context_id}/environment-variable/TAILSCALE_OAUTH_CLIENT_ID" >/dev/null
    
    # Set TAILSCALE_OAUTH_CLIENT_SECRET
    curl -s -X PUT \
        -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"value\": \"${client_secret}\"}" \
        "https://circleci.com/api/v2/context/${context_id}/environment-variable/TAILSCALE_OAUTH_CLIENT_SECRET" >/dev/null
    
    print_success "Tailscale context configured"
    echo
}

setup_deployment_context() {
    print_header "Setting up Deployment Context"
    
    local context_id=$(get_context_id "deployment")
    if [[ -z "$context_id" ]]; then
        create_context "deployment"
        context_id=$(get_context_id "deployment")
    fi
    
    if [[ -z "$context_id" ]]; then
        print_error "Could not get context ID for deployment"
        return
    fi
    
    echo "Enter deployment configuration:"
    read -p "Tailscale hostname/IP of your server: " deploy_host
    read -p "SSH username: " deploy_user
    read -p "Container name [demo-gallery]: " container_name
    container_name="${container_name:-demo-gallery}"
    read -p "Container port [3001]: " container_port
    container_port="${container_port:-3001}"
    read -p "Traefik hostname (optional): " traefik_host
    
    echo
    echo "SSH Key Setup:"
    echo "1. Generate key on server: ssh-keygen -t rsa -b 4096 -f ~/.ssh/circleci_deploy"
    echo "2. Add to authorized_keys: cat ~/.ssh/circleci_deploy.pub >> ~/.ssh/authorized_keys"
    echo "3. Copy private key: cat ~/.ssh/circleci_deploy | base64"
    echo
    read -sp "Enter base64-encoded private key: " ssh_key
    echo
    
    # Set all deployment variables
    local vars=(
        "DEPLOY_HOST:$deploy_host"
        "DEPLOY_USER:$deploy_user"
        "SSH_PRIVATE_KEY:$ssh_key"
        "CONTAINER_NAME:$container_name"
        "CONTAINER_PORT:$container_port"
    )
    
    if [[ -n "$traefik_host" ]]; then
        vars+=("TRAEFIK_HOST:$traefik_host")
    fi
    
    for var in "${vars[@]}"; do
        IFS=':' read -r key value <<< "$var"
        curl -s -X PUT \
            -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"value\": \"${value}\"}" \
            "https://circleci.com/api/v2/context/${context_id}/environment-variable/${key}" >/dev/null
    done
    
    print_success "Deployment context configured"
    echo
}

setup_app_config_context() {
    local context_name="${1:-app-config}"
    local env_file="${2:-$ENV_FILE}"
    
    print_header "Setting up $context_name Context"
    
    local context_id=$(get_context_id "$context_name")
    if [[ -z "$context_id" ]]; then
        create_context "$context_name"
        context_id=$(get_context_id "$context_name")
    fi
    
    if [[ -z "$context_id" ]]; then
        print_error "Could not get context ID for $context_name"
        return
    fi
    
    print_step "Uploading environment variables from $env_file"
    
    local count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes
            value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
            
            # Upload to CircleCI
            if curl -s -X PUT \
                -H "Circle-Token: ${CIRCLECI_API_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"value\": \"${value}\"}" \
                "https://circleci.com/api/v2/context/${context_id}/environment-variable/${key}" >/dev/null 2>&1; then
                ((count++))
                echo -e "  ${GREEN}✓${NC} $key"
            else
                echo -e "  ${RED}✗${NC} $key"
            fi
        fi
    done < "$env_file"
    
    print_success "Uploaded $count environment variables to $context_name"
    echo
}

show_summary() {
    print_header "CircleCI Setup Summary"
    
    echo -e "${CYAN}Contexts Created/Updated:${NC}"
    for context in "${CONTEXTS[@]}"; do
        if get_context_id "$context" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $context"
        else
            echo -e "  ${YELLOW}⚠${NC} $context (may need manual setup)"
        fi
    done
    echo
    
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Verify contexts at:"
    echo "   https://app.circleci.com/settings/organization/github/${CIRCLECI_ORG}/contexts"
    echo
    echo "2. Connect your GitHub repository to CircleCI:"
    echo "   https://app.circleci.com/projects/project-dashboard/github/${CIRCLECI_ORG}"
    echo
    echo "3. Run deployment:"
    echo "   ./scripts/deploy.sh"
    echo
}

interactive_setup() {
    print_header "CircleCI Interactive Setup"
    
    echo "This wizard will help you set up CircleCI contexts."
    echo
    
    # Docker Hub
    if read -p "Set up Docker Hub context? [y/N]: " -n 1 -r; then
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_docker_hub_context
        fi
    fi
    echo
    
    # Tailscale
    if read -p "Set up Tailscale context? [y/N]: " -n 1 -r; then
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_tailscale_context
        fi
    fi
    echo
    
    # Deployment
    if read -p "Set up Deployment context? [y/N]: " -n 1 -r; then
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_deployment_context
        fi
    fi
    echo
    
    # App Config
    if read -p "Set up App Config context from $ENV_FILE? [y/N]: " -n 1 -r; then
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_app_config_context "app-config" "$ENV_FILE"
        fi
    fi
    echo
}

main() {
    check_prerequisites
    
    if [[ "$1" == "--interactive" || "$1" == "-i" ]]; then
        interactive_setup
    elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: $0 [options] [env-file]"
        echo
        echo "Options:"
        echo "  --interactive, -i   Run interactive setup wizard"
        echo "  --help, -h         Show this help message"
        echo
        echo "Environment Variables:"
        echo "  CIRCLECI_API_TOKEN  Your CircleCI API token (required)"
        echo "  CIRCLECI_ORG       GitHub organization/username"
        echo
        exit 0
    else
        # Automated setup from env file
        setup_app_config_context "app-config" "$ENV_FILE"
    fi
    
    show_summary
}

# Handle interruption
trap 'echo -e "\n${RED}Setup interrupted${NC}"; exit 1' INT TERM

main "$@"


