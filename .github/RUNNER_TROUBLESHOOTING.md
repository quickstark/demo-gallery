# GitHub Actions Self-Hosted Runner Troubleshooting

**Issue**: Workflows stuck in "Queued" status and not executing
**Root Cause**: Self-hosted runner is offline or not connected to GitHub Actions

## Current Status

**Queued Workflows**:
- Run ID: 18721365473 (manual workflow_dispatch) - 6m47s in queue
- Run ID: 18721272646 (push trigger) - 7m6s in queue
- Run ID: 18720429104 (push trigger) - 37m50s in queue

**Working Workflows**:
- Version Tagging and Release (uses GitHub-hosted runners) ✅

## Quick Diagnosis

### Step 1: Check Runner Status
```bash
# Navigate to: Settings → Actions → Runners in your GitHub repository
# Or check via CLI:
gh api repos/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions/runners
```

**What to look for**:
- Runner status: Should show "online" (currently showing "offline")
- Last seen: Should be recent (if old, runner is disconnected)
- Labels: Should include "self-hosted" label

### Step 2: Locate Runner Container/Process

Your self-hosted runner is likely running in a Docker container (as mentioned in your context).

**Find the runner container**:
```bash
# List all containers
docker ps -a | grep runner

# Common runner container names
docker ps -a | grep -E "github-runner|actions-runner|runner"
```

**Check runner logs**:
```bash
# Replace with your actual container name
docker logs <runner-container-name> --tail 50
```

### Step 3: Check Runner Service Status

If runner is installed as a service on the host:
```bash
# Check if runner service exists
sudo systemctl status actions.runner.*

# Check runner processes
ps aux | grep Runner.Listener
```

## Solutions

### Solution 1: Restart Runner Container (Most Common)

```bash
# Find runner container
docker ps -a | grep runner

# Restart the container
docker restart <runner-container-name>

# Verify it's running
docker ps | grep runner

# Check logs for connection
docker logs <runner-container-name> --tail 20
```

**Expected log output**:
```
✓ Connected to GitHub
√ Runner successfully registered
√ Runner is listening for jobs
```

### Solution 2: Start Runner if Stopped

```bash
# If container is stopped
docker start <runner-container-name>

# Or if it's a service
sudo systemctl start actions.runner.*
```

### Solution 3: Check Runner Configuration

**Runner should be in your adjacent container** (per your setup notes).

**Verify container network**:
```bash
# Check if runner container can reach GitHub
docker exec <runner-container-name> curl -s https://api.github.com

# Check runner working directory
docker exec <runner-container-name> ls -la /home/runner/_work
```

### Solution 4: Re-register Runner (If Needed)

If runner shows as offline in GitHub and can't reconnect:

1. **Remove old runner**:
   - Go to: GitHub repo → Settings → Actions → Runners
   - Click on offline runner → Remove runner

2. **Get new registration token**:
   ```bash
   gh api repos/OWNER/REPO/actions/runners/registration-token | jq -r .token
   ```

3. **Re-register in container**:
   ```bash
   docker exec -it <runner-container-name> bash

   # Inside container
   ./config.sh remove --token <old-token>
   ./config.sh --url https://github.com/OWNER/REPO --token <new-token>
   ./run.sh
   ```

### Solution 5: Switch to GitHub-Hosted Runners (Temporary)

If you need immediate deployment while troubleshooting:

**Edit `.github/workflows/deploy.yml`**:
```yaml
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest  # Change from: self-hosted
```

**Important**: This requires:
- SSH access to your Ubuntu server from GitHub-hosted runners
- SSH keys stored in GitHub Secrets
- Server firewall allows GitHub Actions IP ranges

## Verification Steps

After fixing runner connectivity:

### 1. Verify Runner is Online
```bash
gh api repos/OWNER/REPO/actions/runners
```

Expected output:
```json
{
  "runners": [
    {
      "id": 123,
      "name": "your-runner-name",
      "status": "online",
      "busy": false,
      "labels": [{"name": "self-hosted"}, ...]
    }
  ]
}
```

