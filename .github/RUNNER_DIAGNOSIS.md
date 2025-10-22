# GitHub Actions Runner Diagnosis

**Date**: 2025-10-22
**Issue**: Workflows queued indefinitely, runner not picking up jobs
**Status**: 🔴 **ROOT CAUSE IDENTIFIED**

## 🎯 Root Cause

**NO RUNNERS ARE REGISTERED** with the `quickstark/demo-gallery` repository.

### Evidence

```bash
gh api repos/quickstark/demo-gallery/actions/runners
```

**Output**:
```json
{
  "total_count": 0,
  "runners": []
}
```

**Meaning**: GitHub Actions cannot find ANY self-hosted runners registered to this repository.

### Why Workflows Are Queued

Your workflow requires:
```yaml
jobs:
  build-and-deploy:
    runs-on: self-hosted  # line 21 of deploy.yml
```

**What GitHub is doing**:
1. Workflow triggered (push to main or manual dispatch)
2. GitHub looks for runners with label `self-hosted`
3. **Finds ZERO runners** → job stays in queue forever
4. Message: "Requested labels: self-hosted... Waiting for a runner to pick up this job..."

## 🔍 Diagnosis Summary

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Runners registered | ≥1 runner | 0 runners | ❌ FAIL |
| Runner status | online | N/A (no runners) | ❌ FAIL |
| Runner labels | "self-hosted" | N/A (no runners) | ❌ FAIL |
| Workflow requirements | `runs-on: self-hosted` | ✅ Correct | ✅ PASS |

**Conclusion**: The workflow is correct, but NO runner is registered to execute it.

## 🤔 Why This Happened

### Possible Scenarios

**Scenario 1: Runner Never Set Up**
- You configured workflows but haven't set up the self-hosted runner yet
- The runner container was never created or started

**Scenario 2: Runner Was Removed**
- Runner was previously registered but got removed from GitHub
- Manual removal or automatic cleanup after being offline too long

**Scenario 3: Runner Registration Expired**
- Runner's authentication token expired
- Runner needs to be re-registered

**Scenario 4: Wrong Repository**
- Runner is registered to a different repository
- Runner is registered at organization level, not repo level

## 🔧 Solution: Set Up Self-Hosted Runner

### Option 1: Check if Runner Container Exists

```bash
# Find any existing runner containers
docker ps -a | grep -E "runner|actions"

# If found, check logs
docker logs <container-name> --tail 50

# If running but not registered, it may need re-registration
```

### Option 2: Set Up New Self-Hosted Runner

#### Step 1: Get Runner Registration Token

Go to GitHub:
```
https://github.com/quickstark/demo-gallery/settings/actions/runners/new
```

Or via CLI:
```bash
gh api -X POST repos/quickstark/demo-gallery/actions/runners/registration-token
```

This will give you:
- Download URL for the runner application
- Registration token (valid for 1 hour)
- Configuration instructions

#### Step 2: Choose Runner Setup Method

**Method A: Docker Container (Recommended)**

Create a Docker container for your runner:

```bash
# Create runner directory
mkdir -p /docker/appdata/demo-gallery-runner
cd /docker/appdata/demo-gallery-runner

# Pull GitHub Actions runner image
docker pull myoung34/github-runner:latest

# Get registration token from GitHub
REGISTRATION_TOKEN="<token from step 1>"

# Run runner container
docker run -d \
  --name demo-gallery-runner \
  --restart unless-stopped \
  -e REPO_URL="https://github.com/quickstark/demo-gallery" \
  -e RUNNER_NAME="demo-gallery-runner" \
  -e RUNNER_TOKEN="$REGISTRATION_TOKEN" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -e LABELS="self-hosted,Linux,X64" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /docker/appdata/demo-gallery-runner:/tmp/github-runner \
  myoung34/github-runner:latest
```

**Important**: Mount Docker socket so runner can build/push Docker images.

**Method B: Native Installation on Ubuntu Server**

