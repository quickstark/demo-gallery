# Docker Push Failure - Authentication Fix

**Date**: 2025-10-22
**Issue**: Docker build succeeds but push fails with "denied: requested access to the resource is denied"
**Status**: ✅ Solution Identified

## 🎯 Root Cause Analysis

### What Happened

**✅ Docker Build: SUCCESS**
```
#19 exporting to image
#19 writing image sha256:0bb1918355fad2ccd5971377e6c05f89fe15d0c1e20b1dcdf6300c8482fe0217 done
#19 naming to docker.io/***/demo-gallery:latest done
#19 DONE 0.0s
```

**❌ Docker Push: FAILED**
```
The push refers to repository [docker.io/***/demo-gallery]
denied: requested access to the resource is denied
Error: Process completed with exit code 1.
```

### Root Cause

**Missing or incorrect Docker Hub credentials in GitHub Secrets**

deploy.yml:242 requires:
```yaml
echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login --username "${{ secrets.DOCKERHUB_USER }}" --password-stdin
```

**Problem**: `DOCKERHUB_USER` and `DOCKERHUB_TOKEN` secrets are either:
1. Not configured in GitHub repository settings
2. Configured with incorrect values
3. Token doesn't have push permissions

## 🔧 Solution: Configure Docker Hub Credentials

### Step 1: Create Docker Hub Access Token

