#!/bin/bash

# Deployment script for demo-gallery React application
# This script can be run directly on the server for manual deployments

set -e

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-yourusername}"
CONTAINER_NAME="${CONTAINER_NAME:-demo-gallery}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_PORT="${CONTAINER_PORT:-3001}"

# Environment variables for the application
VITE_API_URL="${VITE_API_URL:-http://localhost:8000}"
VITE_API_KEY="${VITE_API_KEY}"
VITE_AUTH_USERNAME="${VITE_AUTH_USERNAME}"
VITE_AUTH_PASSWORD="${VITE_AUTH_PASSWORD}"
VITE_ENVIRONMENT="${VITE_ENVIRONMENT:-production}"
VITE_DATADOG_APPLICATION_ID="${VITE_DATADOG_APPLICATION_ID}"
VITE_DATADOG_CLIENT_TOKEN="${VITE_DATADOG_CLIENT_TOKEN}"
VITE_DATADOG_SITE="${VITE_DATADOG_SITE:-datadoghq.com}"
VITE_DATADOG_SERVICE="${VITE_DATADOG_SERVICE:-demo-gallery}"
VITE_RELEASE="${VITE_RELEASE:-1.0.0}"

# Traefik configuration (optional)
TRAEFIK_HOST="${TRAEFIK_HOST:-demo-gallery.yourdomain.com}"
ENABLE_TRAEFIK="${ENABLE_TRAEFIK:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main deployment process
main() {
    log_info "Starting deployment of ${CONTAINER_NAME}..."
    log_info "Image: ${DOCKER_USERNAME}/${CONTAINER_NAME}:${IMAGE_TAG}"
    log_info "Port: ${CONTAINER_PORT}"
    log_info "Environment: ${VITE_ENVIRONMENT}"
    
    # Pull the latest image
    log_info "Pulling Docker image..."
    if ! docker pull "${DOCKER_USERNAME}/${CONTAINER_NAME}:${IMAGE_TAG}"; then
        log_error "Failed to pull Docker image"
        exit 1
    fi
    
    # Check if container exists and stop it
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "Stopping existing container..."
        docker stop "${CONTAINER_NAME}" || true
        docker rm "${CONTAINER_NAME}" || true
    fi
    
    # Prepare Docker run command
    DOCKER_CMD="docker run -d \
        --name ${CONTAINER_NAME} \
        --restart unless-stopped \
        -p ${CONTAINER_PORT}:80 \
        -e VITE_API_URL=\"${VITE_API_URL}\" \
        -e VITE_API_KEY=\"${VITE_API_KEY}\" \
        -e VITE_AUTH_USERNAME=\"${VITE_AUTH_USERNAME}\" \
        -e VITE_AUTH_PASSWORD=\"${VITE_AUTH_PASSWORD}\" \
        -e VITE_ENVIRONMENT=\"${VITE_ENVIRONMENT}\" \
        -e VITE_DATADOG_APPLICATION_ID=\"${VITE_DATADOG_APPLICATION_ID}\" \
        -e VITE_DATADOG_CLIENT_TOKEN=\"${VITE_DATADOG_CLIENT_TOKEN}\" \
        -e VITE_DATADOG_SITE=\"${VITE_DATADOG_SITE}\" \
        -e VITE_DATADOG_SERVICE=\"${VITE_DATADOG_SERVICE}\" \
        -e VITE_RELEASE=\"${VITE_RELEASE}\""
    
    # Add Traefik labels if enabled
    if [ "${ENABLE_TRAEFIK}" = "true" ]; then
        log_info "Configuring Traefik labels..."
        DOCKER_CMD="${DOCKER_CMD} \
            --label traefik.enable=true \
            --label traefik.http.routers.${CONTAINER_NAME}.rule=Host(\`${TRAEFIK_HOST}\`) \
            --label traefik.http.services.${CONTAINER_NAME}.loadbalancer.server.port=80"
        
        # Add HTTPS redirect if needed
        if [ "${TRAEFIK_HTTPS}" = "true" ]; then
            DOCKER_CMD="${DOCKER_CMD} \
                --label traefik.http.routers.${CONTAINER_NAME}.tls=true \
                --label traefik.http.routers.${CONTAINER_NAME}.tls.certresolver=letsencrypt"
        fi
    fi
    
    # Add Portainer labels
    DOCKER_CMD="${DOCKER_CMD} \
        --label com.portainer.accesscontrol.teams=developers \
        --label com.portainer.app=${CONTAINER_NAME}"
    
    # Complete the command with image name
    DOCKER_CMD="${DOCKER_CMD} ${DOCKER_USERNAME}/${CONTAINER_NAME}:${IMAGE_TAG}"
    
    # Run the container
    log_info "Starting new container..."
    eval ${DOCKER_CMD}
    
    # Wait for container to be healthy
    log_info "Waiting for container to be healthy..."
    HEALTH_CHECK_ATTEMPTS=30
    HEALTH_CHECK_DELAY=2
    
    for i in $(seq 1 $HEALTH_CHECK_ATTEMPTS); do
        if docker exec "${CONTAINER_NAME}" wget -q -O /dev/null http://127.0.0.1/health 2>/dev/null; then
            log_info "Container is healthy!"
            break
        fi
        
        if [ $i -eq $HEALTH_CHECK_ATTEMPTS ]; then
            log_error "Container failed to become healthy after $((HEALTH_CHECK_ATTEMPTS * HEALTH_CHECK_DELAY)) seconds"
            log_error "Container logs:"
            docker logs --tail 50 "${CONTAINER_NAME}"
            exit 1
        fi
        
        echo -n "."
        sleep $HEALTH_CHECK_DELAY
    done
    
    echo ""
    
    # Show container status
    log_info "Container status:"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Show access information
    echo ""
    log_info "Deployment complete!"
    log_info "Application is running on port ${CONTAINER_PORT}"
    
    if [ "${ENABLE_TRAEFIK}" = "true" ]; then
        log_info "Traefik URL: https://${TRAEFIK_HOST}"
    else
        log_info "Direct access: http://localhost:${CONTAINER_PORT}"
    fi
    
    # Optional: Clean up old images
    if [ "${CLEANUP_OLD_IMAGES}" = "true" ]; then
        log_info "Cleaning up old images..."
        docker image prune -f --filter "label!=keep"
    fi
}