```bash
# SSH to your Ubuntu server
ssh user@your-server

# Create runner directory
mkdir actions-runner && cd actions-runner

# Download runner (get URL from GitHub)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure (use token from Step 1)
./config.sh --url https://github.com/quickstark/demo-gallery --token <REGISTRATION_TOKEN>

# Install and start as service
sudo ./svc.sh install
sudo ./svc.sh start
```

**Method C: Existing Container (If you have one)**

If you mentioned the runner is in an "adjacent container":

```bash
# Find your existing runner container
docker ps -a | grep runner

# Check its logs
docker logs <runner-container-name> --tail 50

# If it's running but not registered, exec into it
docker exec -it <runner-container-name> bash

# Inside container, check registration
cd /actions-runner  # or wherever runner is installed
./config.sh --check

# If not registered, remove old registration
./config.sh remove --token <OLD_TOKEN>

# Re-register with new token
./config.sh --url https://github.com/quickstark/demo-gallery --token <NEW_TOKEN>

# Start runner
./run.sh &
```

#### Step 3: Verify Runner Registration

```bash
# Check via GitHub CLI
gh api repos/quickstark/demo-gallery/actions/runners

# Should see:
# {
#   "total_count": 1,
#   "runners": [
#     {
#       "id": 123,
#       "name": "demo-gallery-runner",
#       "status": "online",
#       "busy": false,
#       "labels": [
#         {"name": "self-hosted"},
#         {"name": "Linux"},
#         {"name": "X64"}
#       ]
#     }
#   ]
# }
```

Or check in GitHub UI:
```
https://github.com/quickstark/demo-gallery/settings/actions/runners
```

You should see:
- 🟢 **1 runner** registered
- Status: **Idle** or **Active** (not Offline)
- Labels: **self-hosted**, Linux, X64

#### Step 4: Test Workflow

```bash
# Trigger workflow manually
gh workflow run deploy.yml

# Watch it execute (should start immediately)
gh run watch

# Check status
gh run list --limit 3
```

**Expected**: Workflow transitions from "queued" → "in_progress" → "completed" within seconds.

## 🏗️ Recommended Runner Setup

For your demo-gallery project, I recommend **Docker container method**:

### Why Docker Container?

1. **Isolation**: Runner isolated from host system
2. **Docker Access**: Can build/push Docker images (your workflow needs this)
3. **Easy Restart**: `docker restart demo-gallery-runner`
4. **Portable**: Can move to different hosts easily
5. **Resource Control**: Docker resource limits
6. **Auto-Restart**: `--restart unless-stopped` policy

### Complete Setup Script

```bash
#!/bin/bash
# setup-runner.sh - Set up GitHub Actions runner for demo-gallery

set -e

echo "=========================================="
echo "GitHub Actions Runner Setup"
echo "=========================================="
echo ""

# Configuration
REPO="quickstark/demo-gallery"
RUNNER_NAME="demo-gallery-runner"
RUNNER_DIR="/docker/appdata/demo-gallery-runner"

echo "📋 Repository: $REPO"
echo "🏷️  Runner Name: $RUNNER_NAME"
echo "📁 Runner Directory: $RUNNER_DIR"
echo ""

# Get registration token
echo "🔑 Getting registration token from GitHub..."
REGISTRATION_TOKEN=$(gh api -X POST repos/$REPO/actions/runners/registration-token --jq '.token')

if [ -z "$REGISTRATION_TOKEN" ]; then
    echo "❌ Failed to get registration token"
    echo "Make sure you have gh CLI installed and authenticated"
    exit 1
fi

echo "✅ Registration token obtained"
echo ""

# Create runner directory
echo "📁 Creating runner directory..."
mkdir -p "$RUNNER_DIR"
echo "✅ Directory created: $RUNNER_DIR"
echo ""

# Stop and remove existing runner container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^${RUNNER_NAME}$"; then
    echo "⚠️  Existing runner container found, removing..."
    docker stop "$RUNNER_NAME" 2>/dev/null || true
    docker rm "$RUNNER_NAME" 2>/dev/null || true
    echo "✅ Old container removed"
    echo ""
fi

# Run runner container
echo "🚀 Starting runner container..."
docker run -d \
  --name "$RUNNER_NAME" \
  --restart unless-stopped \
  -e REPO_URL="https://github.com/$REPO" \
  -e RUNNER_NAME="$RUNNER_NAME" \
  -e RUNNER_TOKEN="$REGISTRATION_TOKEN" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -e LABELS="self-hosted,Linux,X64" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$RUNNER_DIR:/tmp/github-runner" \
  myoung34/github-runner:latest

echo "✅ Runner container started"
echo ""

# Wait for registration
echo "⏳ Waiting for runner registration..."
sleep 10

# Verify registration
echo "🔍 Verifying registration..."
RUNNER_COUNT=$(gh api repos/$REPO/actions/runners --jq '.total_count')

if [ "$RUNNER_COUNT" -gt 0 ]; then
    echo "✅ Runner successfully registered!"
    echo ""
    echo "Runner details:"
    gh api repos/$REPO/actions/runners --jq '.runners[] | {name, status, busy, labels: [.labels[].name]}'
    echo ""
    echo "=========================================="
    echo "Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Check runner status: gh api repos/$REPO/actions/runners"
    echo "2. Trigger workflow: gh workflow run deploy.yml"
    echo "3. Watch execution: gh run watch"
    echo ""
else
    echo "⚠️  Runner not visible yet, check logs:"
    echo "   docker logs $RUNNER_NAME --tail 50"
    echo ""
fi
```