### 2. Test with Manual Workflow
```bash
# Trigger manual workflow dispatch
gh workflow run deploy.yml
```

### 3. Monitor Workflow Execution
```bash
# Watch workflow status
gh run watch

# Or check runs list
gh run list --limit 3
```

**Expected**: Status changes from "queued" → "in_progress" → "completed"

## Cancel Stuck Workflows

**Option 1: Cancel via CLI**:
```bash
# Cancel specific run
gh run cancel 18721365473
gh run cancel 18721272646
gh run cancel 18720429104

# Or cancel all queued runs
gh run list --status queued --json databaseId -q '.[].databaseId' | xargs -I {} gh run cancel {}
```

**Option 2: Cancel via Web**:
- Go to Actions tab
- Click on queued workflow
- Click "Cancel workflow" button

## Common Issues

### Issue: Runner keeps going offline
**Causes**:
- Container restarts without auto-restart policy
- Network connectivity issues
- Token expiration
- Resource constraints (memory/CPU)

**Fix**:
```bash
# Ensure container auto-restarts
docker update --restart unless-stopped <runner-container-name>

# Check resource usage
docker stats <runner-container-name>
```

### Issue: Runner online but not picking up jobs
**Causes**:
- Label mismatch (workflow requires labels runner doesn't have)
- Runner busy with another job
- Runner in maintenance mode

**Fix**:
```bash
# Check runner labels match workflow requirements
gh api repos/OWNER/REPO/actions/runners

# Workflow requires: runs-on: self-hosted
# Runner must have: labels: ["self-hosted"]
```

### Issue: Runner authentication failed
**Causes**:
- Registration token expired
- Runner removed from repository

**Fix**:
Re-register runner with new token (see Solution 4)

## Best Practices

### 1. Container Auto-Restart
```bash
docker update --restart unless-stopped <runner-container-name>
```

### 2. Health Monitoring
Create a simple health check script:
```bash
#!/bin/bash
# /docker/appdata/demo-gallery/check-runner.sh

RUNNER_CONTAINER="<your-runner-container-name>"

if ! docker ps | grep -q $RUNNER_CONTAINER; then
    echo "❌ Runner container is not running"
    docker start $RUNNER_CONTAINER
fi

# Check if runner is connected
if docker logs $RUNNER_CONTAINER --tail 5 | grep -q "Listening for Jobs"; then
    echo "✅ Runner is healthy"
else
    echo "⚠️  Runner may be disconnected"
    docker restart $RUNNER_CONTAINER
fi
```

### 3. Logging
```bash
# Monitor runner logs
docker logs -f <runner-container-name>
```

## Quick Reference Commands

```bash
# Check runner status in GitHub
gh api repos/OWNER/REPO/actions/runners

# Find runner container
docker ps -a | grep runner

# Restart runner
docker restart <runner-container-name>

# Check runner logs
docker logs <runner-container-name> --tail 50

# Cancel queued workflows
gh run list --status queued --json databaseId -q '.[].databaseId' | xargs -I {} gh run cancel {}

# Trigger test workflow
gh workflow run deploy.yml

# Watch workflow progress
gh run watch
```

## Next Steps

1. **Immediate**: Cancel the 3 queued workflows (they won't execute)
2. **Fix Runner**: Restart runner container and verify it's online
3. **Test**: Trigger a new workflow run and confirm it executes
4. **Monitor**: Set up health checks to prevent future disconnections

## Need More Help?

**Check these files**:
- `.github/workflows/deploy.yml` - Workflow configuration (line 21: `runs-on: self-hosted`)
- `scripts/deploy-github.sh` - Deployment orchestration script
- `.github/workflows/README.md` - Workflow documentation

**Useful resources**:
- [GitHub Self-Hosted Runners Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Troubleshooting Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/monitoring-and-troubleshooting-self-hosted-runners)
