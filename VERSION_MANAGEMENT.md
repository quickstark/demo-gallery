# Version Management

This document explains how versioning works in the React Gallery project.

## Single Source of Truth

The project uses a **centralized version management** approach with the `VERSION` file as the single source of truth.

### VERSION File

Location: `/VERSION` (project root)

```
1.0.0
```

**Format**: Semantic Versioning (`MAJOR.MINOR.PATCH`)
- **MAJOR**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR**: New features, backward compatible (e.g., 1.0.0 → 1.1.0)
- **PATCH**: Bug fixes, backward compatible (e.g., 1.0.0 → 1.0.1)
- **Prerelease**: Optional suffix (e.g., 1.0.0-beta.1, 2.0.0-rc.1)

## Automatic Version Injection

Version management is **completely automated** across all environments:

### Local Development

**Vite Plugin**: Automatically injects version at build time
- Reads `VERSION` file
- Gets current git commit SHA
- Creates `VITE_RELEASE` in format: `VERSION-SHA`
- No manual configuration needed

```javascript
// vite.config.js includes versionInjectionPlugin()
// Automatically injects: import.meta.env.VITE_RELEASE = "1.0.0-abc1234"
```

**How it works**:
```bash
# Start dev server
npm run dev
# Output: 📦 Version injection: 1.0.0-abc1234 (from VERSION file + git)

# Build for production
npm run build
# Output: 📦 Version injection: 1.0.0-abc1234 (from VERSION file + git)
```

### Production Deployment

**GitHub Actions**: `deploy.yml` workflow
- Reads `VERSION` file
- Appends GitHub commit SHA
- Injects as environment variable
- Creates Docker image tags

```yaml
# deploy.yml (lines 87-95)
- name: Read VERSION
  run: |
    BASE_VERSION=$(cat VERSION)
    SHORT_SHA="${{ github.sha }}"
    SHORT_SHA="${SHORT_SHA:0:7}"
    VERSION="${BASE_VERSION}-${SHORT_SHA}"
    echo "version=$VERSION" >> $GITHUB_OUTPUT

# Later used in deployment (line 304)
-e VITE_RELEASE="${{ steps.version.outputs.version }}"
```

## Version Flow Diagram

```
VERSION file (1.0.0)
    ↓
    ├─ Local Development
    │   ├─ Vite plugin reads VERSION
    │   ├─ Gets git SHA: abc1234
    │   └─ Injects: VITE_RELEASE="1.0.0-abc1234"
    │
    └─ Production Deployment
        ├─ GitHub Actions reads VERSION
        ├─ Gets commit SHA: def5678
        ├─ Injects: VITE_RELEASE="1.0.0-def5678"
        └─ Creates Docker tags:
            ├─ latest
            ├─ 1.0.0-def5678
            └─ def5678
```

## Where Version Is Used

### 1. Datadog RUM Tracking

```javascript
// src/App.jsx
const release = import.meta.env.VITE_RELEASE;

datadogRum.init({
  version: release,  // Uses auto-injected version
  // ... other config
});
```

### 2. Docker Image Tags

Created by `deploy.yml`:
- `latest` - Always points to most recent build
- `1.0.0-abc1234` - Full version with commit SHA
- `abc1234` - Commit SHA only

### 3. Git Tags & GitHub Releases

Created by `version-tagging.yml`:
- Git tag: `v1.0.0`
- GitHub Release: `Release v1.0.0`
- Release notes: Automatically generated from commits

### 4. Error Tracking & Monitoring

- Datadog RUM correlates errors with specific releases
- Datadog APM tracks performance by version
- Deployment markers in Datadog link to specific versions

## How to Update Version

### Step 1: Edit VERSION File

```bash
# For new feature (minor bump)
echo "1.1.0" > VERSION

# For bug fix (patch bump)
echo "1.0.1" > VERSION

# For breaking change (major bump)
echo "2.0.0" > VERSION

# For prerelease
echo "1.1.0-beta.1" > VERSION
```