Save this as `scripts/setup-runner.sh`, make it executable:

```bash
chmod +x scripts/setup-runner.sh
```

Then run it:

```bash
./scripts/setup-runner.sh
```

## 📋 Post-Setup Checklist

After setting up the runner:

- [ ] **Verify runner registered**: `gh api repos/quickstark/demo-gallery/actions/runners`
- [ ] **Check runner status**: Should show "online" and "idle"
- [ ] **Verify labels**: Should include "self-hosted"
- [ ] **Test workflow**: `gh workflow run deploy.yml`
- [ ] **Watch execution**: `gh run watch`
- [ ] **Verify immediate start**: Job should start within seconds, not stay queued
- [ ] **Check container logs**: `docker logs demo-gallery-runner --tail 50`
- [ ] **Verify auto-restart**: `docker inspect demo-gallery-runner | grep RestartPolicy`

## 🚨 Common Issues After Setup

### Issue: Runner shows offline immediately

**Cause**: Container can't reach GitHub API
**Fix**: Check network connectivity, firewall rules

### Issue: Runner connects but jobs still queued

**Cause**: Label mismatch (runner has wrong labels)
**Fix**: Ensure runner has "self-hosted" label exactly

### Issue: Docker commands fail in workflow

**Cause**: Docker socket not mounted
**Fix**: Add `-v /var/run/docker.sock:/var/run/docker.sock`

### Issue: Permission denied for Docker socket

**Cause**: Runner user doesn't have Docker permissions
**Fix**: Add runner user to docker group or run container with proper permissions

## 📊 Expected Final State

Once runner is set up correctly:

**GitHub Runners Page**:
```
Runners (1)
  Name: demo-gallery-runner
  Status: 🟢 Idle (or Active)
  Labels: self-hosted, Linux, X64
  Version: 2.311.0
```

**Workflow Behavior**:
```
Trigger workflow → Job starts immediately (within 5 seconds)
No more "Waiting for a runner to pick up this job..."
```

**Container Status**:
```bash
docker ps --filter name=demo-gallery-runner
# demo-gallery-runner   Up 5 minutes   ...
```

## 🔗 Useful Resources

**GitHub Actions Documentation**:
- [Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Adding self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners)
- [Monitoring self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/monitoring-and-troubleshooting-self-hosted-runners)

**Docker Runner Image**:
- [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner)

**GitHub CLI**:
- [gh CLI documentation](https://cli.github.com/manual/)

## 📝 Summary

**Problem**: Workflows queued indefinitely
**Root Cause**: NO self-hosted runner registered to repository
**Solution**: Set up and register a self-hosted runner
**Recommended Method**: Docker container with runner image
**Expected Time**: 10-15 minutes to set up
**Result**: Workflows execute immediately after runner registration

---

**Next Action Required**: Set up self-hosted runner using one of the methods above.
