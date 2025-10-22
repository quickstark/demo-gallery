# React Gallery - Deployment Guide

This guide covers deploying the React Gallery application using GitHub Actions to an Ubuntu server with Docker.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Required GitHub Secrets](#required-github-secrets)
- [Version Management](#version-management)
- [Deployment Methods](#deployment-methods)
- [Manual Deployment](#manual-deployment)
- [Automated Deployment](#automated-deployment)
- [Troubleshooting](#troubleshooting)
- [Monitoring](#monitoring)

---

## Overview

The React Gallery uses a GitHub Actions workflow to:
1. Build a Docker image with semantic versioning
2. Push the image to Docker Hub
3. Deploy the container to your Ubuntu server
4. Integrate with Datadog for monitoring and CD visibility
5. Run SonarQube code quality analysis

**Deployment Architecture**:
- **GitHub Actions**: Self-hosted runner in containerized environment
- **Docker Hub**: Image registry for versioned builds
- **Ubuntu Server**: Target deployment environment
- **Port Mapping**: Application runs on port 8080 (host) → 80 (container)
- **Container Name**: `demo-gallery`

---

## Prerequisites

### Local Development Machine
- **Git**: Version control
- **GitHub CLI** (`gh`): For secrets management
  ```bash
  # Install GitHub CLI
  # macOS
  brew install gh

  # Ubuntu/Debian
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install gh

  # Authenticate
  gh auth login
  ```

### Docker Hub Account
- Create account at https://hub.docker.com
- Generate access token:
  1. Go to Account Settings → Security → Access Tokens
  2. Click "New Access Token"
  3. Name: `github-actions`
  4. Permissions: Read, Write, Delete
  5. Save the token securely

### Ubuntu Server
- Docker installed and running
- GitHub Actions self-hosted runner configured
- Port 8080 available for the application

### Optional Integrations
- **Datadog**: For monitoring and CD visibility (optional)
  - Sign up at https://www.datadoghq.com
  - Get API key and Application key

- **SonarQube**: For code quality analysis (optional)
  - Self-hosted or SonarCloud account
  - Generate authentication token

---

## Required GitHub Secrets

### Docker Hub (Required)
```yaml
DOCKERHUB_USER: your-dockerhub-username
DOCKERHUB_TOKEN: your-dockerhub-access-token
```

### Application Environment Variables (Required)
All environment variables prefixed with `VITE_` are injected at runtime:

```yaml
VITE_API_URL: https://your-api-domain.com
VITE_API_KEY: your-api-key
VITE_AUTH_USERNAME: your-username
VITE_AUTH_PASSWORD: your-password
VITE_ENVIRONMENT: production
```

### Datadog Integration (Optional)
```yaml
DD_API_KEY: your-datadog-api-key
DD_APP_KEY: your-datadog-app-key
DD_ENV: production
VITE_DATADOG_APPLICATION_ID: your-datadog-rum-app-id
VITE_DATADOG_CLIENT_TOKEN: your-datadog-rum-client-token
VITE_DATADOG_SITE: datadoghq.com
VITE_DATADOG_SERVICE: demo-gallery
```

### SonarQube Integration (Optional)
```yaml
SONAR_TOKEN: your-sonarqube-token
SONAR_HOST_URL: https://your-sonarqube-instance.com
```

---

## Deployment Methods

### Method 1: Automated Script (Recommended)

The `deploy-github.sh` script handles the entire deployment workflow:

```bash
# Navigate to project root
cd /path/to/demo-gallery

# Run deployment script
./scripts/deploy-github.sh

# Or specify custom env file
./scripts/deploy-github.sh .env.production

# Force update all secrets even if unchanged
./scripts/deploy-github.sh --force
```

**What the script does**:
1. ✅ Checks prerequisites (git, gh CLI, authentication)
2. 📂 Selects and validates environment file
3. 📊 Displays environment variable summary
4. 🔄 Checks git status for uncommitted changes
5. 💬 Prompts for commit if changes detected
6. 🔐 Compares local env with GitHub secrets
7. ⬆️ Uploads only new/changed secrets
8. 🔍 Monitors GitHub Actions workflow execution
9. 📋 Displays deployment status and links

**Interactive prompts**:
- Environment file selection
- Commit message for changes
- Confirmation for git push
- Secret update confirmation
- Workflow monitoring option

### Method 2: Manual Deployment

#### Step 1: Upload Secrets to GitHub

Create a `.env` file with your production values:

```bash
# Copy from example
cp .env.example .env

# Edit with your values
nano .env
```

Upload secrets using the setup script:

```bash
./scripts/setup-github-secrets.sh .env
```

Or manually using GitHub CLI:

```bash
# Docker Hub credentials
gh secret set DOCKERHUB_USER --body "your-username"
gh secret set DOCKERHUB_TOKEN --body "your-token"

# Application environment variables
gh secret set VITE_API_URL --body "https://api.example.com"
gh secret set VITE_API_KEY --body "your-api-key"
# ... add all required secrets
```

#### Step 2: Commit and Push Changes

```bash
# Check status
git status

# Add changes
git add .

# Commit with descriptive message
git commit -m "feat: Add new feature for gallery"

# Push to trigger deployment
git push origin main
```

#### Step 3: Monitor Deployment

```bash
# Watch workflow execution
gh run watch

# Or view in browser
gh run list
gh run view <run-id>
```

#### Step 4: Verify Deployment

```bash
# Check container status on server
ssh your-server
docker ps | grep demo-gallery

# Check application health
curl http://your-server:8080/health

# View container logs
docker logs demo-gallery --tail 50
```

---

## Manual Deployment

### Local Testing Before Deployment

Test the Docker image locally before pushing:

```bash
# Build image
docker build -t demo-gallery:test .

# Run container with env file
docker run -d \
  --name demo-gallery-test \
  -p 8080:80 \
  --env-file .env \
  demo-gallery:test

# Test the application
curl http://localhost:8080/health
curl http://localhost:8080/

# View logs
docker logs demo-gallery-test

# Clean up
docker stop demo-gallery-test
docker rm demo-gallery-test
```

### Direct Server Deployment (Without GitHub Actions)

If you need to deploy directly to the server:

```bash
# SSH to server
ssh your-server

# Pull latest image
docker pull your-dockerhub-username/demo-gallery:latest

# Stop existing container
docker stop demo-gallery
docker rm demo-gallery

# Run new container
docker run -d \
  --name demo-gallery \
  --restart unless-stopped \
  -p 8080:80 \
  -e VITE_API_URL="https://api.example.com" \
  -e VITE_API_KEY="your-key" \
  -e VITE_ENVIRONMENT="production" \
  your-dockerhub-username/demo-gallery:latest

# Verify deployment
docker ps | grep demo-gallery
curl http://localhost:8080/health
```

---

## Automated Deployment

### GitHub Actions Workflow

The workflow automatically triggers on:
- **Push to main branch**: Automatic deployment
- **Manual trigger**: Via GitHub Actions UI with options

#### Workflow Steps

1. **Checkout Code**: Full history for versioning
2. **Install Datadog CI**: For monitoring integration
3. **Read VERSION**: Creates semantic version (1.0.0-abc1234)
4. **SonarQube Scan**: Code quality analysis
5. **System Information**: Verify runner environment
6. **Docker Build**: Multi-stage build with git metadata
7. **Docker Push**: Push to Docker Hub with tags:
   - `latest`
   - `1.0.0-abc1234` (version-commit)
   - `abc1234` (commit SHA)
8. **Deploy**: Pull and run on Ubuntu server
9. **Health Check**: Verify application is running
10. **Datadog Marking**: Record deployment in CD visibility

#### Manual Trigger Options

Trigger manually from GitHub Actions UI:

- **skip_build**: Skip Docker build (use existing image)
- **skip_deploy**: Build only, don't deploy (for testing)

### Versioning Strategy

**VERSION File**: Base semantic version (e.g., `1.0.0`)

**Git SHA Tagging**: Automatic append of short commit SHA
- Version file: `1.0.0`
- Git commit: `abc1234567...`
- Final version: `1.0.0-abc1234`

**Updating Version**:

```bash
# Update VERSION file for new release
echo "1.1.0" > VERSION

# Commit version bump
git add VERSION
git commit -m "chore: Bump version to 1.1.0"
git push origin main
```

---

## Troubleshooting

### Deployment Script Issues

#### "GitHub CLI (gh) is not installed"
```bash
# Install GitHub CLI (see Prerequisites)
brew install gh  # macOS
# or
sudo apt install gh  # Ubuntu
```

#### "Not authenticated with GitHub CLI"
```bash
gh auth login
# Follow prompts to authenticate
```

#### "Environment file not found"
```bash
# Create from example
cp .env.example .env

# Edit with your values
nano .env
```

#### "Some secrets failed to upload"
- Check GitHub CLI authentication: `gh auth status`
- Verify repository permissions
- Check for special characters in secret values (quote them)

### GitHub Actions Issues

#### "Docker daemon not accessible"
**Cause**: Self-hosted runner can't access Docker socket

**Fix**: Ensure runner container has Docker socket mounted:
```yaml
# In runner container configuration
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

#### "Login to Docker Hub failed"
**Cause**: Invalid Docker Hub credentials

**Fix**: Verify secrets are correct:
```bash
# Check secret exists
gh secret list

# Update secret
gh secret set DOCKERHUB_TOKEN
# Paste token and press Enter
```

#### "datadog-ci not available"
**Cause**: Datadog CI installation failed

**Impact**: Non-critical, deployment continues without Datadog marking

**Fix**: Check `/tmp/datadog-ci.sh` exists on runner or install npm globally

#### "SonarQube scan failed"
**Cause**: SonarQube credentials or project configuration issue

**Impact**: Non-critical, deployment continues without code analysis

**Fix**: Verify `SONAR_TOKEN` and `SONAR_HOST_URL` secrets

### Container Issues

#### "Container not starting"
```bash
# Check container logs
docker logs demo-gallery

# Common issues:
# 1. Port already in use
sudo lsof -i :8080
docker stop <conflicting-container>

# 2. Missing environment variables
docker inspect demo-gallery | grep -A 20 Env
```

#### "Health check failing"
```bash
# Check nginx is running
docker exec demo-gallery ps aux | grep nginx

# Check nginx logs
docker exec demo-gallery cat /var/log/nginx/error.log

# Test health endpoint
curl -v http://localhost:8080/health
```

#### "Application not loading"
```bash
# Check browser console for errors
# Common issues:

# 1. CORS errors - check API_URL configuration
# 2. Missing environment variables
docker exec demo-gallery env | grep VITE

# 3. Nginx configuration issue
docker exec demo-gallery cat /etc/nginx/conf.d/default.conf
```

### Rollback Procedure

If deployment fails and you need to rollback:

```bash
# Method 1: Rollback to previous version tag
docker pull your-username/demo-gallery:1.0.0-previous-sha
docker stop demo-gallery
docker rm demo-gallery
docker run -d \
  --name demo-gallery \
  --restart unless-stopped \
  -p 8080:80 \
  --env-file .env \
  your-username/demo-gallery:1.0.0-previous-sha

# Method 2: Git revert and redeploy
git revert HEAD
git push origin main
# Wait for automatic redeployment
```

---

## Monitoring

### Application Health

**Health Endpoint**: `http://your-server:8080/health`
- Returns `200 OK` when healthy
- Checked every 30 seconds by Docker

**Manual Health Check**:
```bash
curl -f http://your-server:8080/health && echo "Healthy" || echo "Unhealthy"
```

### Container Monitoring

```bash
# Container status
docker ps --filter "name=demo-gallery"

# Resource usage
docker stats demo-gallery --no-stream

# Recent logs
docker logs demo-gallery --tail 100 --follow

# Container details
docker inspect demo-gallery
```

### GitHub Actions Monitoring

**Workflow Runs**:
- View: https://github.com/YOUR_USERNAME/demo-gallery/actions
- CLI: `gh run list`
- Watch: `gh run watch`

**Workflow Status**:
```bash
# List recent runs
gh run list --limit 10

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### Datadog Monitoring (If Enabled)

**Deployment Tracking**:
- CD Visibility: https://app.datadoghq.com/ci/deployments
- RUM Deployments: https://app.datadoghq.com/rum/deployments

**Application Monitoring**:
- RUM Dashboard: https://app.datadoghq.com/rum/explorer
- Service metrics, errors, and user sessions

**SonarQube Metrics in Datadog**:
- Bugs, vulnerabilities, code smells
- Code coverage percentage
- Quality gate status

### Logs and Debugging

**Application Logs**:
```bash
# View live logs
docker logs demo-gallery --follow

# Last 100 lines
docker logs demo-gallery --tail 100

# Logs since timestamp
docker logs demo-gallery --since 2024-01-01T00:00:00

# Save logs to file
docker logs demo-gallery > gallery-logs.txt
```

**Nginx Access Logs**:
```bash
docker exec demo-gallery tail -f /var/log/nginx/access.log
```

**Nginx Error Logs**:
```bash
docker exec demo-gallery tail -f /var/log/nginx/error.log
```

---

## Security Best Practices

### Secrets Management
- ✅ Never commit `.env` files to git
- ✅ Use GitHub Secrets for sensitive data
- ✅ Rotate Docker Hub tokens periodically
- ✅ Use separate tokens for different environments
- ✅ Limit token permissions to minimum required

### Container Security
- ✅ Run as non-root user (nginx user in container)
- ✅ Use official base images (nginx:alpine)
- ✅ Keep base images updated
- ✅ Scan images for vulnerabilities
- ✅ Implement security headers (configured in nginx.conf)

### Network Security
- ✅ Use HTTPS in production (reverse proxy with SSL)
- ✅ Configure firewall rules for port 8080
- ✅ Implement rate limiting at reverse proxy
- ✅ Use environment-specific API endpoints
- ✅ Validate CORS configuration

---

## Environment-Specific Configurations

### Development
```bash
VITE_ENVIRONMENT=development
VITE_API_URL=http://localhost:8000
```

### Staging
```bash
VITE_ENVIRONMENT=staging
VITE_API_URL=https://api-staging.example.com
```

### Production
```bash
VITE_ENVIRONMENT=production
VITE_API_URL=https://api.example.com
```

---

## Performance Optimization

### Image Size
- Current: ~50MB (multi-stage build)
- nginx:alpine base for minimal footprint
- Only production dependencies included

### Caching Strategy
- Static assets: 1 year cache (immutable)
- HTML: No cache (always fresh)
- Gzip compression enabled

### Build Optimization
```bash
# Analyze bundle size
npm run build -- --mode production

# Check for large dependencies
npx vite-bundle-visualizer
```

---

## Support and Resources

### Documentation
- **Docker Setup**: See `DOCKER.md`
- **Development**: See `README.md`
- **Environment Variables**: See `.env.example`

### GitHub Actions
- **Workflow File**: `.github/workflows/deploy.yml`
- **Deployment Script**: `scripts/deploy-github.sh`
- **Secrets Script**: `scripts/setup-github-secrets.sh`

### External Resources
- GitHub Actions Docs: https://docs.github.com/en/actions
- Docker Hub: https://hub.docker.com
- Datadog CI: https://docs.datadoghq.com/continuous_integration/
- SonarQube: https://docs.sonarqube.org/

---

## Quick Reference

### Common Commands
```bash
# Deploy with script
./scripts/deploy-github.sh

# Upload secrets only
./scripts/setup-github-secrets.sh .env

# Watch deployment
gh run watch

# Check container health
docker ps | grep demo-gallery
curl http://localhost:8080/health

# View logs
docker logs demo-gallery --tail 50

# Restart container
docker restart demo-gallery

# Update version
echo "1.1.0" > VERSION
git add VERSION && git commit -m "chore: Bump version"
git push origin main
```

### Port Reference
- **Local Development**: 3001 (Docker Compose)
- **Production**: 8080 (host) → 80 (container)
- **Container Internal**: 80 (nginx)

### Important Paths
- **Application**: `http://your-server:8080`
- **Health Check**: `http://your-server:8080/health`
- **Docker Hub**: `https://hub.docker.com/r/YOUR_USERNAME/demo-gallery`
- **GitHub Actions**: `https://github.com/YOUR_USERNAME/demo-gallery/actions`