### Step 2: Commit and Push

```bash
git add VERSION
git commit -m "chore: Bump version to 1.1.0"
git push origin main
```

### Step 3: Automatic Processing

Two workflows trigger automatically:

**1. version-tagging.yml**
- Creates Git tag: `v1.1.0`
- Generates release notes
- Creates GitHub Release

**2. deploy.yml**
- Builds Docker image with version `1.1.0-abc1234`
- Pushes to Docker Hub
- Deploys to server
- Marks deployment in Datadog

**Result**:
- ✅ Git tag: `v1.1.0`
- ✅ GitHub Release with notes
- ✅ Docker images: `latest`, `1.1.0-abc1234`, `abc1234`
- ✅ Deployed application with version `1.1.0-abc1234`
- ✅ Datadog tracking with correct version

## Commit SHA Purpose

The commit SHA ensures **unique version tracking** even if you forget to increment the VERSION file:

**Scenario Without SHA**:
```
Deploy 1: VERSION=1.0.0 → Docker tag: 1.0.0
Deploy 2: VERSION=1.0.0 (forgot to increment) → Docker tag: 1.0.0 (OVERWRITES!)
```

**Scenario With SHA** (current implementation):
```
Deploy 1: VERSION=1.0.0, SHA=abc1234 → Docker tag: 1.0.0-abc1234
Deploy 2: VERSION=1.0.0 (forgot to increment), SHA=def5678 → Docker tag: 1.0.0-def5678
Result: Both versions preserved, uniquely identified
```

**Benefits**:
- ✅ Every build has unique identifier
- ✅ Traceability to exact commit
- ✅ Prevents accidental overwrites
- ✅ Easy rollback to specific commits
- ✅ Correlates errors with exact code state

## Environment Variables

### VITE_RELEASE

**DO NOT SET MANUALLY** - Automatically injected

**Local**: Set by `vite.config.js` plugin
- Reads: `VERSION` file
- Appends: `git rev-parse --short HEAD`
- Result: `1.0.0-abc1234`

**Production**: Set by `deploy.yml` workflow
- Reads: `VERSION` file
- Appends: GitHub commit SHA
- Result: `1.0.0-def5678`

**Fallback Behavior**:
- VERSION file missing → `unknown`
- Git not available → `VERSION-local`
- Both missing → `unknown-local`

### DD_VERSION

**Not currently used** - React frontend only uses VITE_RELEASE

If backend services are added later:
- Set `DD_VERSION` to match `VITE_RELEASE`
- Used by Datadog APM for backend tracing
- Ensures version consistency across frontend/backend

## Validation

### Check Current Version

**Local Development**:
```bash
# Start dev server and check console output
npm run dev
# Look for: 📦 Version injection: 1.0.0-abc1234 (from VERSION file + git)

# Or check at runtime in browser console
console.log(import.meta.env.VITE_RELEASE)
```

**Production**:
```bash
# Check Docker container environment
docker exec demo-gallery env | grep VITE_RELEASE

# Check Datadog RUM
# Navigate to Datadog → RUM → Explorer
# Look for version field in events
```

### Verify Version Consistency

```bash
# 1. Check VERSION file
cat VERSION
# Output: 1.0.0

# 2. Check current git SHA
git rev-parse --short HEAD
# Output: abc1234

# 3. Expected VITE_RELEASE
echo "$(cat VERSION)-$(git rev-parse --short HEAD)"
# Output: 1.0.0-abc1234

# 4. Verify in running application
npm run dev
# Check console for: 📦 Version injection: 1.0.0-abc1234
```

## Troubleshooting

### "unknown-local" Version

**Cause**: VERSION file or git not found

**Fix**:
```bash
# 1. Verify VERSION file exists
ls -la VERSION

# 2. Verify git is initialized
git status

# 3. If missing, create VERSION file
echo "1.0.0" > VERSION
git add VERSION
git commit -m "chore: Add VERSION file"
```

### Version Not Updating

**Cause**: Vite dev server cached

