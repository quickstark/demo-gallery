# Docker Hub Authentication Diagnostic

**Issue**: Secrets configured but push still fails with "denied: requested access to the resource is denied"
**Date**: 2025-10-22

## 🔍 Quick Diagnostic Checklist

Since your secrets ARE configured in GitHub, the "denied" error means one of these 3 issues:

### ✅ Check 1: Does the Docker Hub Repository Exist?

**Check now**:
1. Go to: https://hub.docker.com/repositories
2. Look for: `demo-gallery` repository
3. **If it doesn't exist** → That's your issue!

**Fix if missing**:
```bash
# Option 1: Create via Docker Hub UI
# Go to: https://hub.docker.com/repository/create
# Name: demo-gallery
# Visibility: Public (or Private if you have a paid account)

# Option 2: Create with first push (requires correct token permissions)
# The push will auto-create if token has correct permissions
```

### ✅ Check 2: Does Your Token Have WRITE Permissions?

**Check token permissions**:
1. Go to: https://hub.docker.com/settings/security
2. Find your token: `github-actions-demo-gallery` (or whatever you named it)
3. Check permissions:
   - ❌ **Read only** → This is the problem!
   - ✅ **Read, Write, Delete** → Good!

**Fix if Read only**:
1. Delete the current token
2. Create NEW token with **Read, Write, Delete** permissions
3. Update `DOCKERHUB_TOKEN` secret in GitHub with the new token

### ✅ Check 3: Is Your Username Exactly Correct?

**Verify username matches**:
1. Go to: https://hub.docker.com/settings/general
2. Find your username (case-sensitive!)
3. Compare with your GitHub secret `DOCKERHUB_USER`
4. **Username MUST match exactly** (including case)

**Common mistakes**:
```bash
❌ DOCKERHUB_USER = "QuickStark"  (wrong case)
✅ DOCKERHUB_USER = "quickstark"  (correct)

❌ DOCKERHUB_USER = "quickstark " (extra space)
✅ DOCKERHUB_USER = "quickstark"  (correct)
```

**Fix if wrong**:
1. GitHub → Settings → Secrets → Actions
2. Edit `DOCKERHUB_USER`
3. Update with EXACT username from Docker Hub

## 🧪 Test Authentication Locally

**Test your credentials work**:
```bash
# Use the exact same credentials from your .env
DOCKERHUB_USER="your-username-from-env"
DOCKERHUB_TOKEN="your-token-from-env"

# Test login
echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USER" --password-stdin

# Expected if credentials are correct:
# Login Succeeded

# Expected if credentials are wrong:
# Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized
```

**If login fails locally** → Your token or username is wrong in `.env`

**If login succeeds locally** → Check if GitHub secrets match your `.env` exactly

## 🔍 Most Likely Culprit

Based on "denied: requested access to the resource is denied" error:

**90% chance**: Token only has **Read** permissions, not **Write**

**Fix**:
1. Docker Hub → Settings → Security → Access Tokens
2. Delete current token
3. Create new token with **Read, Write, Delete** permissions
4. Update GitHub secret `DOCKERHUB_TOKEN` with new token value
5. Re-run workflow

## 📋 Verification After Fix

**Test the fix**:
```bash
# Trigger new workflow
gh workflow run deploy.yml

# Watch logs
gh run watch

# Look for:
# ✅ "Login Succeeded"
# ✅ "docker push" completes without "denied" error
# ✅ "latest: digest: sha256:... size: ..."
```

**Check Docker Hub**:
```bash
# After successful push, verify image exists
# https://hub.docker.com/r/YOUR_USERNAME/demo-gallery/tags
```

## 🎯 Expected Success Output

When fixed correctly, you'll see:
```
Building Docker image for React Gallery...
Login Succeeded
... (build steps)
The push refers to repository [docker.io/quickstark/demo-gallery]
3a0461589c41: Pushed
6516a36bd5b6: Pushed
512dc1390c36: Pushed
... (all layers pushed)
latest: digest: sha256:abc123... size: 1234
1.0.2-abc1234: digest: sha256:def456... size: 1234
✅ Docker image built and pushed successfully
```

## 🚨 If Still Failing After All Checks

**Last resort debugging**:
```bash
# Check what GitHub sees for secrets (won't show values, just confirms they exist)
gh secret list

# Should show:
# DOCKERHUB_TOKEN    Updated XXXX-XX-XX
# DOCKERHUB_USER     Updated XXXX-XX-XX

# Re-set both secrets fresh
gh secret set DOCKERHUB_USER
# Paste your Docker Hub username

gh secret set DOCKERHUB_TOKEN
# Paste your Docker Hub token

# Trigger workflow again
gh workflow run deploy.yml
```

---

## 📊 Summary

**Symptoms**: Secrets exist, but push denied
**Most Common Cause**: Token has Read-only permissions
**Quick Fix**: Regenerate token with Write permissions
**Verification**: Re-run workflow and check for "Pushed" messages

**Check these in order**:
1. ✅ Token has **Write** permissions (not just Read)
2. ✅ Repository exists on Docker Hub OR token can auto-create
3. ✅ Username matches exactly (case-sensitive, no spaces)

---

**Last Updated**: 2025-10-22
