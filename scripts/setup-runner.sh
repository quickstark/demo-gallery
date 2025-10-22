#!/bin/bash

# =============================================================================
# GitHub Actions Runner Setup Script
# =============================================================================
# This script sets up a self-hosted GitHub Actions runner in a Docker container
# for the demo-gallery project
#
# Prerequisites:
#   - Docker installed and running
#   - GitHub CLI (gh) installed and authenticated
#   - Sufficient permissions to manage runners in the repository
#
# Usage:
#   ./scripts/setup-runner.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "=========================================="
echo "GitHub Actions Runner Setup"
echo "=========================================="
echo ""

# Configuration
REPO="quickstark/demo-gallery"
RUNNER_NAME="demo-gallery-runner"
RUNNER_DIR="/docker/appdata/github-runner"
RUNNER_IMAGE="myoung34/github-runner:latest"

log_info "📋 Repository: $REPO"
log_info "🏷️  Runner Name: $RUNNER_NAME"
log_info "📁 Runner Directory: $RUNNER_DIR"
log_info "🐳 Docker Image: $RUNNER_IMAGE"
echo ""

# Check prerequisites
log_step "Checking prerequisites..."

# Check Docker - improved check that works with /usr/bin/docker
if command -v docker >/dev/null 2>&1 || [ -x /usr/bin/docker ]; then
    DOCKER_CMD=$(command -v docker 2>/dev/null || echo "/usr/bin/docker")
    log_info "✅ Docker found at: $DOCKER_CMD"
else
    log_error "Docker is not installed or not executable"
    log_info "Install Docker from: https://docs.docker.com/engine/install/ubuntu/"
    exit 1
fi

# Check if Docker daemon is accessible
if ! $DOCKER_CMD ps >/dev/null 2>&1; then
    log_error "Docker daemon is not running or not accessible"
    log_info "Try: sudo systemctl start docker"
    log_info "Or check permissions: sudo usermod -aG docker $USER"
    exit 1
fi

log_info "✅ Docker daemon is accessible"

# Check GitHub CLI
if command -v gh >/dev/null 2>&1 || [ -x /usr/bin/gh ]; then
    GH_CMD=$(command -v gh 2>/dev/null || echo "/usr/bin/gh")
    log_info "✅ GitHub CLI found at: $GH_CMD"
else
    log_error "GitHub CLI (gh) is not installed"
    log_info "Install from: https://cli.github.com/"
    log_info "Ubuntu: sudo apt install gh"
    exit 1
fi

# Check GitHub CLI authentication
if ! $GH_CMD auth status >/dev/null 2>&1; then
    log_error "GitHub CLI is not authenticated"
    log_info "Run: gh auth login"
    exit 1
fi

log_info "✅ GitHub CLI is authenticated"
echo ""

# Get registration token
log_step "Getting registration token from GitHub..."

REGISTRATION_TOKEN=$($GH_CMD api -X POST repos/$REPO/actions/runners/registration-token --jq '.token' 2>/dev/null)

if [ -z "$REGISTRATION_TOKEN" ]; then
    log_error "Failed to get registration token"
    log_info "Make sure you have admin access to the repository"
    log_info "Repository: https://github.com/$REPO"
    log_info "Try running: gh auth refresh -s admin:org"
    exit 1
fi

log_info "✅ Registration token obtained (valid for 1 hour)"
echo ""

# Create runner directory
log_step "Creating runner directory..."

if [ ! -d "$RUNNER_DIR" ]; then
    if mkdir -p "$RUNNER_DIR" 2>/dev/null; then
        log_info "✅ Directory created: $RUNNER_DIR"
    else
        log_error "Failed to create directory: $RUNNER_DIR"
        log_info "Try with sudo: sudo mkdir -p $RUNNER_DIR && sudo chown $USER:$USER $RUNNER_DIR"
        exit 1
    fi
else
    log_info "✅ Directory already exists: $RUNNER_DIR"
fi
echo ""

# Check for existing runner container
log_step "Checking for existing runner container..."

if $DOCKER_CMD ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${RUNNER_NAME}$"; then
    log_warn "Existing runner container found"
    log_info "Stopping and removing old container..."

    $DOCKER_CMD stop "$RUNNER_NAME" 2>/dev/null || true
    $DOCKER_CMD rm "$RUNNER_NAME" 2>/dev/null || true

    log_info "✅ Old container removed"
else
    log_info "No existing container found"
fi
echo ""

# Pull runner image
log_step "Pulling GitHub Actions runner Docker image..."

if $DOCKER_CMD pull "$RUNNER_IMAGE" 2>&1 | grep -q "Status: Image is up to date"; then
    log_info "✅ Runner image is up to date"
