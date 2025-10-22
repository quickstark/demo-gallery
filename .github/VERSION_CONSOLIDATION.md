# Version Management Consolidation

**Date**: 2025-10-22
**Change Type**: Architecture Improvement
**Impact**: All environments (development, production, Docker)

## Problem Statement

Version information was defined in **three separate places**, causing inconsistency and manual maintenance burden:

1. `VERSION` file: `1.0.0`
2. `.env` VITE_RELEASE: `2.0.1`
3. `.env` DD_VERSION: `2.0.1`

**Issues**:
- ❌ Version drift between files (1.0.0 vs 2.0.1)
- ❌ Manual maintenance required in multiple locations
- ❌ Risk of forgetting to update all places
- ❌ Inconsistent versions between local dev and production
- ❌ No guarantee of uniqueness if VERSION not incremented

## Solution Implemented

**Centralized Version Management** with `VERSION` file as single source of truth:

### Architecture

```
VERSION file (1.0.0)
    ↓
    ├─ Local Development (Vite Plugin)
    │   ├─ Reads VERSION file
    │   ├─ Gets git SHA
    │   └─ Auto-injects: VITE_RELEASE="1.0.0-abc1234"
    │
    └─ Production (GitHub Actions)
        ├─ Reads VERSION file
        ├─ Gets commit SHA
        ├─ Auto-injects: VITE_RELEASE="1.0.0-def5678"
        └─ Creates Docker tags:
            ├─ latest
            ├─ 1.0.0-def5678
            └─ def5678
```

### Key Changes

#### 1. Created Vite Plugin (`vite.config.js`)

```javascript
function versionInjectionPlugin() {
  return {
    name: 'version-injection',
    config: () => {
      const version = fs.readFileSync('VERSION', 'utf-8').trim();
      const gitSha = execSync('git rev-parse --short HEAD').toString().trim();
      const release = `${version}-${gitSha}`;

      return {
        define: {
          'import.meta.env.VITE_RELEASE': JSON.stringify(release)
        }
      };
    }
  };
}
```

**Benefits**:
- ✅ Automatic in all builds (dev and prod)
- ✅ No manual configuration needed
- ✅ Consistent across environments
- ✅ Includes commit SHA for uniqueness

#### 2. Updated `.env` and `.env.example`

**Removed**:
```bash
VITE_RELEASE=2.0.1  # Removed - auto-injected
DD_VERSION=2.0.1     # Removed - not needed for frontend
```

**Added**:
```bash
# VITE_RELEASE is automatically injected from VERSION file + git SHA
# Managed by vite.config.js versionInjectionPlugin()
# Format: VERSION-SHA (e.g., 1.0.0-abc1234)
# Do not set VITE_RELEASE manually - edit VERSION file instead
```

#### 3. Production Unchanged

GitHub Actions (`deploy.yml`) already implements the correct pattern:
```yaml
- name: Read VERSION
  run: |
    BASE_VERSION=$(cat VERSION)
    SHORT_SHA="${{ github.sha }}"
    SHORT_SHA="${SHORT_SHA:0:7}"
    VERSION="${BASE_VERSION}-${SHORT_SHA}"

# Later used
-e VITE_RELEASE="${{ steps.version.outputs.version }}"
```

**No changes needed** - already using VERSION file + commit SHA!

#### 4. Created Documentation

**New Files**:
- `VERSION_MANAGEMENT.md` - Complete version management guide
- `.github/VERSION_CONSOLIDATION.md` - This file

**Updated Files**:
- `DEPLOYMENT.md` - Added centralized version management section
- `.env` - Removed manual versions, added comments
- `.env.example` - Updated with version management documentation

## Technical Details

### Commit SHA Inclusion

**Purpose**: Ensures unique releases even if VERSION not incremented

**Without SHA**:
```
Deploy 1: VERSION=1.0.0 → Tag: 1.0.0 (overwrites previous)
Deploy 2: VERSION=1.0.0 (forgot to increment) → Tag: 1.0.0 (OVERWRITES!)
```

