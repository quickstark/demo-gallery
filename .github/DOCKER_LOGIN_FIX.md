# Docker Login Error Fix

**Date**: 2025-10-22
**Error**: `Error saving credentials: open /root/.docker/config.json...: read-only file system`
**Cause**: Docker config directory mounted as read-only in runner container
**Fix**: Remove read-only Docker config mount from compose file

## 🎯 Root Cause

The compose file had:
```yaml
volumes:
  - ${HOME}/.docker:/root/.docker:ro  # ← :ro = read-only
```

When workflow runs `docker login`, it tries to save credentials to `/root/.docker/config.json` but fails because the mount is read-only.

## ✅ Fix Applied

**Removed the read-only Docker config mount**:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  # REMOVED: - ${HOME}/.docker:/root/.docker:ro
  - /docker/appdata/quickstarkdemo-runner/work:/tmp/runner/work
  - /docker/appdata/quickstarkdemo-runner/tools:/opt/hostedtoolcache
  - /docker/appdata/quickstarkdemo-runner/npm-cache:/root/.npm
  - /docker/appdata/quickstarkdemo-runner/pip-cache:/root/.cache/pip
```

**Why this works**:
- Runner doesn't need host's Docker config
- Workflow provides Docker Hub credentials via secrets
- `docker login` can now create its own config inside container

## 📋 Apply Fix on Ubuntu Server

**SSH to your Ubuntu server** and run:

```bash
# 1. Stop current runner
docker-compose -f docker-compose.runner-fixed.yml down

# 2. Pull latest compose file changes
cd /path/to/demo-gallery
git pull origin main

# Or if you haven't committed, copy the fixed compose file

# 3. Restart runner with updated config
docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d

# 4. Verify runner started
docker ps | grep quickstarkdemo-runner
docker logs quickstarkdemo-runner --tail 20
```

**Expected logs**:
```
✓ Connected to GitHub
✓ Runner successfully registered
✓ Runner is listening for jobs
```

## 🧪 Test Fix

**Trigger a new workflow run**:

```bash
# From Mac or Ubuntu server
gh workflow run deploy.yml --repo quickstarkdemo/demo-gallery

# Watch it run
gh run watch --repo quickstarkdemo/demo-gallery
```

**Expected**: Build Docker Image step should succeed with:
```
Building Docker image for React Gallery...
Login Succeeded
Building with git metadata for Datadog...
Successfully tagged quickstark/demo-gallery:latest
Successfully tagged quickstark/demo-gallery:2.0.1-abc123
```

## ⚠️ Alternative: Keep Mount But Make It Writable

If you WANT to share host Docker config (not needed), remove `:ro`:

```yaml
volumes:
  - ${HOME}/.docker:/root/.docker  # Writable, no :ro
```

**But recommended**: Remove the mount entirely (current fix).

## 🔍 Why Mount Isn't Needed

**Docker Hub credentials flow**:
1. Workflow has secrets: `DOCKERHUB_USER` and `DOCKERHUB_TOKEN`
2. Workflow runs: `docker login --username $USER --password-stdin`
3. Docker saves credentials to `/root/.docker/config.json` (inside container)
4. Subsequent `docker push` commands use those credentials
5. When container stops, credentials are discarded (secure!)

**No host config needed** - workflow provides credentials fresh each time.

---

**Last Updated**: 2025-10-22
**Issue**: Docker login fails with read-only file system
**Fix**: Remove Docker config volume mount from compose
**Apply**: Restart runner on Ubuntu server