elif $DOCKER_CMD pull "$RUNNER_IMAGE" >/dev/null 2>&1; then
    log_info "✅ Runner image pulled"
else
    log_error "Failed to pull runner image"
    log_info "Image: $RUNNER_IMAGE"
    exit 1
fi
echo ""

# Run runner container
log_step "Starting runner container..."

if $DOCKER_CMD run -d \
  --name "$RUNNER_NAME" \
  --restart unless-stopped \
  -e REPO_URL="https://github.com/$REPO" \
  -e RUNNER_NAME="$RUNNER_NAME" \
  -e RUNNER_TOKEN="$REGISTRATION_TOKEN" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -e LABELS="self-hosted,Linux,X64" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$RUNNER_DIR:/tmp/github-runner" \
  "$RUNNER_IMAGE" >/dev/null 2>&1; then
    log_info "✅ Runner container started: $RUNNER_NAME"
else
    log_error "Failed to start runner container"
    log_info "Check Docker logs: docker logs $RUNNER_NAME"
    exit 1
fi
echo ""

# Wait for registration
log_step "Waiting for runner registration (this may take 10-15 seconds)..."
sleep 15
echo ""

# Verify registration
log_step "Verifying runner registration..."

RUNNER_INFO=$($GH_CMD api repos/$REPO/actions/runners 2>/dev/null || echo '{"total_count":0}')
RUNNER_COUNT=$(echo "$RUNNER_INFO" | grep -o '"total_count":[0-9]*' | grep -o '[0-9]*' || echo "0")

if [ "$RUNNER_COUNT" -gt 0 ]; then
    log_info "✅ Runner successfully registered!"
    echo ""
    log_info "Runner details:"

    # Parse runner info without relying on jq
    echo "$RUNNER_INFO" | grep -A 10 '"name"' | while IFS= read -r line; do
        if echo "$line" | grep -q '"name"'; then
            NAME=$(echo "$line" | sed 's/.*"name": *"\([^"]*\)".*/\1/')
            echo "  Name: $NAME"
        elif echo "$line" | grep -q '"status"'; then
            STATUS=$(echo "$line" | sed 's/.*"status": *"\([^"]*\)".*/\1/')
            echo "  Status: $STATUS"
        elif echo "$line" | grep -q '"busy"'; then
            BUSY=$(echo "$line" | sed 's/.*"busy": *\([^,]*\).*/\1/')
            echo "  Busy: $BUSY"
        fi
    done
    echo ""
else
    log_warn "Runner not visible in GitHub yet"
    log_info "This may take a few more seconds"
    log_info "Check logs with: docker logs $RUNNER_NAME --tail 50"
    echo ""
fi

# Check container status
log_step "Checking container status..."

CONTAINER_STATUS=$($DOCKER_CMD inspect --format='{{.State.Status}}' "$RUNNER_NAME" 2>/dev/null || echo "not found")

if [ "$CONTAINER_STATUS" = "running" ]; then
    log_info "✅ Container is running"
else
    log_error "Container is not running (status: $CONTAINER_STATUS)"
    log_info "Check logs: docker logs $RUNNER_NAME"
    exit 1
fi
echo ""

# Show recent logs
log_step "Recent container logs:"
echo "---"
$DOCKER_CMD logs "$RUNNER_NAME" --tail 20 2>&1 || log_warn "Could not retrieve logs"
echo "---"
echo ""

echo "=========================================="
log_info "✅ Setup Complete!"
echo "=========================================="
echo ""

log_info "📋 Next Steps:"
echo ""
echo "  1️⃣  Verify runner status:"
echo "     gh api repos/$REPO/actions/runners"
echo ""
echo "  2️⃣  Check runner in GitHub UI:"
echo "     https://github.com/$REPO/settings/actions/runners"
echo ""
echo "  3️⃣  Trigger a test workflow:"
echo "     gh workflow run deploy.yml"
echo ""
echo "  4️⃣  Watch workflow execution:"
echo "     gh run watch"
echo ""
echo "  5️⃣  Monitor runner logs:"
echo "     docker logs -f $RUNNER_NAME"
echo ""

log_info "🔧 Useful Commands:"
echo ""
echo "  • Restart runner:    docker restart $RUNNER_NAME"
echo "  • Stop runner:       docker stop $RUNNER_NAME"
echo "  • View logs:         docker logs $RUNNER_NAME --tail 50"
echo "  • Container status:  docker ps --filter name=$RUNNER_NAME"
echo "  • Remove runner:     docker rm -f $RUNNER_NAME"
echo ""

log_info "📚 Documentation:"
echo "  • .github/RUNNER_DIAGNOSIS.md - Complete troubleshooting guide"
echo "  • .github/RUNNER_TROUBLESHOOTING.md - Runner maintenance"
echo ""

echo "=========================================="