**With SHA** (current):
```
Deploy 1: VERSION=1.0.0, SHA=abc1234 → Tag: 1.0.0-abc1234 (unique)
Deploy 2: VERSION=1.0.0, SHA=def5678 → Tag: 1.0.0-def5678 (unique)
```

**Benefits**:
- ✅ Every build uniquely identified
- ✅ Exact traceability to source code
- ✅ Prevents accidental overwrites
- ✅ Easy rollback to specific commits
- ✅ Correlates errors with exact code state

### Environment Variable Flow

**Development**:
```
VERSION file (1.0.0)
    ↓ vite.config.js versionInjectionPlugin()
    ↓ + git SHA (abc1234)
    ↓
VITE_RELEASE="1.0.0-abc1234"
    ↓ import.meta.env.VITE_RELEASE
    ↓ src/App.jsx
    ↓
datadogRum.init({ version: "1.0.0-abc1234" })
```

**Production**:
```
VERSION file (1.0.0)
    ↓ deploy.yml workflow
    ↓ + GitHub SHA (def5678)
    ↓
VITE_RELEASE="1.0.0-def5678" (container env var)
    ↓ Runtime injection by entrypoint.sh
    ↓ Browser: import.meta.env.VITE_RELEASE
    ↓
datadogRum.init({ version: "1.0.0-def5678" })
```

### Fallback Behavior

**Git Not Available**:
```javascript
// vite.config.js handles gracefully
try {
  gitSha = execSync('git rev-parse --short HEAD').toString().trim();
} catch (err) {
  console.warn('⚠️  Git not available, using "local"');
  gitSha = 'local';
}
// Result: "1.0.0-local"
```

**VERSION File Missing**:
```javascript
if (fs.existsSync(versionFile)) {
  version = fs.readFileSync(versionFile, 'utf-8').trim();
} else {
  console.warn('⚠️  VERSION file not found, using "unknown"');
  version = 'unknown';
}
// Result: "unknown-local"
```

## Migration Path

### Before

```bash
# .env
VITE_RELEASE=2.0.1  # Manually maintained
DD_VERSION=2.0.1     # Manually maintained

# VERSION
1.0.0                # Out of sync!
```

**Problems**:
- Version drift (2.0.1 vs 1.0.0)
- Manual updates required
- Easy to forget

### After

```bash
# .env
# VITE_RELEASE automatically injected (no manual entry)

# VERSION (single source of truth)
1.0.0

# Result: Automatic everywhere
# Local: VITE_RELEASE="1.0.0-abc1234"
# Prod:  VITE_RELEASE="1.0.0-def5678"
```

**Benefits**:
- No version drift possible
- No manual updates
- Automatic consistency

## Testing Validation

### Test 1: Local Development

```bash
# Start dev server
npm run dev

# Expected output:
# 📦 Version injection: 1.0.0-0715c8f (from VERSION file + git)

# Verify in browser console:
console.log(import.meta.env.VITE_RELEASE)
// Output: "1.0.0-0715c8f"
```

### Test 2: Production Build

```bash
# Build for production
npm run build

# Expected output:
# 📦 Version injection: 1.0.0-0715c8f (from VERSION file + git)

# Check dist output
grep -r "1.0.0-0715c8f" dist/
# Should find version in bundled code
```

### Test 3: Docker Build

```bash
# Build Docker image
docker build -t demo-gallery:test .

# Run container
docker run -d --name test -p 8080:80 demo-gallery:test

# Check environment
docker exec test env | grep VITE_RELEASE
# Should see VITE_RELEASE from deploy.yml injection
```

### Test 4: Production Deployment

```bash
# Update VERSION
echo "1.1.0" > VERSION

# Commit and push
git add VERSION
git commit -m "chore: Bump version to 1.1.0"
git push origin main

# Verify workflows
gh run list

# Check deployed version
docker exec demo-gallery env | grep VITE_RELEASE
# Should show: VITE_RELEASE=1.1.0-abc1234

# Check Datadog RUM
# Navigate to Datadog → RUM → Explorer
# Filter by version: 1.1.0-abc1234
```