**Fix**:
```bash
# Restart dev server
# Press Ctrl+C to stop
npm run dev
```

### Production Version Mismatch

**Cause**: Deploy workflow not using latest VERSION

**Fix**:
```bash
# 1. Verify VERSION file committed
git add VERSION
git commit -m "chore: Update version"
git push origin main

# 2. Check workflow run
gh run list --workflow=deploy.yml

# 3. Verify deployment used correct version
gh run view <run-id> --log | grep "Version from file"
```

### Git SHA Shows "local"

**Cause**: Git not available in build environment

**Expected**: Only in Docker builds without git
**Fix**: Not needed - "local" is acceptable for containerized builds
**Production**: Always has proper SHA from GitHub Actions

## Best Practices

### Version Bumping

**Always update VERSION file** when:
- ✅ Adding new features
- ✅ Fixing bugs
- ✅ Making breaking changes
- ✅ Creating releases

**Follow semantic versioning**:
- ✅ Major: Breaking changes (1.x.x → 2.0.0)
- ✅ Minor: New features (1.0.x → 1.1.0)
- ✅ Patch: Bug fixes (1.0.0 → 1.0.1)

**Commit message format**:
```bash
git commit -m "chore: Bump version to X.Y.Z"
```

### Version Verification

**Before deploying**:
1. ✅ Check VERSION file is updated
2. ✅ Verify changes are committed
3. ✅ Test locally with new version
4. ✅ Verify version appears correctly in app

**After deploying**:
1. ✅ Check GitHub Release was created
2. ✅ Verify Docker images have correct tags
3. ✅ Confirm Datadog shows new version
4. ✅ Test application functionality

### Rollback

If a deployment fails:

**Option 1: Revert VERSION**
```bash
git revert HEAD
git push origin main
# Triggers new deployment with previous version
```

**Option 2: Deploy Specific Version**
```bash
# Deploy specific Docker image
docker pull your-username/demo-gallery:1.0.0-abc1234
docker run -d --name demo-gallery -p 8080:80 \
  --env-file .env \
  your-username/demo-gallery:1.0.0-abc1234
```

## Migration from Manual Versions

Previously, versions were defined in three places:
1. ❌ VERSION file (1.0.0)
2. ❌ .env VITE_RELEASE (2.0.1)
3. ❌ .env DD_VERSION (2.0.1)

Now, version is defined in ONE place:
1. ✅ VERSION file (single source of truth)
2. ✅ Auto-injected everywhere else

**Migration steps completed**:
- ✅ Created `versionInjectionPlugin()` in vite.config.js
- ✅ Removed `VITE_RELEASE` from .env
- ✅ Removed `DD_VERSION` from .env
- ✅ Updated .env.example with documentation
- ✅ Production deployment already using VERSION file

**Benefits**:
- ✅ No manual version maintenance
- ✅ Prevents version drift
- ✅ Automatic across all environments
- ✅ Commit SHA ensures uniqueness

## Related Documentation

- **DEPLOYMENT.md** - Complete deployment guide with version management section
- **DOCKER.md** - Docker configuration and environment variables
- **.github/workflows/README.md** - GitHub Actions workflow documentation
- **.github/workflows/version-tagging.yml** - Automated release creation
- **.github/workflows/deploy.yml** - Deployment with version injection

## Quick Reference

```bash
# Update version
echo "1.1.0" > VERSION

# Commit and deploy
git add VERSION
git commit -m "chore: Bump version to 1.1.0"
git push origin main

# Check local version
npm run dev
# Look for: 📦 Version injection: 1.1.0-abc1234

# Check production version
docker exec demo-gallery env | grep VITE_RELEASE

# View releases
gh release list
```

## Summary

**Single Source of Truth**: VERSION file
**Automatic Injection**: Vite plugin (local) + GitHub Actions (production)
**Format**: VERSION-SHA (e.g., 1.0.0-abc1234)
**Benefits**: No manual maintenance, prevents drift, ensures uniqueness
**Result**: Consistent versioning across all environments and tools
