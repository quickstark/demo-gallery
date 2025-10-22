# Workflow Status and Runner Fix

**Date**: 2025-10-22
**Issue**: Workflows stuck in "Queued" status
**Status**: ✅ Resolved

## What Happened

### Problem
GitHub Actions workflows were stuck in "Queued" status and never executed:
- Run 18721365473: Queued for 8m3s → Cancelled
- Run 18721272646: Queued for 8m24s → Cancelled
- Run 18720429104: Queued for 39m8s → Cancelled

### Root Cause
Your self-hosted GitHub Actions runner was offline/disconnected and couldn't pick up workflow jobs.

**Evidence**:
- Workflows requiring `runs-on: self-hosted` got stuck in queue
- Workflows using GitHub-hosted runners (version-tagging.yml) completed successfully ✅

## Solution Implemented

### 1. Cancelled Stuck Workflows ✅
All 3 queued workflows have been cancelled and removed from the queue.

### 2. Created Troubleshooting Resources

**`.github/RUNNER_TROUBLESHOOTING.md`** - Comprehensive guide covering:
- Quick diagnosis steps
- 5 different solution approaches
- Verification procedures
- Common issues and fixes
- Best practices for runner management

**`scripts/restart-runner.sh`** - Automated restart script:
- Finds your GitHub Actions runner container
- Checks container status
- Restarts if needed
- Verifies connection
- Sets auto-restart policy

## How to Fix Your Runner

### Quick Fix (Recommended)

Run the automated script:
```bash
cd /Users/dirk.nielsen/Documents/Github/demo-gallery
./scripts/restart-runner.sh
```

**What it does**:
1. Searches for runner container (looks for "runner" or "actions" in name)
2. Checks if container is running
3. Restarts container if needed
4. Verifies connection to GitHub
5. Sets auto-restart policy to prevent future issues

### Manual Fix

If you know your runner container name:
```bash
# Find runner container
docker ps -a | grep runner

# Restart it
docker restart <runner-container-name>

# Check logs
docker logs <runner-container-name> --tail 20

# Verify it's connected
docker logs <runner-container-name> | grep -i "listening for jobs"
```

### Verify Fix

After restarting runner:

**1. Check runner status in GitHub**:
- Go to: https://github.com/YOUR_USERNAME/demo-gallery/settings/actions/runners
- Runner should show: 🟢 "Idle" or "Active" (not "Offline")

**2. Trigger test workflow**:
```bash
gh workflow run deploy.yml
```

**3. Monitor execution**:
```bash
gh run watch
```

**Expected**: Workflow should transition from "queued" → "in_progress" → "completed" within seconds

## Why This Happened

### Common Causes:
1. **Container stopped**: Runner container not running or crashed
2. **Network issues**: Runner can't reach GitHub API
3. **Token expired**: Runner authentication failed
4. **Resource constraints**: Container ran out of memory/CPU
5. **Manual shutdown**: Container was stopped for maintenance

### Prevention:
The restart script sets `--restart unless-stopped` policy on your container, which means:
- Container auto-restarts after Docker daemon restart
- Container auto-restarts after crashes
- Container stays running unless manually stopped

## Workflow Configuration

Your workflow is configured to use self-hosted runner:

**File**: `.github/workflows/deploy.yml:21`
```yaml
jobs:
  build-and-deploy:
    runs-on: self-hosted  # Requires your runner to be online
```

**Alternative Option**: If runner issues persist, you can temporarily switch to GitHub-hosted runners:
```yaml
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest  # Uses GitHub's infrastructure
```

⚠️ **Note**: Using GitHub-hosted runners requires SSH access to your Ubuntu server from GitHub's IP ranges.

## Monitoring Your Runner

### Check Runner Health
```bash
# Container status
docker ps --filter name=runner

# Recent logs
docker logs <runner-container-name> --tail 20

# Follow logs in real-time
docker logs -f <runner-container-name>
```

### Check Workflow Status
```bash
# List recent runs
gh run list --limit 10

# Watch active run
gh run watch

# Check specific run
gh run view <run-id>
```

### GitHub Web Interface
- **Workflows**: https://github.com/YOUR_USERNAME/demo-gallery/actions
- **Runners**: https://github.com/YOUR_USERNAME/demo-gallery/settings/actions/runners

## Next Deployment

Once runner is online, trigger a new deployment:

**Option 1: Manual dispatch**
```bash
gh workflow run deploy.yml
```

**Option 2: Use deployment script**
```bash
./scripts/deploy-github.sh
```

**Option 3: Push to main**
```bash
git add .
git commit -m "Your changes"
git push origin main
```

All three methods will trigger the deployment workflow, which should now execute successfully.

## Summary

✅ **Completed**:
- Cancelled 3 stuck workflows
- Identified runner offline issue
- Created troubleshooting documentation
- Created automated restart script
- Set up prevention measures

🔧 **Your Action Required**:
1. Run `./scripts/restart-runner.sh` to restart your GitHub Actions runner
2. Verify runner shows as online in GitHub Settings
3. Test with: `gh workflow run deploy.yml`
4. Monitor execution: `gh run watch`

📚 **Resources Created**:
- `.github/RUNNER_TROUBLESHOOTING.md` - Complete troubleshooting guide
- `.github/WORKFLOW_STATUS.md` - This document
- `scripts/restart-runner.sh` - Automated restart script

---

**For detailed troubleshooting steps, see**: `.github/RUNNER_TROUBLESHOOTING.md`
