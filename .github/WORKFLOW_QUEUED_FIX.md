# Workflow Queued - Organization Runner Issue

**Date**: 2025-10-22
**Symptom**: Workflow stuck in "queued" state after moving to org-level runner
**Most Likely Cause**: Repository still under personal account, not organization

## 🎯 Root Cause (Most Likely)

**Organization runners ONLY work for repositories IN that organization.**

If you have:
- ✅ Runner registered to: **quickstarkdemo** (organization)
- ❌ Repository located at: **quickstark/demo-gallery** (personal account)

Then:
- Workflow runs in `quickstark/demo-gallery`
- Looks for runners in personal account (not organization)
- Can't find org-level runners
- Result: **Queued forever** waiting for a runner

## 🔍 Quick Diagnosis

Run the diagnostic script:

```bash
cd /Users/dirk.nielsen/Documents/Github/demo-gallery
./scripts/diagnose-runner.sh
```

This will check:
1. ✓ Repository location (personal vs organization)
2. ✓ Runner container status
3. ✓ Runner registration in GitHub
4. ✓ Runner online/offline status
5. ✓ Workflow requirements

---

## ✅ Fix 1: Repository Mismatch (MOST COMMON)

**If repo is at** `quickstark/demo-gallery` **but runner is org-level:**

### Option A: Transfer Repository to Organization (Recommended)

```bash
# Transfer repo from personal account to organization
gh repo transfer quickstark/demo-gallery quickstarkdemo

# Update local git remote
cd /Users/dirk.nielsen/Documents/Github/demo-gallery
git remote set-url origin https://github.com/quickstarkdemo/demo-gallery.git

# Verify
git remote -v
# Should show: https://github.com/quickstarkdemo/demo-gallery.git
```

**Benefits**:
- ✅ Use organization-level runner (cleaner, more professional)
- ✅ One runner serves all org repos
- ✅ Better for multi-repo setups

**After transfer**:
- Repository URL changes: `quickstark/demo-gallery` → `quickstarkdemo/demo-gallery`
- Update any external references (bookmarks, CI configs, etc.)
- GitHub automatically redirects old URL, but better to update

---

### Option B: Use Repository-Level Runner Instead

**If you want to keep repo at** `quickstark/demo-gallery`:

```bash
# Stop org-level runner
docker-compose -f docker-compose.runner-fixed.yml down

# Get REPO-level registration token (not org-level)
REPO_TOKEN=$(gh api -X POST repos/quickstark/demo-gallery/actions/runners/registration-token --jq '.token')

# Update .env with repo token
echo "RUNNER_TOKEN=$REPO_TOKEN" > .env.runner

# Create repo-level runner compose
cat > docker-compose.repo-runner.yml <<'EOF'
version: '3.8'

services:
  runner:
    image: myoung34/github-runner:latest
    container_name: demo-gallery-runner
    restart: unless-stopped
    privileged: true

    environment:
      # Repository URL (not org!)
      REPO_URL: https://github.com/quickstark/demo-gallery
      RUNNER_NAME: demo-gallery-runner
      RUNNER_TOKEN: ${RUNNER_TOKEN}
      LABELS: self-hosted,Linux,X64,ubuntu,docker
      EPHEMERAL: "false"
      DISABLE_AUTO_UPDATE: "false"

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /docker/appdata/demo-gallery-runner:/tmp/github-runner

    networks:
      - runner-network

networks:
  runner-network:
    driver: bridge
EOF

# Deploy repo-level runner
docker-compose -f docker-compose.repo-runner.yml --env-file .env.runner up -d

# Verify
gh api repos/quickstark/demo-gallery/actions/runners
```

**Drawbacks**:
- ⚠️ Need separate runner per repository
- ⚠️ More management overhead
- ⚠️ Less scalable

---

## ✅ Fix 2: Runner Not Running

**If runner container is stopped:**

```bash
# Check status
docker ps -a | grep runner

# Start runner
docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d

# Watch logs
docker logs -f quickstarkdemo-runner
```

**Success indicators**:
```
✓ Connected to GitHub
✓ Runner successfully registered
✓ Runner is listening for jobs
```

---

## ✅ Fix 3: Runner Offline/Disconnected

**If runner is running but offline:**

