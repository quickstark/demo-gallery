# Demo Gallery

> A modern React image gallery application with Datadog RUM integration, Docker deployment, and comprehensive CI/CD automation

[![Version](https://img.shields.io/badge/version-1.0.2-blue.svg)](./VERSION)
[![React](https://img.shields.io/badge/React-18.2-61dafb.svg)](https://reactjs.org/)
[![Vite](https://img.shields.io/badge/Vite-6.2-646cff.svg)](https://vitejs.dev/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ed.svg)](./Dockerfile)

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Development](#development)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Contributing](#contributing)

## 🎯 Overview

Demo Gallery is a production-ready React application that showcases modern web development practices with comprehensive observability, automated deployment, and professional development workflows.

**Built With:**
- **Frontend**: React 18 + Vite 6 + Chakra UI 3
- **Monitoring**: Datadog RUM + Logs + APM
- **Deployment**: Docker + GitHub Actions + Self-Hosted Runners
- **Infrastructure**: Nginx + Multi-stage builds + Health checks

## ✨ Features

### Core Functionality
- 📸 **Image Gallery**: Upload, view, and manage images with compression
- 🎨 **Modern UI**: Responsive design with Chakra UI 3 and Framer Motion
- 🖼️ **Image Processing**: Client-side compression with browser-image-compression
- 🔍 **Image Zoom**: Enhanced viewing with react-medium-image-zoom
- 📱 **Responsive**: Mobile-first design with adaptive layouts

### Observability & Monitoring
- 📊 **Datadog RUM**: Real User Monitoring with session replay
- 📝 **Datadog Logs**: Structured logging with error tracking
- 🔗 **APM Integration**: Distributed tracing with network interception
- 🎯 **Custom Context**: Image processing metadata and user preferences
- 📈 **Performance**: Long task tracking and resource monitoring

### DevOps & Infrastructure
- 🐳 **Docker**: Multi-stage builds with runtime configuration
- 🚀 **CI/CD**: Automated GitHub Actions workflows
- 📦 **Versioning**: Semantic versioning with git SHA tracking
- 🏷️ **Tagging**: Multiple Docker tags (latest, VERSION-SHA, SHA)
- 🔄 **Health Checks**: Built-in container health monitoring
- 📋 **SonarQube**: Code quality and security analysis integration

### Development Experience
- ⚡ **Vite**: Lightning-fast HMR and optimized builds
- 🎨 **Chakra UI**: Component library with theming support
- 🔧 **ESLint**: Code quality and consistency
- 📱 **React Router**: Client-side routing with navigation
- 🎭 **Error Boundaries**: Graceful error handling
- 🔄 **Version Injection**: Automatic version management from VERSION file

## 🚀 Quick Start

### Prerequisites

- **Node.js**: 20.x or higher
- **Yarn**: Package manager (or npm)
- **Docker**: For containerized deployment (optional)
- **Git**: Version control

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/demo-gallery.git
   cd demo-gallery
   ```

2. **Install dependencies**:
   ```bash
   yarn install
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start development server**:
   ```bash
   yarn dev
   ```

   Application will be available at: http://localhost:5173

5. **Build for production**:
   ```bash
   yarn build
   ```

### Docker Quick Start

```bash
# Build the image
docker build -t demo-gallery:latest .

# Run the container
docker run -d \
  --name demo-gallery \
  -p 8080:80 \
  -e VITE_API_URL="http://localhost:8000" \
  -e VITE_ENVIRONMENT="production" \
  -e VITE_DATADOG_APPLICATION_ID="your-app-id" \
  -e VITE_DATADOG_CLIENT_TOKEN="your-token" \
  demo-gallery:latest

# Check health
curl http://localhost:8080/health
```

For detailed Docker instructions, see [DOCKER.md](./DOCKER.md).

## 🏗️ Architecture

### Application Structure

```
demo-gallery/
├── src/
│   ├── components/         # React components
│   │   ├── Home.jsx       # Main gallery view
│   │   ├── Form.jsx       # Image upload form
│   │   ├── About.jsx      # About page
│   │   ├── Navigation.jsx # Navigation bar
│   │   ├── Modal_Info.jsx # Image modal
│   │   ├── Error.jsx      # Error page
│   │   ├── ErrorBoundary.jsx # Error boundary
│   │   ├── Context.jsx    # Environment context
│   │   └── RumViewTracker.jsx # Datadog RUM integration
│   ├── hooks/             # Custom React hooks
│   ├── utils/             # Utility functions
│   ├── App.jsx            # Main application component
│   ├── main.jsx           # Application entry point
│   └── index.css          # Global styles
├── docker/                # Docker configuration
│   ├── nginx.conf        # Nginx web server config
│   └── entrypoint.sh     # Container startup script
├── scripts/              # Deployment scripts
│   ├── deploy-github.sh  # GitHub Actions deployment
│   ├── setup-github-secrets.sh # Secrets management
│   └── restart-runner.sh # Runner maintenance
├── .github/
│   └── workflows/        # CI/CD workflows
│       ├── deploy.yml    # Main deployment workflow
│       └── version-tagging.yml # Version management
├── Dockerfile            # Multi-stage Docker build
├── vite.config.js        # Vite configuration
├── package.json          # Dependencies and scripts
├── VERSION               # Semantic version (1.0.2)
└── .env.example          # Environment variables template
```

### Technology Stack

**Frontend**:
- React 18.2 (UI library)
- Vite 6.2 (Build tool)
- Chakra UI 3.21 (Component library)
- React Router 6.22 (Routing)
- Framer Motion 10.16 (Animations)
- Axios 1.8 (HTTP client)

**Observability**:
- Datadog Browser RUM 6.5
- Datadog Browser Logs 6.5
- Datadog RUM Interceptor (Network tracing)

**Development**:
- ESLint (Linting)
- Playwright 1.53 (E2E testing)
- SonarQube (Code analysis)

**Infrastructure**:
- Docker (Containerization)
- Nginx (Web server)
- GitHub Actions (CI/CD)

### Version Management

The application uses a **centralized version management system**:

1. **Single Source of Truth**: `VERSION` file (1.0.2)
2. **Automatic Injection**: Vite plugin reads VERSION + git SHA
3. **Format**: `VERSION-SHA` (e.g., 1.0.2-abc1234)
4. **Environments**: Works in local dev and production
5. **Tracking**: Unique version for every build/deployment

**Version Flow**:
```
VERSION file (1.0.2)
    ↓
vite.config.js (versionInjectionPlugin)
    ↓
Git SHA (abc1234)
    ↓
VITE_RELEASE="1.0.2-abc1234"
    ↓
Datadog RUM version tracking
```

For complete version management details, see [VERSION_MANAGEMENT.md](./VERSION_MANAGEMENT.md).

## 📚 Documentation

### Core Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide
  - GitHub Actions workflows
  - Manual deployment
  - Environment configuration
  - Deployment validation

- **[DOCKER.md](./DOCKER.md)** - Docker configuration guide
  - Multi-stage builds
  - Runtime configuration
  - Health checks
  - Troubleshooting

- **[VERSION_MANAGEMENT.md](./VERSION_MANAGEMENT.md)** - Version management
  - Single source of truth pattern
  - Automatic injection
  - Version format (VERSION-SHA)
  - Git tagging workflow

### GitHub Workflows Documentation

- **[.github/workflows/README.md](.github/workflows/README.md)** - Workflows overview
- **[.github/DEPLOYMENT_CLEANUP.md](.github/DEPLOYMENT_CLEANUP.md)** - Infrastructure cleanup notes
- **[.github/VERSION_CONSOLIDATION.md](.github/VERSION_CONSOLIDATION.md)** - Version consolidation details
- **[.github/DATADOG_DEPLOYMENT_COMPARISON.md](.github/DATADOG_DEPLOYMENT_COMPARISON.md)** - Datadog integration comparison
- **[.github/RUNNER_TROUBLESHOOTING.md](.github/RUNNER_TROUBLESHOOTING.md)** - Runner troubleshooting guide
- **[.github/WORKFLOW_STATUS.md](.github/WORKFLOW_STATUS.md)** - Current workflow status

### Scripts Documentation

All deployment scripts include comprehensive inline documentation:
- `scripts/deploy-github.sh` - GitHub Actions orchestration
- `scripts/setup-github-secrets.sh` - Secrets management
- `scripts/restart-runner.sh` - Runner maintenance

## 💻 Development

### Available Scripts

```bash
# Development
yarn dev              # Start dev server (localhost:5173)
yarn build            # Build for production
yarn preview          # Preview production build
yarn start            # Serve production build with http-server

# Code Quality
yarn lint             # Run ESLint
yarn lint:fix         # Fix ESLint issues automatically

# Testing
npx playwright test   # Run E2E tests (requires Playwright setup)
```

### Environment Variables

Required environment variables (see [.env.example](./.env.example)):

**API Configuration**:
- `VITE_API_URL` - Backend API URL
- `VITE_API_KEY` - Optional API authentication key
- `VITE_AUTH_USERNAME` - Basic auth username (if needed)
- `VITE_AUTH_PASSWORD` - Basic auth password (if needed)

**Application**:
- `VITE_ENVIRONMENT` - Environment name (development/production)

**Datadog**:
- `VITE_DATADOG_APPLICATION_ID` - Datadog RUM application ID
- `VITE_DATADOG_CLIENT_TOKEN` - Datadog RUM client token
- `VITE_DATADOG_SITE` - Datadog site (datadoghq.com)
- `VITE_DATADOG_SERVICE` - Service name (demo-gallery)

**Version** (Auto-injected):
- `VITE_RELEASE` - Automatically set from VERSION file + git SHA

### Development Workflow

1. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test**:
   ```bash
   yarn dev          # Test locally
   yarn lint         # Check code quality
   yarn build        # Test production build
   ```

3. **Commit changes**:
   ```bash
   git add .
   git commit -m "feat: description of changes"
   ```

4. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   # Create pull request on GitHub
   ```

### Code Quality Standards

- **ESLint**: Enforced code style and best practices
- **SonarQube**: Automated code quality and security analysis
- **Error Boundaries**: Graceful error handling in React
- **TypeScript-ready**: Structure supports TypeScript migration
- **Component Patterns**: Consistent component organization

## 🚀 Deployment

### Deployment Methods

#### 1. Automated Deployment (Recommended)

**GitHub Actions** automatically deploys on push to `main`:

```bash
# Update version
echo "1.0.3" > VERSION

# Commit and push
git add VERSION
git commit -m "chore: Bump version to 1.0.3"
git push origin main

# Deployment happens automatically via GitHub Actions
```

**What happens**:
1. GitHub Actions workflow triggers
2. Docker image built with version tag
3. Pushed to Docker Hub (3 tags: latest, VERSION-SHA, SHA)
4. Deployed to Ubuntu server on port 8080
5. Health check validation
6. Deployment marked in Datadog

#### 2. Manual Deployment

Use the deployment script for manual deployments:

```bash
./scripts/deploy-github.sh
```

This script:
- Validates environment configuration
- Uploads GitHub Secrets
- Commits and pushes changes
- Monitors workflow execution

#### 3. Emergency/Backup Deployment

For emergencies when GitHub Actions unavailable:

```bash
./deploy.sh
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete deployment documentation.

### Deployment Architecture

```
Developer Push
    ↓
GitHub Actions (Self-Hosted Runner)
    ↓
    ├─ Read VERSION file (1.0.2)
    ├─ Append commit SHA (abc1234)
    ├─ Build Docker image
    ├─ Tag: latest, 1.0.2-abc1234, abc1234
    ├─ Push to Docker Hub
    ├─ Deploy to Ubuntu server:8080
    ├─ Health check validation
    └─ Mark deployment in Datadog
```

### Required Secrets

Configure in GitHub Settings → Secrets:

**Docker Hub**:
- `DOCKERHUB_USER` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token

**Application**:
- `VITE_API_URL` - Backend API URL
- `VITE_API_KEY` - Optional API key
- `VITE_AUTH_USERNAME` - Basic auth username
- `VITE_AUTH_PASSWORD` - Basic auth password
- `VITE_ENVIRONMENT` - Environment (production)
- `VITE_DATADOG_APPLICATION_ID` - Datadog RUM app ID
- `VITE_DATADOG_CLIENT_TOKEN` - Datadog RUM token
- `VITE_DATADOG_SITE` - Datadog site
- `VITE_DATADOG_SERVICE` - Service name

**Datadog**:
- `DD_API_KEY` - Datadog API key
- `DD_APP_KEY` - Datadog Application key
- `DD_ENV` - Environment for Datadog (production)

**SonarQube** (Optional):
- `SONAR_TOKEN` - SonarQube authentication token
- `SONAR_HOST_URL` - SonarQube server URL

## 📊 Monitoring

### Datadog Integration

The application includes comprehensive Datadog observability:

**Real User Monitoring (RUM)**:
- Session replay (100% sampling)
- User interactions tracking
- Resource monitoring
- Long task tracking
- Custom context (image processing metadata)

**Logging**:
- Structured logging with context
- Error forwarding from RUM
- Custom log levels
- Feature-based tagging

**APM Integration**:
- Network request tracing
- Distributed tracing with trace IDs
- Request/response payload capture
- Automatic trace correlation

**Deployment Tracking**:
- Deployment markers in Datadog CD Visibility
- Version tracking (VERSION-SHA format)
- Git metadata (repository, branch, commit)
- Deployment method tagging

**Access Monitoring**:
- **CD Deployments**: https://app.datadoghq.com/ci/deployments
- **RUM Dashboard**: https://app.datadoghq.com/rum
- **Logs Explorer**: https://app.datadoghq.com/logs
- **Service APM**: https://app.datadoghq.com/apm/services/demo-gallery

### Monitoring Configuration

Datadog is initialized in `src/App.jsx` with:
- Application ID and client token
- Service and environment tagging
- Version tracking from VITE_RELEASE
- Custom context for image processing
- Network tracing for allowed URLs

### Health Checks

**Container Health**:
```bash
# Docker health check (every 30s)
curl http://localhost:8080/health

# Container status
docker ps --filter name=demo-gallery
```

**Application Monitoring**:
- Datadog RUM dashboard
- SonarQube quality metrics
- GitHub Actions workflow status

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Convention

We follow conventional commits:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or modifications
- `chore:` - Maintenance tasks

### Pull Request Process

1. Update documentation for any new features
2. Ensure all tests pass and linting succeeds
3. Update VERSION file if needed
4. PR will trigger CI checks (SonarQube, linting)
5. Requires approval before merging
6. Merge to `main` triggers deployment

## 📋 Project Status

- **Version**: 1.0.2
- **Status**: ✅ Production Ready
- **Deployment**: ✅ Automated via GitHub Actions
- **Monitoring**: ✅ Datadog RUM + Logs + APM
- **Documentation**: ✅ Comprehensive
- **CI/CD**: ✅ GitHub Actions workflows
- **Container**: ✅ Docker ready with health checks

### Recent Updates

- ✅ Centralized version management (VERSION file + git SHA)
- ✅ Automated deployment workflows
- ✅ Datadog deployment marking
- ✅ SonarQube integration
- ✅ CircleCI cleanup (migrated to GitHub Actions)
- ✅ Comprehensive documentation

## 📝 License

This project is part of a demonstration portfolio.

## 🔗 Links

- **GitHub Repository**: [demo-gallery](https://github.com/yourusername/demo-gallery)
- **Docker Hub**: [yourusername/demo-gallery](https://hub.docker.com/r/yourusername/demo-gallery)
- **Documentation**: See [docs](#documentation) section above
- **Deployment Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)

## 📞 Support

For issues, questions, or contributions:
- **Issues**: [GitHub Issues](https://github.com/yourusername/demo-gallery/issues)
- **Documentation**: Review docs in this repository
- **Deployment Help**: See [DEPLOYMENT.md](./DEPLOYMENT.md) and [RUNNER_TROUBLESHOOTING.md](.github/RUNNER_TROUBLESHOOTING.md)

---

**Built with ❤️ using React, Vite, Datadog, and Docker**

*Last Updated: 2025-10-22 | Version: 1.0.2*
