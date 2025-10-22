#!/bin/bash

# =============================================================================
# GitHub Secrets Setup Script for React Gallery
# =============================================================================
# This script uploads environment variables to GitHub Secrets for the CI/CD pipeline
#
# Usage: ./scripts/setup-github-secrets.sh [env-file]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEFAULT_ENV_FILE=".env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Helper functions
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Parse arguments
ENV_FILE="${1:-$DEFAULT_ENV_FILE}"

if [[ ! -f "$PROJECT_ROOT/$ENV_FILE" ]]; then
    print_error "Environment file '$ENV_FILE' not found in project root"
    exit 1
fi

cd "$PROJECT_ROOT"

print_step "Reading environment variables from $ENV_FILE..."

# Counter for uploaded secrets
SUCCESS_COUNT=0
ERROR_COUNT=0

# Read and upload secrets
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # Parse key=value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        KEY="${BASH_REMATCH[1]}"
        VALUE="${BASH_REMATCH[2]}"

        # Remove quotes from value
        VALUE=$(echo "$VALUE" | sed 's/^["'\'']\|["'\'']$//g')

        # Skip if value is empty
        if [[ -z "$VALUE" ]]; then
            print_warning "Skipping $KEY (empty value)"
            continue
        fi

        # Upload to GitHub Secrets
        print_step "Uploading secret: $KEY"
        if echo "$VALUE" | gh secret set "$KEY"; then
            print_success "✓ Uploaded $KEY"
            ((SUCCESS_COUNT++))
        else
            print_error "✗ Failed to upload $KEY"
            ((ERROR_COUNT++))
        fi
    fi
done < "$ENV_FILE"

echo
echo "================================"
echo "Upload Summary:"
echo "  Success: $SUCCESS_COUNT"
echo "  Errors: $ERROR_COUNT"
echo "================================"
echo

if [[ $ERROR_COUNT -gt 0 ]]; then
    print_warning "Some secrets failed to upload. Check the errors above."
    exit 1
else
    print_success "All secrets uploaded successfully!"
fi
