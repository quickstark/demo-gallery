# Runner Setup - Ready to Execute

**Date**: 2025-10-22
**Status**: ✅ Ready for execution
**Token**: `AEFUERVJ5VWIYTKKBY572KTI7EHQE` (valid for 1 hour from creation)

## 🎯 What's Been Fixed

### ✅ Script Enhanced for Ubuntu
The `scripts/setup-runner.sh` has been fixed to work on Ubuntu systems:

**Problem Solved**:
- Script was failing with "Docker not found" despite `/usr/bin/docker` existing
- Enhanced to check both `command -v docker` AND `[ -x /usr/bin/docker ]`
- Stores discovered path in `$DOCKER_CMD` variable
- Uses `$DOCKER_CMD` throughout instead of hardcoded 'docker'

**Same fix applied to**:
- Docker detection (lines 64-71)
- GitHub CLI detection (lines 84-92)
- All docker commands throughout script

### ✅ Documentation Complete
- **RUNNER_QUICK_SETUP.md**: Quick reference with 3 setup options
- **RUNNER_SETUP_COMPLETE.md**: Comprehensive guide with troubleshooting
- **RUNNER_DIAGNOSIS.md**: Root cause analysis of the queued workflows issue
- **setup-runner.sh**: Automated setup script (now Ubuntu-compatible)

## 🚀 Execute Runner Setup Now

### Option 1: Automated Script (Recommended)

**On your Ubuntu server** where you want the runner:

```bash
cd /Users/dirk.nielsen/Documents/Github/demo-gallery
./scripts/setup-runner.sh
```

**What it does automatically**:
1. ✅ Checks Docker and GitHub CLI are installed
2. ✅ Gets fresh registration token from GitHub
3. ✅ Creates runner directory: `/docker/appdata/demo-gallery-runner`
4. ✅ Pulls GitHub runner Docker image
5. ✅ Starts runner container with correct configuration
6. ✅ Verifies registration with GitHub
7. ✅ Shows you the runner status

**Expected output**:
```
[INFO] ✅ Docker found at: /usr/bin/docker
[INFO] ✅ Docker daemon is accessible
[INFO] ✅ GitHub CLI found at: /usr/bin/gh
[INFO] ✅ GitHub CLI is authenticated
[INFO] ✅ Registration token obtained
[INFO] ✅ Directory created: /docker/appdata/demo-gallery-runner
[INFO] ✅ Runner image is up to date
[INFO] ✅ Runner container started: demo-gallery-runner
[INFO] ✅ Runner successfully registered!
```

### Option 2: Manual Docker Setup

If you prefer to run commands manually:

```bash
# Get fresh token (if original expired)
gh api -X POST repos/quickstark/demo-gallery/actions/runners/registration-token --jq '.token'

# Set the token
REGISTRATION_TOKEN="AEFUERVJ5VWIYTKKBY572KTI7EHQE"

# Create directory
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

# Check logs
docker logs demo-gallery-runner --tail 50
```

## ✅ Verify Registration

After setup completes, verify the runner is registered:

```bash
# Check via GitHub CLI
gh api repos/quickstark/demo-gallery/actions/runners

# Expected output:
# {
#   "total_count": 1,
#   "runners": [
#     {
#       "id": 123456,
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

**Check in GitHub UI**:
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

## 🧪 Test Workflow Execution

Once runner is registered:

```bash
# Cancel old queued workflows (if any still exist)
gh run list --status queued --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}

# Trigger new workflow
gh workflow run deploy.yml

# Watch it execute (should start IMMEDIATELY!)
gh run watch
```

**Expected behavior**:
```
✅ Workflow transitions from "queued" → "in_progress" within 5-10 seconds
✅ No more "Waiting for a runner to pick up this job..."
✅ Runner shows as "Active" or "Busy" in GitHub
✅ Workflow completes successfully
```

## 🔧 Troubleshooting

### If script fails

**Check Docker**:
```bash
# Verify Docker is installed
which docker
# or
ls -l /usr/bin/docker

# Test Docker works
docker ps
```

**Check GitHub CLI**:
```bash
# Verify gh is installed
which gh

# Check authentication
gh auth status
```

### If token expired

**Get new token**:
```bash
gh api -X POST repos/quickstark/demo-gallery/actions/runners/registration-token --jq '.token'
```

Then update the script or manual command with new token.

### If container fails to start

**Check logs**:
```bash
docker logs demo-gallery-runner --tail 100
```

**Restart container**:
```bash
docker restart demo-gallery-runner
```

**Remove and recreate**:
```bash
docker rm -f demo-gallery-runner
./scripts/setup-runner.sh  # run script again
```

### If runner shows offline

**Check container status**:
```bash
docker ps --filter name=demo-gallery-runner
```

**Check container logs**:
```bash
docker logs demo-gallery-runner --tail 50
```

**Restart runner**:
```bash
docker restart demo-gallery-runner
```

## 📊 Success Criteria

You'll know everything is working when:

- ✅ Runner shows as 🟢 **Idle/Active** in GitHub (not Offline)
- ✅ Runner has labels: **self-hosted**, Linux, X64
- ✅ New workflow runs start **immediately** (within 5-10 seconds)
- ✅ No more workflows stuck in "Queued" status
- ✅ Docker build and deploy steps succeed in workflow
- ✅ Container auto-restarts after server reboot (--restart unless-stopped)

## 📋 Quick Command Reference

```bash
# Check runner status
gh api repos/quickstark/demo-gallery/actions/runners

# View runner container
docker ps --filter name=demo-gallery-runner

# Check runner logs
docker logs demo-gallery-runner --tail 50

# Follow runner logs live
docker logs -f demo-gallery-runner

# Restart runner
docker restart demo-gallery-runner

# Stop runner
docker stop demo-gallery-runner

# Remove runner (unregister first in GitHub UI!)
docker rm -f demo-gallery-runner

# Trigger workflow
gh workflow run deploy.yml

# Watch workflow
gh run watch

# List recent runs
gh run list --limit 5
```

## 🎉 After Successful Setup

Once your runner is working:

1. **Test deployment**: Push a small change to trigger workflow
2. **Monitor first run**: Watch it complete successfully
3. **Verify application**: Check deployed app is accessible
4. **Set up monitoring**: Consider health checks for runner container

## 📚 Documentation References

- **Quick Setup**: [RUNNER_QUICK_SETUP.md](./RUNNER_QUICK_SETUP.md)
- **Complete Guide**: [RUNNER_SETUP_COMPLETE.md](./RUNNER_SETUP_COMPLETE.md)
- **Diagnosis**: [RUNNER_DIAGNOSIS.md](./RUNNER_DIAGNOSIS.md)
- **Troubleshooting**: [RUNNER_TROUBLESHOOTING.md](./RUNNER_TROUBLESHOOTING.md)

---

## 🚦 Current Status

**Token Status**: ⏱️ Valid for 1 hour from creation
**Script Status**: ✅ Fixed and ready for Ubuntu
**Documentation**: ✅ Complete
**Ready to Execute**: ✅ YES

**Next Action**: Run `./scripts/setup-runner.sh` on your Ubuntu server now!

---

**Last Updated**: 2025-10-22
**Script Location**: `scripts/setup-runner.sh`
**Repository**: quickstark/demo-gallery