```bash
# Check logs for errors
docker logs quickstarkdemo-runner --tail 50

# Common issues:
# - Token expired → Regenerate and restart
# - Network issues → Check connectivity
# - Configuration errors → Review compose file

# Restart runner
docker restart quickstarkdemo-runner

# Or full recreation
docker-compose -f docker-compose.runner-fixed.yml down
TOKEN=$(gh api -X POST orgs/quickstarkdemo/actions/runners/registration-token --jq '.token')
echo "GITHUB_PAT=$TOKEN" > .env
docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d
```

---

## 🔍 Verify Fix Worked

### Check 1: Runner Shows Online

```bash
# For organization runner
gh api orgs/quickstarkdemo/actions/runners

# Should show:
# {
#   "total_count": 1,
#   "runners": [{
#     "name": "quickstarkdemo-runner",
#     "status": "online",  # ← Must be "online"
#     "busy": false
#   }]
# }
```

**Or check GitHub UI**:
```
https://github.com/organizations/quickstarkdemo/settings/actions/runners
```

Should show:
```
🟢 quickstarkdemo-runner - Idle
```

---

### Check 2: Trigger Test Workflow

```bash
# Trigger workflow
gh workflow run deploy.yml

# Watch status (should start within 10 seconds)
gh run watch

# Should see:
# ✓ Queued    (< 5 seconds)
# ✓ In progress
# ✓ Building Docker image...
```

---

## 📊 Decision Matrix

### Scenario 1: Want Professional Org Setup

**Action**: Transfer repo to organization

```bash
gh repo transfer quickstark/demo-gallery quickstarkdemo
git remote set-url origin https://github.com/quickstarkdemo/demo-gallery.git
```

**Result**: ✅ Use org-level runner (already configured)

---

### Scenario 2: Want to Keep Personal Account

**Action**: Switch to repo-level runner

```bash
# Stop org runner
docker-compose -f docker-compose.runner-fixed.yml down

# Deploy repo-level runner (see Option B above)
docker-compose -f docker-compose.repo-runner.yml --env-file .env.runner up -d
```

**Result**: ✅ Runner works with personal repo

---

## 🎯 Recommended Path

**I recommend Option A: Transfer to Organization**

**Why**:
- ✅ Cleaner, more professional structure
- ✅ ONE runner serves all organization repos
- ✅ Easier to add more projects later
- ✅ Better for team collaboration
- ✅ Industry standard approach

**How**:
```bash
# 1. Transfer repository
gh repo transfer quickstark/demo-gallery quickstarkdemo

# 2. Update local remote
git remote set-url origin https://github.com/quickstarkdemo/demo-gallery.git

# 3. Verify runner is online
gh api orgs/quickstarkdemo/actions/runners

# 4. Test workflow
gh workflow run deploy.yml
gh run watch
```

**Time**: 5 minutes total

---

## 🔧 Troubleshooting

### Issue: "gh repo transfer" fails

**Error**:
```
user does not have required permissions
```

**Fix**: Ensure you have admin permissions on both source and destination

```bash
# Check permissions
gh api repos/quickstark/demo-gallery --jq '.permissions'

# Should show: "admin": true
```

---

### Issue: Workflow still queued after transfer

**Possible causes**:
1. Runner not online → Check `gh api orgs/quickstarkdemo/actions/runners`
2. Runner busy → Wait for current job to finish
3. Label mismatch → Check workflow uses `runs-on: self-hosted`

**Debug**:
```bash
# Check workflow run details
gh run list --limit 1
gh run view <RUN_ID>

# Check runner logs
docker logs quickstarkdemo-runner --tail 50
```

---

### Issue: Don't want to transfer repo

**Alternative**: Use repo-level runner (see Fix 1, Option B)

**Trade-off**: More management, less scalable, but works with personal repos

---

## 📋 Quick Reference

### Diagnostic Command
```bash
./scripts/diagnose-runner.sh
```

### Transfer Repo to Org
```bash
gh repo transfer quickstark/demo-gallery quickstarkdemo
git remote set-url origin https://github.com/quickstarkdemo/demo-gallery.git
```

### Check Runner Status
```bash
# Organization
gh api orgs/quickstarkdemo/actions/runners

# Repository
gh api repos/quickstark/demo-gallery/actions/runners

# Container
docker ps | grep runner
docker logs quickstarkdemo-runner --tail 20
```

### Test Workflow
```bash
gh workflow run deploy.yml
gh run watch
```

---

**Last Updated**: 2025-10-22
**Most Common Issue**: Repository not in organization
**Fix**: Transfer repo OR switch to repo-level runner
**Time to Fix**: 5 minutes
