#!/bin/bash

# Navi Deployment Update Script
# Automates backend updates and iOS app builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/src/backend"
IOS_PROJECT="$PROJECT_ROOT/src/frontend/ios/Navi_app.xcodeproj"
RAILWAY_SERVICE="lovely-vibrancy-production-2c30.up.railway.app"

# Options
SKIP_TESTS=false
SKIP_BUILD=false
VERBOSE=false
DRY_RUN=false

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Usage
usage() {
    echo "Navi Deployment Update Script"
    echo ""
    echo "Usage: $0 [options] <command>"
    echo ""
    echo "Commands:"
    echo "  backend         Update backend only"
    echo "  ios             Build iOS app only"
    echo "  all             Update backend and build iOS (default)"
    echo "  status          Check deployment status"
    echo "  rollback        Rollback to previous version"
    echo ""
    echo "Options:"
    echo "  --skip-tests    Skip running tests"
    echo "  --skip-build    Skip building iOS app"
    echo "  --verbose       Verbose output"
    echo "  --dry-run       Show what would be done without executing"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 all                    # Full deployment"
    echo "  $0 backend --skip-tests   # Quick backend update"
    echo "  $0 status                 # Check current status"
    echo "  $0 --dry-run all         # Preview what would happen"
}

# Parse arguments
COMMAND="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        backend|ios|all|status|rollback)
            COMMAND="$1"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if [ "$COMMAND" = "backend" ] || [ "$COMMAND" = "all" ]; then
        if ! command -v railway &> /dev/null; then
            missing_deps+=("railway")
        fi
        
        if ! command -v node &> /dev/null; then
            missing_deps+=("node")
        fi
        
        if ! command -v npm &> /dev/null; then
            missing_deps+=("npm")
        fi
    fi
    
    if [ "$COMMAND" = "ios" ] || [ "$COMMAND" = "all" ]; then
        if ! command -v xcodebuild &> /dev/null; then
            # Try alternative path
            if [ ! -f "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]; then
                missing_deps+=("xcodebuild")
            fi
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install instructions:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                railway)
                    echo "  railway: curl -fsSL https://railway.app/install.sh | sh"
                    ;;
                node)
                    echo "  node: brew install node"
                    ;;
                npm)
                    echo "  npm: comes with node"
                    ;;
                xcodebuild)
                    echo "  xcodebuild: install Xcode from App Store"
                    ;;
            esac
        done
        exit 1
    fi
}

# Execute command with dry-run support
execute() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $*"
    else
        verbose_log "Executing: $*"
        "$@"
    fi
}

# Check git status
check_git_status() {
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        warning "Not in a git repository - skipping git checks"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Check for uncommitted changes
    if ! git diff --quiet; then
        warning "You have uncommitted changes:"
        git status --porcelain
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Get current branch and commit
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local commit=$(git rev-parse --short HEAD)
    
    log "Current branch: $branch"
    log "Current commit: $commit"
}

# Run backend tests
run_backend_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        warning "Skipping backend tests"
        return 0
    fi
    
    log "Running backend tests..."
    cd "$BACKEND_DIR"
    
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        execute npm test
    else
        warning "No test script found in package.json"
    fi
    
    # Run API tests if available
    local api_test_script="$PROJECT_ROOT/src/core/scripts/test-api.sh"
    if [ -f "$api_test_script" ] && [ -x "$api_test_script" ]; then
        log "Running API integration tests..."
        execute "$api_test_script" --quick
    fi
}

# Deploy backend
deploy_backend() {
    log "Deploying backend to Railway..."
    
    cd "$BACKEND_DIR"
    
    # Check if railway is linked
    if ! execute railway status > /dev/null 2>&1; then
        error "Railway not linked. Run 'railway link' first."
        return 1
    fi
    
    # Deploy
    execute railway up
    
    # Wait for deployment to be ready
    log "Waiting for deployment to be healthy..."
    local retries=30
    local delay=10
    
    for ((i=1; i<=retries; i++)); do
        if execute curl -sf "https://$RAILWAY_SERVICE/health" > /dev/null; then
            success "Backend deployment is healthy"
            return 0
        fi
        
        if [ $i -lt $retries ]; then
            verbose_log "Health check failed, retrying in ${delay}s ($i/$retries)..."
            sleep $delay
        fi
    done
    
    error "Backend deployment health check failed after $retries attempts"
    return 1
}

# Build iOS app
build_ios_app() {
    if [ "$SKIP_BUILD" = true ]; then
        warning "Skipping iOS app build"
        return 0
    fi
    
    log "Building iOS app..."
    
    if [ ! -f "$IOS_PROJECT/project.pbxproj" ]; then
        error "iOS project not found at $IOS_PROJECT"
        return 1
    fi
    
    local xcodebuild_cmd="xcodebuild"
    if [ ! -x "$(command -v xcodebuild)" ]; then
        xcodebuild_cmd="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
    fi
    
    cd "$(dirname "$IOS_PROJECT")"
    
    # Clean build
    log "Cleaning iOS project..."
    execute "$xcodebuild_cmd" -project "$(basename "$IOS_PROJECT")" -scheme Navi_app clean
    
    # Build for simulator
    log "Building for iOS Simulator..."
    execute "$xcodebuild_cmd" -project "$(basename "$IOS_PROJECT")" -scheme Navi_app -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' build
    
    # TODO: Build Watch App when target is added
    # execute "$xcodebuild_cmd" -project "$(basename "$IOS_PROJECT")" -scheme "Navi_app Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
    
    success "iOS app build completed"
}

