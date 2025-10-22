#!/bin/bash

# Runner Diagnostic Script
# Identifies why workflows are stuck in "queued" state

echo "=========================================="
echo "GitHub Actions Runner Diagnostic"
echo "=========================================="
echo ""

# Check 1: Repository Location
echo "📍 CHECK 1: Repository Location"
echo "----------------------------------------"
REPO_INFO=$(gh repo view --json owner,name,url)
REPO_OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
REPO_URL=$(echo "$REPO_INFO" | jq -r '.url')

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "URL: $REPO_URL"

# Check if owner is organization or user
OWNER_TYPE=$(gh api users/$REPO_OWNER --jq '.type')
echo "Owner Type: $OWNER_TYPE"

if [ "$OWNER_TYPE" = "Organization" ]; then
    echo "✅ Repository is in an organization: $REPO_OWNER"
    ORG_NAME="$REPO_OWNER"
elif [ "$OWNER_TYPE" = "User" ]; then
    echo "⚠️  Repository is under personal account: $REPO_OWNER"
    echo ""
    echo "💡 For org-level runners, repository must be in the organization!"
    echo "   Current: $REPO_OWNER/$REPO_NAME (personal)"
    echo "   Needed: quickstarkdemo/$REPO_NAME (organization)"
    echo ""
    echo "To fix: Transfer repo to organization"
    echo "   gh repo transfer $REPO_OWNER/$REPO_NAME quickstarkdemo"
    ORG_NAME="quickstarkdemo"
fi
echo ""

# Check 2: Runner Container Status
echo "🐳 CHECK 2: Runner Container Status"
echo "----------------------------------------"
RUNNER_CONTAINERS=$(docker ps -a --filter "name=runner" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}")

if [ -z "$RUNNER_CONTAINERS" ]; then
    echo "❌ No runner containers found!"
    echo ""
    echo "Search for any container with 'runner' in name:"
    docker ps -a | grep -i runner || echo "  No containers found"
else
    echo "$RUNNER_CONTAINERS"
    echo ""

    # Check if any are running
    RUNNING_RUNNERS=$(docker ps --filter "name=runner" --format "{{.Names}}")
    if [ -z "$RUNNING_RUNNERS" ]; then
        echo "❌ Runner containers exist but NONE are running!"
        echo ""
        echo "To start runner:"
        echo "  docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d"
    else
        echo "✅ Running containers: $RUNNING_RUNNERS"

        # Get logs from running runner
        FIRST_RUNNER=$(echo "$RUNNING_RUNNERS" | head -1)
        echo ""
        echo "Recent logs from $FIRST_RUNNER:"
        echo "---"
        docker logs "$FIRST_RUNNER" --tail 10 2>&1 | sed 's/^/  /'
        echo "---"
    fi
fi
echo ""

# Check 3: Organization Runners
echo "🏢 CHECK 3: Organization Runners"
echo "----------------------------------------"
if gh api orgs/$ORG_NAME >/dev/null 2>&1; then
    echo "Checking runners for organization: $ORG_NAME"

    ORG_RUNNERS=$(gh api orgs/$ORG_NAME/actions/runners --jq '.runners[] | {name, status, busy, labels: [.labels[].name]}')

    if [ -z "$ORG_RUNNERS" ]; then
        echo "❌ No runners registered to organization: $ORG_NAME"
        echo ""
        echo "To register org-level runner:"
        echo "  1. Get token: gh api -X POST orgs/$ORG_NAME/actions/runners/registration-token --jq '.token'"
        echo "  2. Update .env with token"
        echo "  3. Deploy: docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d"
    else
        echo "✅ Organization runners found:"
        echo "$ORG_RUNNERS" | jq -r '. | "  Name: \(.name)\n  Status: \(.status)\n  Busy: \(.busy)\n  Labels: \(.labels | join(", "))\n"'

        # Check if any are online
        ONLINE_COUNT=$(echo "$ORG_RUNNERS" | jq -r 'select(.status == "online")' | wc -l)
        if [ "$ONLINE_COUNT" -eq 0 ]; then
            echo "❌ No runners are ONLINE!"
            echo "   Runners exist but are offline/disconnected"
        else
            echo "✅ $ONLINE_COUNT runner(s) online"
        fi
    fi