**On Docker Hub** (https://hub.docker.com):

1. **Log in** to Docker Hub
2. **Navigate to**: Account Settings → Security → Access Tokens
3. **Click**: "New Access Token"
4. **Configure**:
   - **Description**: `github-actions-demo-gallery`
   - **Access permissions**: **Read, Write, Delete** (or at minimum Read & Write)
5. **Generate** and **COPY the token immediately** (you won't see it again!)

**Example token**: `dckr_pat_1234abcd5678efgh9012ijkl3456mnop`

### Step 2: Add Secrets to GitHub Repository

**On GitHub** (https://github.com/quickstark/demo-gallery):

1. **Navigate to**: Settings → Secrets and variables → Actions
2. **Click**: "New repository secret"

**Add Secret #1 - DOCKERHUB_USER**:
- **Name**: `DOCKERHUB_USER`
- **Value**: Your Docker Hub username (e.g., `quickstark`)
- **Click**: "Add secret"

**Add Secret #2 - DOCKERHUB_TOKEN**:
- **Name**: `DOCKERHUB_TOKEN`
- **Value**: The access token you copied from Step 1
- **Click**: "Add secret"

### Step 3: Verify Secrets Are Configured

**Via GitHub CLI**:
```bash
gh secret list

# Should show:
# DOCKERHUB_TOKEN    Updated 2025-10-22
# DOCKERHUB_USER     Updated 2025-10-22
# ... (other secrets)
```

**Via GitHub UI**:
- Go to: Settings → Secrets and variables → Actions
- Verify both `DOCKERHUB_USER` and `DOCKERHUB_TOKEN` are listed

### Step 4: Test the Fix

**Trigger a new workflow run**:
```bash
# Option 1: Manual trigger
gh workflow run deploy.yml

# Option 2: Push a change
git commit --allow-empty -m "test: Verify Docker Hub authentication"
git push origin main
```

**Watch the workflow**:
```bash
gh run watch
```

**Expected success output**:
```
Building Docker image for React Gallery...
Login Succeeded
... (build steps)
#19 naming to docker.io/quickstark/demo-gallery:latest done
The push refers to repository [docker.io/quickstark/demo-gallery]
3a0461589c41: Pushed
6516a36bd5b6: Pushed
... (all layers pushed)
latest: digest: sha256:abc123... size: 1234
✅ Docker image built and pushed successfully
```

## 📋 Complete Required Secrets List

For **full deployment pipeline** to work, configure these secrets:

### Critical (Deployment will fail without these)

| Secret | Purpose | Where to Get | Required |
|--------|---------|--------------|----------|
| `DOCKERHUB_USER` | Docker Hub username | Your Docker Hub account | ✅ YES |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Docker Hub → Security → Access Tokens | ✅ YES |

### Important (Datadog integration)

| Secret | Purpose | Where to Get | Required |
|--------|---------|--------------|----------|
| `DD_API_KEY` | Datadog API key | Datadog → Organization Settings → API Keys | For Datadog |
| `DD_APP_KEY` | Datadog Application key | Datadog → Organization Settings → Application Keys | For Datadog |
| `DD_ENV` | Environment name | Your choice (e.g., `production`) | Optional* |

*Has fallback to `production` if not set

### Optional (Application configuration)

| Secret | Purpose | Default/Fallback |
|--------|---------|------------------|
| `VITE_API_URL` | API endpoint URL | No default |
| `VITE_API_KEY` | API authentication key | No default |
| `VITE_AUTH_USERNAME` | Basic auth username | No default |
| `VITE_AUTH_PASSWORD` | Basic auth password | No default |
| `VITE_ENVIRONMENT` | App environment | Fallback: `production` |
| `VITE_DATADOG_APPLICATION_ID` | Datadog RUM app ID | No default |
| `VITE_DATADOG_CLIENT_TOKEN` | Datadog RUM token | No default |
| `VITE_DATADOG_SITE` | Datadog site | Fallback: `datadoghq.com` |
| `VITE_DATADOG_SERVICE` | Service name | Fallback: `demo-gallery` |

### Optional (Code quality)

| Secret | Purpose | Required |
|--------|---------|----------|
| `SONAR_TOKEN` | SonarQube authentication | Only if using SonarQube |
| `SONAR_HOST_URL` | SonarQube server URL | Only if using SonarQube |

## 🚀 Quick Fix Using Script

If you have all secrets in `.env` file:

```bash
# Add Docker Hub credentials to .env
echo "DOCKERHUB_USER=your-docker-username" >> .env
echo "DOCKERHUB_TOKEN=dckr_pat_your_token_here" >> .env

# Upload all secrets to GitHub
./scripts/setup-github-secrets.sh

# Verify
gh secret list
```

**Note**: The script uploads ALL variables from `.env` to GitHub Secrets.

## 🔍 Troubleshooting

### Issue: "Login Succeeded" but push still fails

**Possible causes**:
1. Docker Hub repository doesn't exist
2. Username in secret doesn't match Docker Hub username
3. Token doesn't have write permissions

**Fix**:
```bash
# Create repository on Docker Hub first
# Or verify repository exists: https://hub.docker.com/r/YOUR_USERNAME/demo-gallery

# Verify username matches exactly (case-sensitive)
# Regenerate token with Read & Write permissions
```

### Issue: Token not working

**Solution**: Regenerate token with correct permissions
1. Docker Hub → Security → Access Tokens
2. Delete old token
3. Create new token with **Read, Write, Delete** permissions
4. Update `DOCKERHUB_TOKEN` secret in GitHub

### Issue: "repository does not exist or may require 'docker login'"

**Solution**: Ensure repository exists on Docker Hub
```bash
# Option 1: Create via Docker Hub UI
# Go to: https://hub.docker.com/repository/create
# Name: demo-gallery
# Visibility: Public or Private

# Option 2: Push will auto-create if username is correct and token has permissions
```

### Issue: Want to test authentication locally

**Test Docker Hub auth locally**:
```bash
# Use the same credentials
echo "YOUR_TOKEN" | docker login --username YOUR_USERNAME --password-stdin

# Should see: Login Succeeded

# Test push
docker tag demo-gallery:latest YOUR_USERNAME/demo-gallery:test
docker push YOUR_USERNAME/demo-gallery:test

# Should succeed without "denied" error
```

## 📊 Verification Checklist

After fixing:

- [ ] `DOCKERHUB_USER` secret configured in GitHub
- [ ] `DOCKERHUB_TOKEN` secret configured in GitHub
- [ ] Token has Read & Write permissions at minimum
- [ ] Docker Hub repository exists (or will auto-create)
- [ ] Username matches exactly (case-sensitive)
- [ ] New workflow run triggered
- [ ] "Login Succeeded" appears in logs
- [ ] "docker push" completes without "denied" error
- [ ] Image appears on Docker Hub: `https://hub.docker.com/r/YOUR_USERNAME/demo-gallery`

## 🎉 Success Criteria

You'll know it's fixed when:

✅ **Build logs show**:
```
Login Succeeded
Building Docker image...
... (build steps)
Pushing image...
latest: digest: sha256:abc123... size: 1234
✅ Docker image built and pushed successfully
```

✅ **Docker Hub shows**:
- New image with tag `latest`
- New image with tag `1.0.2-abc1234` (version-SHA)
- New image with tag `abc1234...` (commit SHA)

✅ **Deployment continues**:
```
=== Deploying React Gallery to Local Docker ===
Pulling latest image...
Starting container...
✅ Container started successfully
```

## 🔗 Related Documentation

- **deploy.yml workflow**: `.github/workflows/deploy.yml` (lines 234-267)
- **Secrets setup script**: `scripts/setup-github-secrets.sh`
- **Environment template**: `.env.example`
- **Docker Hub Access Tokens**: https://docs.docker.com/security/for-developers/access-tokens/
- **GitHub Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets

---

## 📝 Summary

**Problem**: Docker push failed with "denied: requested access to the resource is denied"
**Root Cause**: Missing `DOCKERHUB_USER` and `DOCKERHUB_TOKEN` GitHub Secrets
**Solution**: Create Docker Hub access token and add both secrets to GitHub repository
**Verification**: Re-run workflow and verify push succeeds

**Next Step**: Add the two required secrets to GitHub repository settings and trigger a new workflow run.

---

**Last Updated**: 2025-10-22
**Issue Status**: Identified - Awaiting Secret Configuration
**Documentation**: Complete
