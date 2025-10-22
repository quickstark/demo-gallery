# Port 8080 Conflict - Resolution Guide

**Date**: 2025-10-22
**Issue**: `Bind for 0.0.0.0:8080 failed: port is already allocated`
**Status**: ✅ Solution Ready

## 🎯 Root Cause

**Good News**: Docker Hub authentication is working! Image pulled successfully ✅

**New Issue**: Port 8080 is already in use on your Ubuntu server

```
docker: Error response from daemon: failed to set up container networking:
driver failed programming external connectivity on endpoint demo-gallery:
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Why This Happens**:
- Deploy script stops containers by NAME ("demo-gallery")
- But another container (different name) or application is using port 8080
- Common culprits: old containers, FastAPI project, nginx, other services

## 🔍 Immediate Diagnostic

**On your Ubuntu server, run these commands**:

### Find What's Using Port 8080

```bash
# Option 1: Find container using port 8080
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" | grep 8080

# Option 2: Find process using port 8080 (non-Docker)
sudo lsof -i :8080

# Option 3: Find all containers with their ports
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

**Example output**:
```
CONTAINER ID   NAMES              PORTS
abc123def456   fastapi-app        0.0.0.0:8080->8000/tcp
```
☝️ This shows `fastapi-app` is using port 8080

## ✅ Quick Fix Options

### Option 1: Stop Whatever's On Port 8080 (Quickest)

**If it's a Docker container**:
```bash
# Find the container
CONTAINER_ON_8080=$(docker ps --format "{{.Names}}" --filter "publish=8080")

echo "Container using port 8080: $CONTAINER_ON_8080"

# Stop it
docker stop $CONTAINER_ON_8080

# Or stop ALL containers on port 8080
docker ps --filter "publish=8080" -q | xargs docker stop

# Then re-run your workflow
gh workflow run deploy.yml
```

**If it's a non-Docker process**:
```bash
# Find the process ID
sudo lsof -i :8080 | grep LISTEN

# Example output:
# node    12345 user   23u  IPv4 123456      0t0  TCP *:8080 (LISTEN)
#         ^PID

# Kill it (replace 12345 with actual PID)
sudo kill -9 12345

# Then re-run your workflow
gh workflow run deploy.yml
```

### Option 2: Use a Different Port for Demo Gallery

**If port 8080 is reserved for another service** (like FastAPI):

I'll create a separate fix document for this - see below.

### Option 3: Update Workflow for Smarter Cleanup (BEST)

**Best long-term solution** - Update deploy.yml to automatically handle port conflicts.

I'll provide the updated workflow section below.

## 🛠️ Workflow Fix: Smart Port Cleanup

**Replace the deployment section** (lines 275-305 in deploy.yml):

```yaml
# Stop and remove existing containers
echo "Stopping existing container by name..."
docker stop demo-gallery 2>/dev/null || echo "No container named demo-gallery"
docker rm -f demo-gallery 2>/dev/null || echo "No container to remove"

# Stop any container using port 8080 (regardless of name)
echo "Checking for containers using port 8080..."
PORT_8080_CONTAINER=$(docker ps --filter "publish=8080" --format "{{.Names}}" | head -1)
if [ -n "$PORT_8080_CONTAINER" ]; then
  echo "⚠️  Found container using port 8080: $PORT_8080_CONTAINER"
  echo "Stopping it to free the port..."
  docker stop "$PORT_8080_CONTAINER"
  docker rm -f "$PORT_8080_CONTAINER"
  echo "✅ Port 8080 freed"
else
  echo "✅ Port 8080 is available"
fi

# Clean up old images to save space
echo "Cleaning up old images..."
docker image prune -f || true

# Pull the latest image (already pushed to Docker Hub)
echo "Pulling latest image from Docker Hub..."
docker pull ${{ secrets.DOCKERHUB_USER }}/demo-gallery:latest

# Run new container with production configuration
echo "Starting new container..."
docker run -d \
  --name demo-gallery \
  --restart unless-stopped \
  -p 8080:80 \
  --add-host=host.docker.internal:host-gateway \
  -e VITE_API_URL="${{ secrets.VITE_API_URL }}" \
  -e VITE_API_KEY="${{ secrets.VITE_API_KEY }}" \
  -e VITE_AUTH_USERNAME="${{ secrets.VITE_AUTH_USERNAME }}" \
  -e VITE_AUTH_PASSWORD="${{ secrets.VITE_AUTH_PASSWORD }}" \
  -e VITE_ENVIRONMENT="${{ secrets.VITE_ENVIRONMENT || 'production' }}" \
  -e VITE_DATADOG_APPLICATION_ID="${{ secrets.VITE_DATADOG_APPLICATION_ID }}" \
  -e VITE_DATADOG_CLIENT_TOKEN="${{ secrets.VITE_DATADOG_CLIENT_TOKEN }}" \
  -e VITE_DATADOG_SITE="${{ secrets.VITE_DATADOG_SITE || 'datadoghq.com' }}" \
  -e VITE_DATADOG_SERVICE="${{ secrets.VITE_DATADOG_SERVICE || 'demo-gallery' }}" \
  -e VITE_RELEASE="${{ steps.version.outputs.version }}" \
  ${{ secrets.DOCKERHUB_USER }}/demo-gallery:latest
```

