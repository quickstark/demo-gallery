# Quick Runner Setup - Demo Gallery

**Token**: `AEFUERVJ5VWIYTKKBY572KTI7EHQE` (valid for 1 hour)
**Repository**: quickstark/demo-gallery

## 🚀 Three Options - Pick One

### Option 1: Automated Docker Setup (Easiest - Recommended)

```bash
cd /Users/dirk.nielsen/Documents/Github/demo-gallery
./scripts/setup-runner.sh
```

✅ **Done!** Script handles everything automatically.

---

### Option 2: Manual Docker Setup

```bash
# Set your token
REGISTRATION_TOKEN="AEFUERVJ5VWIYTKKBY572KTI7EHQE"

# Run runner container
docker run -d \
  --name demo-gallery-runner \
  --restart unless-stopped \
  -e REPO_URL="https://github.com/quickstark/demo-gallery" \
  -e RUNNER_NAME="demo-gallery-runner" \
  -e RUNNER_TOKEN="$REGISTRATION_TOKEN" \
  -e LABELS="self-hosted,Linux,X64" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /docker/appdata/demo-gallery-runner:/tmp/github-runner \
  myoung34/github-runner:latest

# Verify
docker logs demo-gallery-runner --tail 20
```

---

### Option 3: Native Installation (On Server)

```bash
# SSH to server
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure
./config.sh --url https://github.com/quickstark/demo-gallery --token AEFUERVJ5VWIYTKKBY572KTI7EHQE

# When prompted:
#   Name: demo-gallery-runner
#   Labels: (accept defaults: self-hosted, Linux, X64)
#   Work folder: (accept default: _work)

# Install as service (recommended)
sudo ./svc.sh install
sudo ./svc.sh start

# Or run directly (for testing)
./run.sh
```

---

## ✅ Verify Setup

```bash
# Check runner registered
gh api repos/quickstark/demo-gallery/actions/runners

# Should show:
# {
#   "total_count": 1,
#   "runners": [{"name": "demo-gallery-runner", "status": "online"}]
# }
```

---

## 🧪 Test It Works

```bash
# Cancel old queued workflows
gh run list --status queued --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}

# Trigger new workflow
gh workflow run deploy.yml

# Watch it run (should start immediately!)
gh run watch
```

**Expected**: Workflow starts within 5-10 seconds (not stuck in queue)

---

## 🔧 If Something Goes Wrong

**Check logs**:
```bash
# Docker
docker logs demo-gallery-runner --tail 50

# Native
sudo journalctl -u actions.runner.* -n 50
```

**Restart**:
```bash
# Docker
docker restart demo-gallery-runner

# Native
sudo ./svc.sh restart
```

**Get new token** (if expired):
```bash
gh api -X POST repos/quickstark/demo-gallery/actions/runners/registration-token --jq '.token'
```

---

## 📚 Full Documentation

- [RUNNER_SETUP_COMPLETE.md](./RUNNER_SETUP_COMPLETE.md) - Complete guide
- [RUNNER_DIAGNOSIS.md](./RUNNER_DIAGNOSIS.md) - Root cause analysis
- [RUNNER_TROUBLESHOOTING.md](./RUNNER_TROUBLESHOOTING.md) - Troubleshooting

---

**Pick your preferred option above and run it now while the token is still valid!** ⏱️
