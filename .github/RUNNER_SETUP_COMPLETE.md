# GitHub Actions Runner Setup - Complete Guide

**Date**: 2025-10-22
**Repository**: quickstark/demo-gallery
**Status**: ✅ Ready for Setup

## 🎯 Current Status

You're now in the GitHub runner setup page with the correct token for **demo-gallery**.

**Previous Issue**: Was using FastAPI project's runner token
**Resolution**: Now using demo-gallery's registration token

## 🚀 Complete Setup Steps

### Step 1: Configure the Runner ✅ (You're Here)

You should see this in the GitHub UI:

```
Configure

# Create the runner and start the configuration experience
$ ./config.sh --url https://github.com/quickstark/demo-gallery --token AEFUERVJ5VWIYTKKBY572KTI7EHQE

# Last step, run it!
$ ./run.sh
```

### Step 2: Where to Run These Commands

**Option A: Native Installation (Direct on Server)**

If you want to install directly on your Ubuntu server:

```bash
# SSH to your server
ssh user@your-server

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download runner (Linux x64)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Optional: Validate the hash (from GitHub page)
echo "29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278  actions-runner-linux-x64-2.311.0.tar.gz" | shasum -a 256 -c

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure with YOUR token
./config.sh --url https://github.com/quickstark/demo-gallery --token AEFUERVJ5VWIYTKKBY572KTI7EHQE

# During configuration, you'll be asked:
#   - Runner name: demo-gallery-runner (or any name you prefer)
#   - Runner group: Default
#   - Labels: self-hosted,Linux,X64 (accept defaults)
#   - Work folder: _work (accept default)

# Start the runner
./run.sh

# To run as a service (recommended):
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

**Option B: Docker Container (Recommended)**

If you prefer Docker (better isolation and easier management):

```bash
# Get your token from GitHub (shown above)
REGISTRATION_TOKEN="AEFUERVJ5VWIYTKKBY572KTI7EHQE"

# Create runner directory
mkdir -p /docker/appdata/demo-gallery-runner

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

# Check logs to verify registration
docker logs demo-gallery-runner --tail 50

# Should see:
# ✓ Connected to GitHub
# ✓ Runner successfully registered
# ✓ Runner is listening for jobs
```

**Option C: Use Our Automated Script**

We created a script that does all of this automatically:

```bash
# From your project directory
cd /Users/dirk.nielsen/Documents/Github/demo-gallery

# Run the setup script
./scripts/setup-runner.sh

# It will:
# 1. Check prerequisites
# 2. Get a fresh registration token automatically
# 3. Set up the Docker container
# 4. Verify registration
# 5. Show you the runner status
```

## 🔍 Step 3: Verify Runner Registration

After running the setup (any option above), verify it worked:

**Check via GitHub CLI**:
```bash
gh api repos/quickstark/demo-gallery/actions/runners
```

**Expected output**:
```json
{
  "total_count": 1,
  "runners": [
    {
      "id": 123456,
      "name": "demo-gallery-runner",
      "os": "Linux",
      "status": "online",
      "busy": false,
      "labels": [
        {"id": 1, "name": "self-hosted", "type": "read-only"},
        {"id": 2, "name": "Linux", "type": "read-only"},
        {"id": 3, "name": "X64", "type": "read-only"}
      ]
    }
  ]
}
```

**Check via GitHub UI**:
```
https://github.com/quickstark/demo-gallery/settings/actions/runners
```

Should show:
```
Self-hosted runners (1)

  🟢 demo-gallery-runner
     Status: Idle
     Labels: self-hosted, Linux, X64
     Last activity: Just now
```

## ✅ Step 4: Test the Runner

Once registered, test that it picks up jobs:

```bash
# Cancel any queued workflows first
gh run list --status queued --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}

# Trigger a new workflow run
gh workflow run deploy.yml

# Watch it execute (should start immediately!)
gh run watch