**What this does differently**:
1. ✅ Stops container by name (demo-gallery)
2. ✅ **Also stops ANY container using port 8080** (new!)
3. ✅ Provides clear logging about what's being stopped
4. ✅ Frees port 8080 before starting new container

## 📋 Manual Fix (Immediate)

**Right now, on your Ubuntu server**:

```bash
# Step 1: Find what's on port 8080
docker ps --filter "publish=8080"

# Step 2: Stop it (replace CONTAINER_NAME with actual name from step 1)
docker stop CONTAINER_NAME

# Step 3: Re-run GitHub workflow
gh workflow run deploy.yml

# Step 4: Watch it succeed
gh run watch
```

## 🎯 Most Likely Scenario

**If you're running FastAPI on the same server**:

Your FastAPI project is probably using port 8080. Options:

**A. Move FastAPI to different port** (e.g., 8000):
```bash
# Stop FastAPI container
docker stop fastapi-app

# Restart on port 8000
docker run -d \
  --name fastapi-app \
  -p 8000:8000 \
  your-fastapi-image

# Demo gallery can now use 8080
```

**B. Move Demo Gallery to different port** (e.g., 8081):
- See "Change Port Configuration" section below

**C. Use port-based cleanup** (recommended):
- Apply the workflow fix above
- It will automatically stop FastAPI when deploying gallery
- (Only do this if FastAPI and Gallery shouldn't run simultaneously)

## 🔄 Change Port Configuration (If Needed)

**If you want demo-gallery on port 8081 instead**:

### Update deploy.yml

Find and replace these lines:

**Line 293** - Container port mapping:
```yaml
# Before:
-p 8080:80 \

# After:
-p 8081:80 \
```

**Lines 317-328** - Health check URLs:
```yaml
# Before:
curl -f http://localhost:8080/health
curl -f http://localhost:8080/

# After:
curl -f http://localhost:8081/health
curl -f http://localhost:8081/
```

**Commit and push**:
```bash
git add .github/workflows/deploy.yml
git commit -m "fix: Change demo-gallery port to 8081"
git push origin main
```

**Access application**:
```
http://your-ubuntu-server:8081
```

## 📊 Verification After Fix

**After applying any fix, verify**:

```bash
# Check container is running
docker ps | grep demo-gallery

# Expected output:
# demo-gallery   Up 2 minutes   0.0.0.0:8080->80/tcp

# Test application
curl http://localhost:8080/

# Should return HTML content

# Check from external browser
# http://YOUR_SERVER_IP:8080
```

## 🎉 Success Criteria

You'll know it's fixed when:

✅ **Workflow logs show**:
```
Stopping existing container...
Checking for containers using port 8080...
✅ Port 8080 is available
Starting new container...
9f74a99c83c5... (container ID)
✅ Health check passed - Gallery is running on port 8080
```

✅ **Docker ps shows**:
```
NAMES           PORTS
demo-gallery    0.0.0.0:8080->80/tcp
```

✅ **Application accessible**:
```
http://your-server-ip:8080
```

## 🔗 Related Files

- **Workflow**: `.github/workflows/deploy.yml` (line 293 for port mapping)
- **Cleanup Script**: `scripts/deploy-github.sh`
- **Port Troubleshooting**: This document

---

## 📝 Summary

**Problem**: Port 8080 already allocated
**Root Cause**: Another container/process using the port
**Quick Fix**: Stop container using port 8080, re-run workflow
**Long-term Fix**: Update deploy.yml with port-based cleanup
**Alternative**: Change demo-gallery to use different port (8081)

**Immediate Action**: Run diagnostic commands above to see what's on port 8080, then apply appropriate fix.

---

**Last Updated**: 2025-10-22
**Status**: Solution Ready - Choose Quick Fix or Workflow Update