## Impact Assessment

### Positive Impacts

✅ **Single Source of Truth**
- Only edit VERSION file
- No more manual .env updates
- Prevents version drift

✅ **Automatic Everywhere**
- Local dev: Vite plugin
- Production: GitHub Actions
- Docker: Environment injection

✅ **Unique Tracking**
- Commit SHA appended
- Every build uniquely identified
- Prevents overwrites

✅ **Better Traceability**
- Version → exact commit
- Easy debugging
- Simple rollback

✅ **Less Manual Work**
- No .env maintenance
- Automated consistency
- Fewer human errors

### Breaking Changes

**None** - Backward compatible:
- ✅ Production workflow unchanged
- ✅ Docker deployment unchanged
- ✅ Datadog integration unchanged
- ✅ Only .env files modified (local dev)

### Migration Required

**For Developers**:
1. Pull latest changes
2. Remove `VITE_RELEASE` and `DD_VERSION` from local `.env`
3. Restart dev server
4. Version now auto-injected from VERSION file

**For Production**:
- No changes needed - already implemented correctly

## Rollback Plan

If issues arise, revert these changes:

### Files to Revert

```bash
# Revert vite.config.js
git checkout HEAD~1 -- vite.config.js

# Revert .env changes
git checkout HEAD~1 -- .env .env.example

# Remove new documentation
rm VERSION_MANAGEMENT.md
rm .github/VERSION_CONSOLIDATION.md
```

### Manual Fix

Add back to `.env`:
```bash
VITE_RELEASE=1.0.0
DD_VERSION=1.0.0
```

## Future Considerations

### DD_VERSION Usage

Currently not used (frontend-only app).

**If backend services added**:
```javascript
// Add to vite.config.js
define: {
  'import.meta.env.VITE_RELEASE': JSON.stringify(release),
  'import.meta.env.DD_VERSION': JSON.stringify(release),
}
```

### Version Automation

Consider adding npm scripts:

```json
{
  "scripts": {
    "version:patch": "npm version patch --no-git-tag-version",
    "version:minor": "npm version minor --no-git-tag-version",
    "version:major": "npm version major --no-git-tag-version"
  }
}
```

These would update `package.json` version, which could then sync to VERSION file.

### Build-Time Version Display

Consider adding version to UI footer:

```javascript
// src/components/Footer.jsx
const version = import.meta.env.VITE_RELEASE;

return (
  <footer>
    <small>Version: {version}</small>
  </footer>
);
```

## Documentation

**Primary Documentation**:
- [VERSION_MANAGEMENT.md](../VERSION_MANAGEMENT.md) - Complete guide

**Related Documentation**:
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Deployment guide with version management
- [.github/workflows/README.md](workflows/README.md) - GitHub Actions workflows
- [DOCKER.md](../DOCKER.md) - Docker configuration

## Summary

### Changes Made

✅ Created `versionInjectionPlugin()` in vite.config.js
✅ Removed `VITE_RELEASE` and `DD_VERSION` from .env files
✅ Updated .env.example with version management docs
✅ Created VERSION_MANAGEMENT.md documentation
✅ Updated DEPLOYMENT.md with centralized version section
✅ Validated version injection works correctly

### Result

**Before**: 3 places to manage version (inconsistent)
**After**: 1 place to manage version (VERSION file)

**Format**: `VERSION-SHA` (e.g., `1.0.0-abc1234`)
**Automatic**: Local dev + Production + Docker
**Unique**: Every build has unique identifier
**Traceable**: Version maps to exact commit

### Developer Experience

**Update Version**:
```bash
echo "1.1.0" > VERSION
git add VERSION && git commit -m "chore: Bump version to 1.1.0"
git push origin main
```

**Result**: Automatic everywhere
- ✅ Git tag v1.1.0
- ✅ GitHub Release
- ✅ Docker images 1.1.0-abc1234
- ✅ Deployed with correct version
- ✅ Datadog tracking updated