# Or check status
gh run list --limit 3
```

**Expected behavior**:
```
✅ Workflow status: "in_progress" (within 5-10 seconds)
✅ No more "Waiting for a runner to pick up this job..."
✅ Runner shows as "Active" or "Busy" in GitHub
```

## 📋 Runner Configuration Details

### Recommended Configuration

**Runner Name**: `demo-gallery-runner` (or any descriptive name)
**Labels**: `self-hosted`, `Linux`, `X64` (accept defaults)
**Work Folder**: `_work` (accept default)

### Why These Settings?

**Runner Name**:
- Use descriptive name to identify which project it serves
- Example: `demo-gallery-runner`, `gallery-prod-runner`

**Labels**:
- `self-hosted` - Required (workflow specifies this)
- `Linux` - Auto-added based on OS
- `X64` - Auto-added based on architecture
- You can add custom labels if needed

**Work Folder**:
- Default `_work` is fine
- This is where GitHub Actions checks out your code

## 🔧 Important: Docker Access

Your workflow needs to **build and push Docker images**. The runner must have Docker access.

### Native Installation

Add runner user to docker group:
```bash
# If runner runs as specific user
sudo usermod -aG docker <runner-user>

# If running as root/service
# Should work automatically
```

### Docker Container

Ensure Docker socket is mounted (already in our script):
```bash
-v /var/run/docker.sock:/var/run/docker.sock
```

**Verify Docker access** (after runner is running):
```bash
# For native installation
sudo -u <runner-user> docker ps

# For Docker container
docker exec demo-gallery-runner docker ps

# Should show running containers, not permission denied
```

## 🎯 What Happens After Setup

### 1. Runner Registers
```
Runner connects to GitHub
    ↓
GitHub: "Hello demo-gallery-runner, welcome!"
    ↓
Runner: "I'm ready for work with labels: self-hosted, Linux, X64"
    ↓
Status: 🟢 Idle (waiting for jobs)
```

### 2. Workflow Triggers
```
You push to main / manual trigger
    ↓
GitHub Actions: "Need runner with label: self-hosted"
    ↓
Finds: demo-gallery-runner (Idle)
    ↓
Assigns job to runner
    ↓
Status: 🔵 Active/Busy
```

### 3. Job Execution
```
Runner receives job
    ↓
1. Checkout code
2. Install Datadog CI
3. Read VERSION file
4. Run SonarQube analysis
5. Build Docker image
6. Push to Docker Hub
7. Deploy to server
8. Mark deployment in Datadog
    ↓
Job complete
    ↓
Status: 🟢 Idle (ready for next job)
```

## 🚨 Troubleshooting

### Runner Shows Offline Immediately

**Symptoms**: Runner registers but shows offline within minutes

**Causes**:
- Network connectivity issues
- Firewall blocking GitHub API
- Runner service crashed

**Fix**:
```bash
# Check runner logs
docker logs demo-gallery-runner --tail 100

# Or for native installation
sudo journalctl -u actions.runner.* -n 100

# Restart runner
docker restart demo-gallery-runner

# Or for native installation
sudo ./svc.sh restart
```

### Jobs Still Queued After Registration

**Symptoms**: Runner shows online but jobs don't start

**Causes**:
- Label mismatch
- Runner busy with another job
- Runner in wrong repository

**Fix**:
```bash
# Verify runner labels
gh api repos/quickstark/demo-gallery/actions/runners --jq '.runners[].labels[].name'

# Should include "self-hosted"

# Check if runner is busy
gh api repos/quickstark/demo-gallery/actions/runners --jq '.runners[] | {name, status, busy}'

# If labels missing, re-register with correct labels
```

### Docker Commands Fail in Workflow

**Symptoms**: Workflow fails at Docker build step

**Causes**:
- Docker socket not mounted
- Runner doesn't have Docker permissions

**Fix**:
```bash
# For Docker container, ensure socket mounted:
docker inspect demo-gallery-runner | grep docker.sock

# Should show:
# "/var/run/docker.sock:/var/run/docker.sock"

