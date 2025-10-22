#!/bin/bash

# Build Custom Runner Image with Node.js and datadog-ci pre-installed
# This eliminates the need to install tools in every workflow run

set -e

echo "=========================================="
echo "Building Custom GitHub Runner Image"
echo "=========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found!"
    echo "Please install Docker first"
    exit 1
fi

# Configuration
IMAGE_NAME="quickstarkdemo/github-runner"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Image: $FULL_IMAGE"
echo ""

# Build the image
echo "📦 Building custom runner image..."
echo "This will install:"
echo "  - Base: myoung34/github-runner:latest"
echo "  - Node.js 20 LTS"
echo "  - npm"
echo "  - @datadog/datadog-ci"
echo ""

docker build -f Dockerfile.runner -t "$FULL_IMAGE" .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "Image: $FULL_IMAGE"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi

# Test the image
echo "🧪 Testing image..."
echo ""

echo "Checking Node.js..."
docker run --rm "$FULL_IMAGE" node --version

echo "Checking npm..."
docker run --rm "$FULL_IMAGE" npm --version

echo "Checking datadog-ci..."
docker run --rm "$FULL_IMAGE" datadog-ci version

echo ""
echo "✅ All tools verified!"
echo ""

# Ask if user wants to push to registry
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "Option 1: Use Locally (No push needed)"
echo "  Update docker-compose.runner-fixed.yml:"
echo "    image: $FULL_IMAGE"
echo ""
echo "Option 2: Push to Docker Hub (Recommended for remote server)"
echo "  docker login"
echo "  docker push $FULL_IMAGE"
echo ""
echo "  Then update docker-compose.runner-fixed.yml on server:"
echo "    image: $FULL_IMAGE"
echo ""

read -p "Push to Docker Hub now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing to Docker Hub..."
    echo ""

    # Check if logged in
    if ! docker info 2>/dev/null | grep -q "Username:"; then
        echo "Please log in to Docker Hub:"
        docker login
    fi

    docker push "$FULL_IMAGE"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Pushed successfully!"
        echo ""
        echo "Image available at: https://hub.docker.com/r/$IMAGE_NAME"
        echo ""
        echo "On your Ubuntu server:"
        echo "  1. Update docker-compose.runner-fixed.yml"
        echo "     Change: image: myoung34/github-runner:latest"
        echo "     To:     image: $FULL_IMAGE"
        echo ""
        echo "  2. Pull and restart:"
        echo "     docker-compose -f docker-compose.runner-fixed.yml pull"
        echo "     docker-compose -f docker-compose.runner-fixed.yml up -d --force-recreate"
    else
        echo ""
        echo "❌ Push failed!"
        exit 1
    fi
else
    echo ""
    echo "Skipped push."
    echo ""
    echo "To use locally, update docker-compose.runner-fixed.yml:"
    echo "  image: $FULL_IMAGE"
fi

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