# Show usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy the demo-gallery React application as a Docker container.

OPTIONS:
    -h, --help              Show this help message
    -t, --tag TAG          Docker image tag (default: latest)
    -p, --port PORT        Container port (default: 3001)
    -e, --env ENV          Environment (default: production)
    --traefik              Enable Traefik labels
    --cleanup              Clean up old Docker images after deployment
    
ENVIRONMENT VARIABLES:
    DOCKER_USERNAME         Docker Hub username
    CONTAINER_NAME          Container name (default: demo-gallery)
    VITE_API_URL           API URL for the application
    VITE_API_KEY           Optional API key for authentication
    VITE_AUTH_USERNAME     Basic Auth username (if Authelia supports it)
    VITE_AUTH_PASSWORD     Basic Auth password (if Authelia supports it)
    VITE_ENVIRONMENT       Environment name
    VITE_DATADOG_*         Datadog configuration
    TRAEFIK_HOST           Hostname for Traefik routing
    
EXAMPLES:
    # Deploy latest version
    ./deploy.sh
    
    # Deploy specific tag with Traefik
    ./deploy.sh --tag v1.2.3 --traefik
    
    # Deploy to development environment
    ./deploy.sh --env development --port 3002
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--port)
            CONTAINER_PORT="$2"
            shift 2
            ;;
        -e|--env)
            VITE_ENVIRONMENT="$2"
            shift 2
            ;;
        --traefik)
            ENABLE_TRAEFIK="true"
            shift
            ;;
        --cleanup)
            CLEANUP_OLD_IMAGES="true"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Run main deployment
main
