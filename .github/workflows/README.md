# GitHub Actions Workflows

This directory contains the CI/CD workflows for the React Gallery project.

## Workflows Overview

### 1. deploy.yml - Main Deployment Workflow

**Triggers**:
- Push to `main` branch (any files)
- Manual workflow dispatch with options

**Purpose**: Builds Docker image and deploys to production server

**Steps**:
1. Checkout code with full history
2. Install Datadog CI
3. Read VERSION file and create deployment version (`VERSION-SHA`)
4. Run SonarQube code analysis
5. Build Docker image with git metadata
6. Push to Docker Hub with three tags:
   - `latest`
   - `VERSION-SHA` (e.g., `1.0.0-abc1234`)
   - `SHA` (e.g., `abc1234`)
7. Deploy container to Ubuntu server on port 8080
8. Run health checks
9. Mark deployment in Datadog

**Runner**: Self-hosted (containerized runner on Ubuntu server)

**Manual Options**:
- `skip_build`: Skip Docker build (use existing image)
- `skip_deploy`: Build only, don't deploy

### 2. version-tagging.yml - Version Release Workflow

**Triggers**:
- Push to `main` branch when `VERSION` file changes

**Purpose**: Creates Git tags and GitHub Releases for semantic versioning

**Steps**:
1. Checkout code with full history
2. Read and validate VERSION file (semver format)
3. Check if tag already exists (duplicate prevention)
4. Generate release notes from commit history
5. Create annotated Git tag (`v{VERSION}`)
6. Push tag to origin
7. Create GitHub Release with generated notes

**Runner**: GitHub-hosted (`ubuntu-latest`)

**Validation**:
- VERSION file must exist and not be empty
- Must match semantic version format: `MAJOR.MINOR.PATCH` or `MAJOR.MINOR.PATCH-prerelease`
- Examples: `1.0.0`, `2.1.3`, `1.0.0-beta.1`

## Workflow Coordination

### Trigger Relationship

```
User Action: Update VERSION file and push to main
│
├─> version-tagging.yml (triggered by VERSION file change)
│   ├─ Validates version format
│   ├─ Creates Git tag (v1.0.0)
│   ├─ Generates release notes
│   └─ Creates GitHub Release
│
└─> deploy.yml (triggered by push to main)
    ├─ Reads VERSION file (1.0.0)
    ├─ Appends commit SHA (1.0.0-abc1234)
    ├─ Builds Docker image
    ├─ Pushes to Docker Hub
    └─ Deploys to server

Result:
- Git tag: v1.0.0
- GitHub Release: Release v1.0.0
- Docker images: latest, 1.0.0-abc1234, abc1234
- Deployed application with version 1.0.0-abc1234
```

### Workflow Execution Order

Both workflows trigger **simultaneously** when VERSION file is pushed to main:

1. **Parallel execution**: Both workflows start at the same time
2. **No conflicts**: They operate on different resources:
   - `version-tagging.yml`: Creates Git tags and GitHub Releases
   - `deploy.yml`: Builds and deploys Docker containers
3. **Independent completion**: Each workflow completes independently

### Typical Version Release Flow

```bash
# Step 1: Update VERSION file
echo "1.1.0" > VERSION

# Step 2: Commit and push
git add VERSION
git commit -m "chore: Bump version to 1.1.0"
git push origin main

# Step 3: Automatic processing (parallel)
# ├─ version-tagging.yml: Creates v1.1.0 tag and release
# └─ deploy.yml: Builds and deploys 1.1.0-abc1234

# Step 4: Results available
# ├─ Git tag: v1.1.0
# ├─ GitHub Release: https://github.com/USER/demo-gallery/releases/tag/v1.1.0
# ├─ Docker images: latest, 1.1.0-abc1234, abc1234
# └─ Live deployment: http://server:8080
```

## Version Management

### Dual-Versioning Approach

**1. Semantic Versioning** (managed by `version-tagging.yml`):
- Clean release markers: `v1.0.0`, `v1.1.0`, `v2.0.0`
- GitHub Releases with release notes
- Git tags for version history
- Human-readable milestone tracking

**2. Deployment Versioning** (managed by `deploy.yml`):
- Deployment tracking: `1.0.0-abc1234`
- Exact commit traceability
- Docker image identification
- Debugging and rollback support

### VERSION File Format

The `VERSION` file at project root contains only the semantic version:

```
1.0.0
```

**Valid formats**:
- `1.0.0` - Standard release
- `1.2.3` - Release with features and fixes
- `2.0.0-beta.1` - Prerelease version
- `1.0.0-rc.2` - Release candidate

**Invalid formats**:
- `v1.0.0` - No 'v' prefix
- `1.0` - Incomplete version
- `1.0.0.0` - Too many components

### Release Notes Generation

The `version-tagging.yml` workflow automatically generates release notes:

**First Release**:
```markdown
## Release v1.0.0

Initial release of React Gallery

### Changes
- Add image upload functionality (abc1234)
- Implement gallery grid layout (def5678)
- Add Datadog RUM integration (ghi9012)
...
```

**Subsequent Releases**:
```markdown
## Release v1.1.0

Changes since v1.0.0

### Changes
- Add user authentication (jkl3456)
- Improve upload performance (mno7890)
- Fix navigation bug (pqr1234)
...
```

## Troubleshooting

### "Tag already exists" Warning

**Cause**: The VERSION value has already been tagged

**Resolution**:
1. Check existing tags: `git tag`
2. Update VERSION to a new value
3. Or delete the existing tag if intentional:
   ```bash
   git tag -d v1.0.0
   git push origin :refs/tags/v1.0.0
   gh release delete v1.0.0 -y
   ```

### "Invalid version format" Error

**Cause**: VERSION file doesn't match semantic versioning format