# If not, recreate container with socket mount
docker rm -f demo-gallery-runner
# Then run with -v /var/run/docker.sock:/var/run/docker.sock
```

## 📊 Expected Final State

### GitHub Runners Page
```
https://github.com/quickstark/demo-gallery/settings/actions/runners

Self-hosted runners (1)

  🟢 demo-gallery-runner
     Status: Idle (or Active when running jobs)
     Labels: self-hosted, Linux, X64
     Last activity: [Recent timestamp]
     Version: 2.311.0
```

### Workflow Behavior
```
Before: Workflows stuck "Queued" forever
After:  Workflows start within 5-10 seconds
```

### Container/Service Status
```bash
# Docker container
docker ps --filter name=demo-gallery-runner
# demo-gallery-runner   Up 10 minutes   ...

# Native service
sudo ./svc.sh status
# ● actions.runner.quickstark-demo-gallery.demo-gallery-runner.service - GitHub Actions Runner
#    Active: active (running)
```

## 🎉 Success Criteria

You'll know everything is working when:

- ✅ Runner shows as 🟢 Idle/Active in GitHub
- ✅ Labels include "self-hosted"
- ✅ Workflow starts immediately (not queued)
- ✅ Docker build step succeeds
- ✅ Deployment completes successfully
- ✅ Container/service auto-restarts after reboot

## 📝 Next Steps After Setup

### 1. Test Complete Workflow
```bash
# Make a small change
echo "Test runner" >> README.md
git add README.md
git commit -m "test: Verify runner picks up jobs"
git push origin main

# Watch it deploy
gh run watch
```

### 2. Monitor Runner Health
```bash
# Check runner status regularly
gh api repos/quickstark/demo-gallery/actions/runners

# Monitor logs
docker logs -f demo-gallery-runner

# Or for native
sudo journalctl -u actions.runner.* -f
```

### 3. Set Up Monitoring (Optional)
```bash
# Create health check script
cat > /docker/appdata/check-runner-health.sh << 'EOF'
#!/bin/bash
RUNNER_STATUS=$(gh api repos/quickstark/demo-gallery/actions/runners --jq '.runners[0].status')
if [ "$RUNNER_STATUS" != "online" ]; then
    echo "Runner offline, restarting..."
    docker restart demo-gallery-runner
fi
EOF

chmod +x /docker/appdata/check-runner-health.sh

# Add to crontab (check every 5 minutes)
crontab -e
# Add: */5 * * * * /docker/appdata/check-runner-health.sh
```

## 🔗 Related Documentation

- **[RUNNER_DIAGNOSIS.md](./RUNNER_DIAGNOSIS.md)** - Root cause analysis
- **[RUNNER_TROUBLESHOOTING.md](./RUNNER_TROUBLESHOOTING.md)** - Troubleshooting guide
- **[setup-runner.sh](../scripts/setup-runner.sh)** - Automated setup script
- **[restart-runner.sh](../scripts/restart-runner.sh)** - Maintenance script

## 📞 Support

If you encounter issues:

1. Check runner logs: `docker logs demo-gallery-runner --tail 100`
2. Verify registration: `gh api repos/quickstark/demo-gallery/actions/runners`
3. Review [RUNNER_TROUBLESHOOTING.md](./RUNNER_TROUBLESHOOTING.md)
4. Check GitHub Actions status: https://www.githubstatus.com/

---

## 🎯 Quick Command Reference

```bash
# Check runner status
gh api repos/quickstark/demo-gallery/actions/runners

# Trigger workflow
gh workflow run deploy.yml

# Watch workflow
gh run watch

# Cancel queued runs
gh run list --status queued --json databaseId -q '.[].databaseId' | xargs -I {} gh run cancel {}

# Restart runner (Docker)
docker restart demo-gallery-runner

# View runner logs (Docker)
docker logs -f demo-gallery-runner

# Restart runner (Native)
sudo ./svc.sh restart

# View runner logs (Native)
sudo journalctl -u actions.runner.* -f
```

---

**You're almost there! Just run the configuration commands with your demo-gallery token and your workflows will start executing immediately!** 🚀