else
    echo "⚠️  Organization '$ORG_NAME' not accessible"
    echo "   Checking repository-level runners instead..."

    REPO_RUNNERS=$(gh api repos/$REPO_OWNER/$REPO_NAME/actions/runners --jq '.runners[] | {name, status, busy}')

    if [ -z "$REPO_RUNNERS" ]; then
        echo "❌ No runners registered to repository: $REPO_OWNER/$REPO_NAME"
    else
        echo "✅ Repository runners found:"
        echo "$REPO_RUNNERS" | jq -r '. | "  Name: \(.name)\n  Status: \(.status)\n  Busy: \(.busy)\n"'
    fi
fi
echo ""

# Check 4: Workflow Run Status
echo "⚙️  CHECK 4: Latest Workflow Run"
echo "----------------------------------------"
LATEST_RUN=$(gh run list --limit 1 --json status,conclusion,databaseId,name,headBranch)

if [ -z "$LATEST_RUN" ]; then
    echo "ℹ️  No recent workflow runs found"
else
    RUN_ID=$(echo "$LATEST_RUN" | jq -r '.[0].databaseId')
    RUN_STATUS=$(echo "$LATEST_RUN" | jq -r '.[0].status')
    RUN_NAME=$(echo "$LATEST_RUN" | jq -r '.[0].name')
    RUN_BRANCH=$(echo "$LATEST_RUN" | jq -r '.[0].headBranch')

    echo "Latest Run: $RUN_NAME"
    echo "Branch: $RUN_BRANCH"
    echo "Status: $RUN_STATUS"
    echo "Run ID: $RUN_ID"

    if [ "$RUN_STATUS" = "queued" ]; then
        echo ""
        echo "🔍 Workflow is QUEUED - checking why..."

        # Get job details
        JOBS=$(gh api repos/$REPO_OWNER/$REPO_NAME/actions/runs/$RUN_ID/jobs --jq '.jobs[] | {name, status, runner_name, labels}')

        echo "$JOBS" | jq -r '. | "  Job: \(.name)\n  Status: \(.status)\n  Runner: \(.runner_name // "none")\n  Required Labels: \(.labels | join(", "))\n"'

        echo "💡 Job is waiting for runner with labels: $(echo "$JOBS" | jq -r '.labels | join(", ")')"
    fi
fi
echo ""

# Summary and Recommendations
echo "=========================================="
echo "📋 SUMMARY & RECOMMENDATIONS"
echo "=========================================="
echo ""

# Determine the issue
if [ "$OWNER_TYPE" = "User" ]; then
    echo "🚨 PRIMARY ISSUE: Repository Mismatch"
    echo "   Repository: $REPO_OWNER/$REPO_NAME (personal account)"
    echo "   Runner: Registered to organization 'quickstarkdemo'"
    echo ""
    echo "   ❌ Organization runners ONLY work for repos IN that organization!"
    echo ""
    echo "✅ FIX: Transfer repository to organization"
    echo "   gh repo transfer $REPO_OWNER/$REPO_NAME quickstarkdemo"
    echo ""
    echo "   After transfer, update local git remote:"
    echo "   git remote set-url origin https://github.com/quickstarkdemo/$REPO_NAME.git"
    echo ""
elif [ -z "$RUNNING_RUNNERS" ]; then
    echo "🚨 PRIMARY ISSUE: Runner Not Running"
    echo "   Runner container exists but is stopped/crashed"
    echo ""
    echo "✅ FIX: Start the runner"
    echo "   docker-compose -f docker-compose.runner-fixed.yml --env-file .env up -d"
    echo "   docker logs -f quickstarkdemo-runner"
    echo ""
elif [ "$ONLINE_COUNT" -eq 0 ]; then
    echo "🚨 PRIMARY ISSUE: Runner Offline"
    echo "   Runner is running but not connected to GitHub"
    echo ""
    echo "✅ FIX: Check runner logs and restart"
    echo "   docker logs quickstarkdemo-runner --tail 50"
    echo "   docker restart quickstarkdemo-runner"
    echo ""
else
    echo "✅ Runner appears to be working!"
    echo "   Repository: $REPO_OWNER/$REPO_NAME (organization)"
    echo "   Runner: Online and idle"
    echo ""
    echo "If workflow still queued, check:"
    echo "   1. Runner labels match workflow requirements"
    echo "   2. Runner group allows this repository"
    echo "   3. Trigger a new workflow run: gh workflow run deploy.yml"
fi

echo "=========================================="
echo ""
echo "For detailed runner logs:"
echo "  docker logs quickstarkdemo-runner --tail 100"
echo ""
echo "To check GitHub runner UI:"
echo "  https://github.com/organizations/quickstarkdemo/settings/actions/runners"
echo ""
