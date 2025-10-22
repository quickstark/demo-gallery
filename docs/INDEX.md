# Documentation Index

Complete documentation for the Demo Gallery project.

## 📚 Quick Navigation

### Getting Started
- **[README.md](../README.md)** - Project overview and quick start
- **[Quick Start Guide](#quick-start-guide)** - 5-minute setup
- **[Environment Setup](#environment-setup)** - Configuration guide

### Core Documentation
- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Complete deployment guide
- **[DOCKER.md](../DOCKER.md)** - Docker configuration
- **[VERSION_MANAGEMENT.md](../VERSION_MANAGEMENT.md)** - Version management

### GitHub Actions & CI/CD
- **[Workflows Overview](../.github/workflows/README.md)** - All workflows
- **[Deployment Workflow](../.github/workflows/deploy.yml)** - Main CI/CD pipeline
- **[Version Tagging](../.github/workflows/version-tagging.yml)** - Auto-tagging
- **[Runner Troubleshooting](../.github/RUNNER_TROUBLESHOOTING.md)** - Fix runner issues

### Technical Documentation
- **[Datadog Integration](#datadog-integration)** - Monitoring setup
- **[Version Consolidation](../.github/VERSION_CONSOLIDATION.md)** - Version architecture
- **[Deployment Comparison](../.github/DATADOG_DEPLOYMENT_COMPARISON.md)** - FastAPI vs React
- **[Infrastructure Cleanup](../.github/DEPLOYMENT_CLEANUP.md)** - Migration notes

### Operational Guides
- **[Workflow Status](../.github/WORKFLOW_STATUS.md)** - Current status
- **[Runner Restart Guide](../scripts/restart-runner.sh)** - Maintenance script
- **[Secrets Setup](../scripts/setup-github-secrets.sh)** - Configure secrets
- **[Deploy Script](../scripts/deploy-github.sh)** - Deployment orchestration

## 📖 Documentation by Topic

### Architecture & Design

#### Application Architecture
```
React 18 + Vite 6
    ↓
Chakra UI 3 + Framer Motion
    ↓
Axios + React Router
    ↓
Datadog RUM + Logs + APM
```

**Key Files**:
- `src/App.jsx` - Main application component with Datadog init
- `src/main.jsx` - Entry point
- `vite.config.js` - Build configuration with version plugin
- `package.json` - Dependencies and scripts

**Documentation**:
- [README.md - Architecture](../README.md#architecture)
- [Application Structure](../README.md#application-structure)
- [Technology Stack](../README.md#technology-stack)

#### Docker Architecture
```
Multi-stage Build:
  Stage 1: node:20-alpine (builder)
    ├─ Install dependencies
    ├─ Build with Vite
    └─ Generate dist/

  Stage 2: nginx:alpine (runtime)
    ├─ Copy dist/ files
    ├─ Runtime env injection
    └─ Health checks
```

**Key Files**:
- `Dockerfile` - Multi-stage build configuration
- `docker/nginx.conf` - Web server configuration
- `docker/entrypoint.sh` - Runtime environment injection
- `docker-compose.yml` - Local testing setup

**Documentation**:
- [DOCKER.md](../DOCKER.md) - Complete Docker guide
- [README.md - Docker Quick Start](../README.md#docker-quick-start)

#### Version Management Architecture
```
VERSION file (1.0.2) ← Single source of truth
    ↓
vite.config.js (versionInjectionPlugin)
    ├─ Read VERSION file
    ├─ Get git SHA (abc1234)
    └─ Create VITE_RELEASE="1.0.2-abc1234"
    ↓
Automatic Injection:
    ├─ Local dev: import.meta.env.VITE_RELEASE
    ├─ Production: Container env var
    └─ Datadog: version tracking
```

**Key Files**:
- `VERSION` - Semantic version (1.0.2)
- `vite.config.js:11-52` - Version injection plugin
- `.env.example:16-20` - Version management comments

**Documentation**:
- [VERSION_MANAGEMENT.md](../VERSION_MANAGEMENT.md) - Complete guide
- [VERSION_CONSOLIDATION.md](../.github/VERSION_CONSOLIDATION.md) - Technical details

### Deployment & Operations

#### Automated Deployment Flow
```
git push origin main
    ↓
GitHub Actions (Self-Hosted Runner)
    ├─ Read VERSION file
    ├─ Append commit SHA
    ├─ Install Datadog CI
    ├─ Run SonarQube analysis
    ├─ Build Docker image
    ├─ Tag: latest, VERSION-SHA, SHA
    ├─ Push to Docker Hub
    ├─ Deploy to Ubuntu:8080
    ├─ Health check validation
    └─ Mark deployment in Datadog
```

**Key Files**:
- `.github/workflows/deploy.yml` - Main deployment workflow
- `.github/workflows/version-tagging.yml` - Version automation
- `scripts/deploy-github.sh` - Orchestration script
- `scripts/setup-github-secrets.sh` - Secrets management

**Documentation**:
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Complete deployment guide
- [README.md - Deployment](../README.md#deployment)
- [Workflows README](../.github/workflows/README.md) - Workflow details

#### Manual Deployment
```
./scripts/deploy-github.sh
    ├─ Validate environment
    ├─ Upload GitHub Secrets
    ├─ Commit changes
    ├─ Push to origin
    └─ Monitor workflow
```

**Documentation**:
- [DEPLOYMENT.md - Manual Deployment](../DEPLOYMENT.md#manual-deployment)
- [deploy-github.sh](../scripts/deploy-github.sh) - Script with inline docs

#### Emergency Deployment
```
./deploy.sh
    ├─ Pull Docker image
    ├─ Stop existing container
    ├─ Start new container
    └─ Health check
```

**Documentation**:
- [deploy.sh](../deploy.sh) - Emergency backup script
- [DEPLOYMENT.md - Emergency Deployment](../DEPLOYMENT.md#emergency-deployment)

### Monitoring & Observability

#### Datadog Integration
```
Datadog RUM (Real User Monitoring)
    ├─ Session replay (100%)
    ├─ User interactions
    ├─ Resource monitoring
    ├─ Long task tracking
    └─ Custom context

Datadog Logs
    ├─ Structured logging
    ├─ Error forwarding
    ├─ Custom log levels
    └─ Feature tagging

Datadog APM
    ├─ Network tracing
    ├─ Distributed traces
    ├─ Payload capture
    └─ Trace correlation

Deployment Tracking
    ├─ CD Visibility markers
    ├─ Version tracking
    ├─ Git metadata
    └─ Method tagging
```

**Key Files**:
- `src/App.jsx:29-72` - Datadog RUM initialization
- `src/App.jsx:60-69` - Datadog Logs initialization
- `.github/workflows/deploy.yml:344-403` - Deployment marking
- `.github/workflows/deploy.yml:29-84` - Datadog CI installation

**Documentation**:
- [README.md - Monitoring](../README.md#monitoring)
- [DATADOG_DEPLOYMENT_COMPARISON.md](../.github/DATADOG_DEPLOYMENT_COMPARISON.md)
- [Datadog RUM Docs](https://docs.datadoghq.com/real_user_monitoring/)

#### Health Checks
```
Container Health Check (every 30s):
  wget http://127.0.0.1:80/ || exit 1

Application Health Endpoints:
  - /health (Nginx health)
  - / (Application root)

Monitoring:
  - Docker ps status
  - Datadog RUM dashboard
  - GitHub Actions status
```

**Documentation**:
- [DOCKER.md - Health Checks](../DOCKER.md#health-checks)
- [README.md - Health Checks](../README.md#health-checks)

### Development

#### Development Workflow
```
1. Create feature branch
2. yarn dev (local testing)
3. yarn lint (code quality)
4. yarn build (production test)
5. git commit -m "feat: ..."
6. git push origin feature/...
7. Create Pull Request
8. CI checks (SonarQube, linting)
9. Merge to main
10. Auto-deploy via GitHub Actions
```

**Available Scripts**:
- `yarn dev` - Start dev server (localhost:5173)
- `yarn build` - Build for production
- `yarn preview` - Preview production build
- `yarn lint` - Run ESLint
- `yarn lint:fix` - Fix ESLint issues

**Documentation**:
- [README.md - Development](../README.md#development)
- [README.md - Available Scripts](../README.md#available-scripts)
- [README.md - Development Workflow](../README.md#development-workflow)

#### Environment Configuration
```
Required Variables:
  VITE_API_URL              (Backend API)
  VITE_ENVIRONMENT          (dev/prod)
  VITE_DATADOG_APPLICATION_ID
  VITE_DATADOG_CLIENT_TOKEN

Optional Variables:
  VITE_API_KEY
  VITE_AUTH_USERNAME
  VITE_AUTH_PASSWORD

Auto-Injected:
  VITE_RELEASE              (VERSION-SHA)
```

**Key Files**:
- `.env.example` - Environment template
- `vite.config.js:11-52` - Version injection
- `docker/entrypoint.sh` - Runtime injection

**Documentation**:
- [README.md - Environment Variables](../README.md#environment-variables)
- [DEPLOYMENT.md - Environment Configuration](../DEPLOYMENT.md#environment-configuration)

### Troubleshooting

#### Runner Issues
**Symptoms**: Workflows stuck in "Queued" status

**Solution**:
```bash
./scripts/restart-runner.sh
```

**Documentation**:
- [RUNNER_TROUBLESHOOTING.md](../.github/RUNNER_TROUBLESHOOTING.md) - Complete guide
- [WORKFLOW_STATUS.md](../.github/WORKFLOW_STATUS.md) - Status summary
- [restart-runner.sh](../scripts/restart-runner.sh) - Automated fix

#### Docker Issues
**Common Problems**:
- Container won't start
- Environment variables not applied
- Build failures
- Health check failures

**Documentation**:
- [DOCKER.md - Troubleshooting](../DOCKER.md#troubleshooting)

#### Deployment Issues
**Common Problems**:
- Workflow failures
- Docker push errors
- Deployment timeouts
- Health check failures

**Documentation**:
- [DEPLOYMENT.md - Troubleshooting](../DEPLOYMENT.md#troubleshooting)
- [RUNNER_TROUBLESHOOTING.md](../.github/RUNNER_TROUBLESHOOTING.md)

## 🔍 Documentation Search

### By Component

**Frontend Components**:
- Home.jsx - Main gallery view
- Form.jsx - Image upload form
- About.jsx - About page
- Navigation.jsx - Navigation bar
- Modal_Info.jsx - Image modal
- Error.jsx - Error page
- ErrorBoundary.jsx - Error boundary
- Context.jsx - Environment context
- RumViewTracker.jsx - Datadog RUM integration

**Infrastructure**:
- Dockerfile - Multi-stage build
- docker/nginx.conf - Web server config
- docker/entrypoint.sh - Runtime injection
- docker-compose.yml - Local testing

**CI/CD**:
- .github/workflows/deploy.yml - Main deployment
- .github/workflows/version-tagging.yml - Version automation
- scripts/deploy-github.sh - Orchestration
- scripts/setup-github-secrets.sh - Secrets

**Configuration**:
- vite.config.js - Build config
- package.json - Dependencies
- .env.example - Environment template
- VERSION - Semantic version

### By Task

**I want to...**

...deploy the application:
→ [DEPLOYMENT.md](../DEPLOYMENT.md)

...run locally:
→ [README.md - Quick Start](../README.md#quick-start)

...use Docker:
→ [DOCKER.md](../DOCKER.md)

...understand versioning:
→ [VERSION_MANAGEMENT.md](../VERSION_MANAGEMENT.md)

...fix runner issues:
→ [RUNNER_TROUBLESHOOTING.md](../.github/RUNNER_TROUBLESHOOTING.md)

...configure monitoring:
→ [README.md - Monitoring](../README.md#monitoring)

...contribute code:
→ [README.md - Contributing](../README.md#contributing)

...set up CI/CD:
→ [Workflows README](../.github/workflows/README.md)

## 📋 Quick Reference

### Deployment Checklist
- [ ] Update VERSION file
- [ ] Commit changes
- [ ] Push to main branch
- [ ] Monitor GitHub Actions
- [ ] Verify deployment health
- [ ] Check Datadog RUM

### Configuration Checklist
- [ ] Copy .env.example to .env
- [ ] Set VITE_API_URL
- [ ] Configure Datadog credentials
- [ ] Test locally with yarn dev
- [ ] Build for production
- [ ] Verify version injection

### Troubleshooting Checklist
- [ ] Check GitHub Actions status
- [ ] Verify runner is online
- [ ] Review container logs
- [ ] Test health endpoint
- [ ] Check Datadog dashboard
- [ ] Validate environment variables

## 🔗 External Resources

**React & Vite**:
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)
- [Chakra UI Docs](https://chakra-ui.com/)

**Datadog**:
- [Datadog RUM](https://docs.datadoghq.com/real_user_monitoring/)
- [Datadog Logs](https://docs.datadoghq.com/logs/)
- [Datadog APM](https://docs.datadoghq.com/tracing/)

**Docker**:
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)

**GitHub Actions**:
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)

## 📅 Documentation Updates

**Last Updated**: 2025-10-22
**Version**: 1.0.2

**Recent Changes**:
- ✅ Comprehensive README.md rewrite
- ✅ Documentation index created
- ✅ All docs organized and cross-referenced
- ✅ Quick navigation added
- ✅ Troubleshooting guides enhanced

---

**Need help?** Check the [README.md](../README.md) first, then explore topic-specific docs above.