**Resolution**:
```bash
# Ensure VERSION file contains valid semver
echo "1.0.0" > VERSION  # Valid
echo "v1.0.0" > VERSION  # Invalid - no 'v' prefix
echo "1.0" > VERSION     # Invalid - incomplete
```

### Workflows Not Triggering

**Cause**: Various permission or configuration issues

**Check**:
1. **Branch name**: Workflows only trigger on `main` branch
   ```bash
   git branch --show-current  # Should show "main"
   ```

2. **File path**: `version-tagging.yml` only triggers on VERSION file changes
   ```bash
   git diff --name-only HEAD~1  # Should include "VERSION"
   ```

3. **Workflow permissions**: Check repository Settings → Actions → General
   - Workflow permissions: "Read and write permissions"
   - Allow GitHub Actions to create pull requests: Enabled

4. **Runner availability** (for deploy.yml):
   ```bash
   # Check self-hosted runner status
   # Settings → Actions → Runners
   ```

### GitHub Release Creation Failed

**Cause**: Insufficient permissions or GitHub API issues

**Resolution**:
1. Check workflow permissions (see above)
2. Verify GitHub token has `contents: write` permission
3. Check GitHub status: https://www.githubstatus.com/

### Both Workflows Run But Only Need One

**Situation**: Normal operation - this is expected behavior

**Explanation**:
- VERSION file change triggers both workflows
- `version-tagging.yml`: Creates release metadata
- `deploy.yml`: Deploys the application
- Both are needed for a complete release

**If you only want tagging without deployment**:
```bash
# Use deploy.yml manual trigger with skip_deploy
# Settings → Actions → deploy.yml → Run workflow
# Select: skip_deploy = true
```

## Monitoring Workflows

### GitHub UI

**View all workflow runs**:
```
https://github.com/YOUR_USERNAME/demo-gallery/actions
```

**View specific workflow**:
```
https://github.com/YOUR_USERNAME/demo-gallery/actions/workflows/deploy.yml
https://github.com/YOUR_USERNAME/demo-gallery/actions/workflows/version-tagging.yml
```

### GitHub CLI

```bash
# List recent runs
gh run list

# List runs for specific workflow
gh run list --workflow=deploy.yml
gh run list --workflow=version-tagging.yml

# Watch latest run
gh run watch

# View run details
gh run view <run-id>

# View run logs
gh run view <run-id> --log
```

### Workflow Status Badges

Add to README.md:

```markdown
![Deploy](https://github.com/YOUR_USERNAME/demo-gallery/actions/workflows/deploy.yml/badge.svg)
![Version](https://github.com/YOUR_USERNAME/demo-gallery/actions/workflows/version-tagging.yml/badge.svg)
```

## Best Practices

### Version Bumping

**Before releasing**:
1. Ensure all changes are committed
2. Update VERSION file with appropriate semver bump
3. Use descriptive commit message
4. Verify workflows complete successfully

**Commit message convention**:
```bash
git commit -m "chore: Bump version to 1.1.0"  # Version bump
git commit -m "feat: Add user authentication"  # Feature
git commit -m "fix: Resolve upload error"      # Bug fix
git commit -m "docs: Update deployment guide"  # Documentation
```

### Testing Workflows

**Local validation** (before pushing):
```bash
# Validate VERSION format
cat VERSION | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'

# Check if tag exists
git tag | grep "v$(cat VERSION)"

# Test Docker build locally
docker build -t demo-gallery:test .
```

**Manual workflow testing**:
1. Go to Actions → deploy.yml → Run workflow
2. Select options (skip_build, skip_deploy)
3. Monitor execution
4. Validate results

### Rollback Procedures

**Revert version bump**:
```bash
# Option 1: Git revert (recommended)
git revert HEAD
git push origin main

# Option 2: Manual VERSION update
echo "1.0.0" > VERSION
git add VERSION
git commit -m "chore: Rollback to v1.0.0"
git push origin main
```

**Deploy specific version**:
```bash
# SSH to server and deploy specific image
ssh your-server
docker pull your-username/demo-gallery:1.0.0-abc1234
docker stop demo-gallery && docker rm demo-gallery
docker run -d --name demo-gallery -p 8080:80 \
  --env-file .env \
  your-username/demo-gallery:1.0.0-abc1234
```

## Security Considerations

### Secrets Management

**Required secrets** (Settings → Secrets → Actions):
- `DOCKERHUB_USER` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token
- `VITE_*` - Application environment variables
- `DD_API_KEY`, `DD_APP_KEY` - Datadog (optional)
- `SONAR_TOKEN`, `SONAR_HOST_URL` - SonarQube (optional)

**Secret rotation**:
1. Generate new token/key
2. Update in GitHub Secrets
3. Test with manual workflow run
4. Invalidate old token/key

### Workflow Permissions

Both workflows have minimal required permissions:

**version-tagging.yml**:
```yaml
permissions:
  contents: write  # Required for creating tags and releases
```

**deploy.yml**:
```yaml
# Uses default permissions
# Self-hosted runner has Docker access via socket mount
```

### Runner Security

**Self-hosted runner** (deploy.yml):
- Runs in isolated container
- Docker socket mounted for builds
- No direct access to secrets (injected at runtime)

**GitHub-hosted runner** (version-tagging.yml):
- Ephemeral environment
- Automatic cleanup after run
- No persistent state

## Additional Resources

- **Deployment Guide**: See `DEPLOYMENT.md` for complete deployment documentation
- **Docker Guide**: See `DOCKER.md` for Docker configuration details
- **GitHub Actions**: https://docs.github.com/en/actions
- **Semantic Versioning**: https://semver.org/
- **GitHub Releases**: https://docs.github.com/en/repositories/releasing-projects-on-github