# Check deployment status
check_status() {
    log "Checking deployment status..."
    
    # Backend health
    log "Checking backend health..."
    local health_response=$(curl -sf "https://$RAILWAY_SERVICE/health" || echo "FAILED")
    
    if [ "$health_response" != "FAILED" ]; then
        success "Backend is healthy"
        verbose_log "Health response: $health_response"
    else
        error "Backend health check failed"
    fi
    
    # Railway status
    if command -v railway &> /dev/null; then
        log "Checking Railway deployment status..."
        cd "$BACKEND_DIR"
        railway status || warning "Could not get Railway status"
    fi
    
    # Test key endpoints
    log "Testing key API endpoints..."
    
    # Register test user
    local register_response=$(curl -sf -X POST "https://$RAILWAY_SERVICE/api/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"deviceToken": "test-token-status-check"}' || echo "FAILED")
    
    if [ "$register_response" != "FAILED" ]; then
        success "User registration endpoint working"
        
        # Extract token for further tests
        local token=$(echo "$register_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        
        if [ -n "$token" ]; then
            # Test pairing endpoint
            local pairing_response=$(curl -sf -X POST "https://$RAILWAY_SERVICE/api/pairing/create" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" || echo "FAILED")
            
            if [ "$pairing_response" != "FAILED" ]; then
                success "Pairing endpoint working"
            else
                error "Pairing endpoint failed"
            fi
        fi
    else
        error "User registration endpoint failed"
    fi
}

# Rollback deployment
rollback_deployment() {
    warning "Rolling back deployment..."
    
    cd "$BACKEND_DIR"
    
    if ! command -v railway &> /dev/null; then
        error "Railway CLI not available for rollback"
        return 1
    fi
    
    # Get recent deployments
    log "Getting recent deployments..."
    railway deployments
    
    echo ""
    read -p "Enter deployment ID to rollback to: " deployment_id
    
    if [ -z "$deployment_id" ]; then
        error "No deployment ID provided"
        return 1
    fi
    
    # Perform rollback
    execute railway deployments rollback "$deployment_id"
    
    # Verify rollback
    log "Verifying rollback..."
    sleep 10
    check_status
}

# Generate deployment report
generate_report() {
    local report_file="$PROJECT_ROOT/deployment_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Navi Deployment Report

**Date:** $(date)
**Command:** $COMMAND
**Git Branch:** $(cd "$PROJECT_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
**Git Commit:** $(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Deployment Status

### Backend
- **URL:** https://$RAILWAY_SERVICE
- **Health Status:** $(curl -sf "https://$RAILWAY_SERVICE/health" > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy")
- **Tests:** $([ "$SKIP_TESTS" = true ] && echo "⏭️ Skipped" || echo "✅ Passed")

### iOS App
- **Build Status:** $([ "$SKIP_BUILD" = true ] && echo "⏭️ Skipped" || echo "✅ Built")
- **Project:** $IOS_PROJECT

## Next Steps

1. Test the app on physical devices
2. Verify push notifications are working
3. Monitor error rates and performance
4. Update app store listing if needed

## Rollback Instructions

If issues are found, rollback with:
\`\`\`bash
$0 rollback
\`\`\`

---
Generated by Navi deployment script
EOF
    
    log "Deployment report generated: $report_file"
}

# Main execution
main() {
    echo "======================================"
    echo "     Navi Deployment Script"
    echo "======================================"
    echo "Command: $COMMAND"
    echo "Project: $PROJECT_ROOT"
    echo "Dry Run: $([ "$DRY_RUN" = true ] && echo "Yes" || echo "No")"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Check git status
    if [ "$COMMAND" != "status" ]; then
        check_git_status
    fi
    
    # Execute command
    case $COMMAND in
        backend)
            run_backend_tests
            deploy_backend
            ;;
        ios)
            build_ios_app
            ;;
        all)
            run_backend_tests
            deploy_backend
            build_ios_app
            ;;
        status)
            check_status
            ;;
        rollback)
            rollback_deployment
            ;;
    esac
    
    # Generate report for deployments
    if [ "$COMMAND" != "status" ] && [ "$COMMAND" != "rollback" ] && [ "$DRY_RUN" = false ]; then
        generate_report
    fi
    
    echo ""
    success "Deployment script completed successfully!"
    
    if [ "$COMMAND" = "all" ] || [ "$COMMAND" = "backend" ]; then
        echo ""
        echo "🚀 Your Navi backend is now live at:"
        echo "   https://$RAILWAY_SERVICE"
        echo ""
        echo "📱 Next steps:"
        echo "   1. Test the iOS app with the updated backend"
        echo "   2. Verify pairing and tap functionality"
        echo "   3. Monitor logs: railway logs -f"
    fi
}

# Cleanup function
cleanup() {
    verbose_log "Cleaning up..."
    # Add any cleanup code here if needed
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"