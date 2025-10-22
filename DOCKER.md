# Docker Deployment Guide

Complete guide for building, running, and deploying the demo-gallery application using Docker.

## Table of Contents
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Local Development](#local-development)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Using Docker Compose (Recommended for Local Testing)

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

Application will be available at: http://localhost:3001

### Using Docker CLI

```bash
# Build the image
docker build -t demo-gallery:latest .

# Run the container
docker run -d \
  --name demo-gallery \
  -p 3001:80 \
  -e VITE_API_URL="http://localhost:8000" \
  -e VITE_ENVIRONMENT="development" \
  demo-gallery:latest

# Check health
curl http://localhost:3001/health
```

## Architecture

### Multi-Stage Build

The Dockerfile uses a multi-stage build approach:

1. **Builder Stage** (node:20-alpine)
   - Installs dependencies with Yarn
   - Builds the Vite application
   - Creates optimized production bundle

2. **Runtime Stage** (nginx:alpine)
   - Serves static files with Nginx
   - Injects runtime environment variables
   - Implements health checks and security headers

### Runtime Environment Injection

Environment variables are injected at **runtime** (not build time) via the `entrypoint.sh` script:

- Build-time: Uses placeholder values (e.g., `__VITE_API_URL__`)
- Runtime: Replaces placeholders with actual environment variables
- Benefit: Single image works across multiple environments

### Key Features

- **Multi-stage build**: Optimized image size (~50MB final)
- **Runtime config**: Environment variables injected at container start
- **Health checks**: Built-in health endpoint at `/health`
- **Security headers**: X-Frame-Options, CSP, XSS protection
- **SPA routing**: Nginx configured for React Router
- **Caching**: Optimized cache headers for static assets
- **Compression**: Gzip enabled for all text content

## Local Development

### Prerequisites

- Docker Desktop installed and running
- `.env` file created (copy from `.env.example`)

### Configuration

Edit `.env` file with your local settings:

```bash
# API Configuration
VITE_API_URL=http://localhost:8000
VITE_ENVIRONMENT=development

# Datadog (optional for local)
VITE_DATADOG_APPLICATION_ID=
VITE_DATADOG_CLIENT_TOKEN=
```

### Development Workflow

```bash
# Start container
docker-compose up -d

# Watch logs
docker-compose logs -f demo-gallery

# Rebuild after code changes
docker-compose up -d --build

# Access container shell
docker exec -it demo-gallery sh

# Stop and remove
docker-compose down

# Stop and remove with volumes
docker-compose down -v
```

### Useful Commands

```bash
# View container status
docker-compose ps

# View resource usage
docker stats demo-gallery

# Inspect container
docker inspect demo-gallery

# View runtime config
curl http://localhost:3001/config.json
```

## Production Deployment

### Manual Deployment

The `deploy.sh` script provides automated deployment:

```bash
# Set required environment variables
export DOCKER_USERNAME="yourusername"
export VITE_API_URL="https://api.yourdomain.com"
export VITE_DATADOG_APPLICATION_ID="your-dd-app-id"
export VITE_DATADOG_CLIENT_TOKEN="your-dd-token"

# Deploy latest version
./deploy.sh

# Deploy specific version with Traefik
./deploy.sh --tag v1.2.3 --traefik

# Deploy to custom port
./deploy.sh --port 8080 --env production
```

### CI/CD Deployment

The project includes CircleCI configuration for automated deployments:

1. **Build**: Builds Docker image on every commit
2. **Push**: Pushes to Docker Hub with version tags
3. **Deploy**: Automatically deploys to configured servers

#### Required CircleCI Contexts

- `docker-hub`: Docker Hub credentials
- `tailscale`: Tailscale OAuth credentials
- `deployment`: SSH keys and server config
- `app-config`: Runtime environment variables

### Building for Production

```bash
# Build production image
docker build -t yourusername/demo-gallery:latest .

# Tag with version
docker tag yourusername/demo-gallery:latest yourusername/demo-gallery:v1.0.0

# Push to registry
docker push yourusername/demo-gallery:latest
docker push yourusername/demo-gallery:v1.0.0
```

### Running in Production

```bash
docker run -d \
  --name demo-gallery \
  --restart unless-stopped \
  -p 3001:80 \
  -e VITE_API_URL="https://api.yourdomain.com" \
  -e VITE_ENVIRONMENT="production" \
  -e VITE_DATADOG_APPLICATION_ID="your-app-id" \
  -e VITE_DATADOG_CLIENT_TOKEN="your-token" \
  -e VITE_DATADOG_SITE="datadoghq.com" \
  -e VITE_DATADOG_SERVICE="demo-gallery" \
  -e VITE_RELEASE="1.0.0" \
  yourusername/demo-gallery:latest
```

### Production with Traefik

```bash
docker run -d \
  --name demo-gallery \
  --restart unless-stopped \
  --label traefik.enable=true \
  --label traefik.http.routers.demo-gallery.rule=Host(\`gallery.yourdomain.com\`) \
  --label traefik.http.services.demo-gallery.loadbalancer.server.port=80 \
  --label traefik.http.routers.demo-gallery.tls=true \
  --label traefik.http.routers.demo-gallery.tls.certresolver=letsencrypt \
  -e VITE_API_URL="https://api.yourdomain.com" \
  -e VITE_ENVIRONMENT="production" \
  yourusername/demo-gallery:latest
```

## Configuration

### Environment Variables

All configuration is done via environment variables passed at runtime:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_API_URL` | Yes | `http://localhost:8000` | Backend API URL |
| `VITE_API_KEY` | No | - | Optional API authentication key |
| `VITE_AUTH_USERNAME` | No | - | Basic auth username (if needed) |
| `VITE_AUTH_PASSWORD` | No | - | Basic auth password (if needed) |
| `VITE_ENVIRONMENT` | Yes | `production` | Environment name |
| `VITE_DATADOG_APPLICATION_ID` | No | - | Datadog RUM application ID |
| `VITE_DATADOG_CLIENT_TOKEN` | No | - | Datadog RUM client token |
| `VITE_DATADOG_SITE` | No | `datadoghq.com` | Datadog site |
| `VITE_DATADOG_SERVICE` | No | `demo-gallery` | Service name for Datadog |
| `VITE_RELEASE` | No | `1.0.0` | Release version |

### Nginx Configuration

The nginx configuration (`docker/nginx.conf`) includes:

- SPA routing: All routes serve `index.html`
- Cache headers: 30 days for assets, 1 hour for HTML
- Security headers: X-Frame-Options, CSP, XSS protection
- CORS: Enabled for API calls
- Gzip: Enabled for all text content
- Health endpoint: `/health` for container health checks

### Health Checks

Built-in health check runs every 30 seconds:

```bash
# Manual health check
curl http://localhost:3001/health

# Docker health status
docker ps --filter "name=demo-gallery"
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs demo-gallery

# Check if port is in use
lsof -i :3001

# Inspect container
docker inspect demo-gallery
```

### Environment Variables Not Applied

```bash
# Verify entrypoint script ran
docker logs demo-gallery | grep "Environment variable injection"

# Check config file
curl http://localhost:3001/config.json

# Manually check env vars in container
docker exec demo-gallery env | grep VITE
```

### Build Failures

```bash
# Clean Docker cache
docker builder prune -a

# Rebuild from scratch
docker-compose build --no-cache

# Check Dockerfile syntax
docker build --check .
```

### Performance Issues

```bash
# Check resource usage
docker stats demo-gallery

# Increase worker processes (edit nginx.conf)
# worker_processes auto;

# Check nginx logs
docker exec demo-gallery cat /var/log/nginx/access.log
docker exec demo-gallery cat /var/log/nginx/error.log
```

### Network Issues

```bash
# Verify container network
docker network inspect demo-gallery_demo-gallery-network

# Check container connectivity
docker exec demo-gallery ping -c 3 google.com

# Test API connectivity from container
docker exec demo-gallery wget -O- http://your-api-url/health
```

## Security Considerations

1. **Secrets Management**: Never commit secrets to `.env` or Dockerfile
2. **Image Scanning**: Regularly scan images for vulnerabilities
3. **Base Image Updates**: Keep node and nginx images updated
4. **Least Privilege**: Run as non-root user (nginx runs as nginx user)
5. **Network Isolation**: Use Docker networks to isolate containers

## Best Practices

1. **Version Tags**: Always tag images with versions, not just `latest`
2. **Health Checks**: Monitor container health in production
3. **Resource Limits**: Set CPU/memory limits in production
4. **Log Management**: Use log drivers for centralized logging
5. **Backup Strategy**: Backup environment configurations

## Additional Resources

- [Dockerfile](./Dockerfile)
- [docker-compose.yml](./docker-compose.yml)
- [Nginx Configuration](./docker/nginx.conf)
- [Entrypoint Script](./docker/entrypoint.sh)
- [Deployment Script](./deploy.sh)
- [Environment Example](./.env.example)
