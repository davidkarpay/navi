#!/bin/bash

# Navi Health Monitoring Script
# Continuously monitors backend health and sends alerts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE="https://lovely-vibrancy-production-2c30.up.railway.app"
CHECK_INTERVAL=60  # seconds
MAX_FAILURES=3
ALERT_COOLDOWN=300  # 5 minutes
LOG_FILE="./navi_health_monitor.log"
METRICS_FILE="./navi_health_metrics.json"

# State variables
consecutive_failures=0
last_alert_time=0
start_time=$(date +%s)

# Options
VERBOSE=false
DAEMON=false
QUIET=false
WEBHOOK_URL=""

# Logging functions
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [INFO] $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [SUCCESS] $1"
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}$message${NC}"
    fi
    echo "$message" >> "$LOG_FILE"
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [ERROR] $1"
    echo -e "${RED}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [WARNING] $1"
    echo -e "${YELLOW}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local message="[$timestamp] [DEBUG] $1"
        echo -e "${BLUE}$message${NC}"
        echo "$message" >> "$LOG_FILE"
    fi
}

# Usage
usage() {
    echo "Navi Health Monitoring Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i, --interval <seconds>    Check interval (default: 60)"
    echo "  -f, --max-failures <num>    Max consecutive failures before alert (default: 3)"
    echo "  -w, --webhook <url>         Webhook URL for alerts (Slack, Discord, etc.)"
    echo "  -d, --daemon                Run as daemon (background process)"
    echo "  -v, --verbose               Verbose output"
    echo "  -q, --quiet                 Quiet mode (errors and alerts only)"
    echo "  -l, --log-file <path>       Log file path (default: ./navi_health_monitor.log)"
    echo "  -h, --help                  Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                          # Run with defaults"
    echo "  $0 -i 30 -v                # Check every 30 seconds, verbose"
    echo "  $0 -d -w 'https://hooks.slack.com/...'  # Daemon with Slack alerts"
    echo "  $0 --quiet                  # Only show errors and alerts"
    echo ""
    echo "Monitoring includes:"
    echo "  - API health endpoint"
    echo "  - Response time tracking"
    echo "  - User registration test"
    echo "  - Database connectivity"
    echo "  - Memory usage (if available)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -f|--max-failures)
            MAX_FAILURES="$2"
            shift 2
            ;;
        -w|--webhook)
            WEBHOOK_URL="$2"
            shift 2
            ;;
        -d|--daemon)
            DAEMON=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
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
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing_deps[*]}"
        echo "Install with: brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Send alert via webhook
send_alert() {
    local alert_type="$1"
    local message="$2"
    local current_time=$(date +%s)
    
    # Check cooldown
    if [ $((current_time - last_alert_time)) -lt $ALERT_COOLDOWN ]; then
        verbose_log "Alert cooldown active, not sending alert"
        return
    fi
    
    last_alert_time=$current_time
    
    if [ -n "$WEBHOOK_URL" ]; then
        verbose_log "Sending $alert_type alert via webhook"
        
        # Format for Slack/Discord webhook
        local payload=$(cat <<EOF
{
    "text": "🚨 Navi Alert: $alert_type",
    "attachments": [
        {
            "color": "$([ "$alert_type" = "RECOVERY" ] && echo "good" || echo "danger")",
            "fields": [
                {
                    "title": "Message",
                    "value": "$message",
                    "short": false
                },
                {
                    "title": "Time",
                    "value": "$(date)",
                    "short": true
                },
                {
                    "title": "Service",
                    "value": "$API_BASE",
                    "short": true
                }
            ]
        }
    ]
}
EOF
        )
        
        if curl -sf -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "$payload" > /dev/null; then
            verbose_log "Alert sent successfully"
        else
            error "Failed to send alert via webhook"
        fi
    else
        warning "No webhook URL configured for alerts"
    fi
}

# Update metrics file
update_metrics() {
    local status="$1"
    local response_time="$2"
    local timestamp=$(date +%s)
    
    # Create metrics object
    local metrics=$(cat <<EOF
{
    "timestamp": $timestamp,
    "status": "$status",
    "response_time_ms": $response_time,
    "consecutive_failures": $consecutive_failures,
    "uptime_seconds": $((timestamp - start_time)),
    "api_base": "$API_BASE"
}
EOF
    )
    
    # Append to metrics file (keep last 1000 entries)
    if [ -f "$METRICS_FILE" ]; then
        # Read existing metrics and append new one
        local temp_file=$(mktemp)
        echo "$metrics" > "$temp_file"
        tail -n 999 "$METRICS_FILE" >> "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$METRICS_FILE"
    else
        echo "$metrics" > "$METRICS_FILE"
    fi
}

# Check API health
check_health() {
    verbose_log "Checking health endpoint..."
    
    local start_time=$(date +%s%3N)
    local response=$(curl -sf --max-time 10 "$API_BASE/health" 2>/dev/null)
    local curl_exit_code=$?
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [ $curl_exit_code -eq 0 ]; then
        # Parse response
        local status=$(echo "$response" | jq -r '.status' 2>/dev/null)
        
        if [ "$status" = "ok" ]; then
            verbose_log "Health check passed (${response_time}ms)"
            update_metrics "healthy" "$response_time"
            return 0
        else
            error "Health check returned invalid status: $status"
            update_metrics "unhealthy" "$response_time"
            return 1
        fi
    else
        error "Health check failed (curl exit code: $curl_exit_code)"
        update_metrics "unreachable" "0"
        return 1
    fi
}

# Test user registration
test_registration() {
    verbose_log "Testing user registration..."
    
    local test_token="health-check-$(date +%s)"
    local response=$(curl -sf --max-time 10 -X POST "$API_BASE/api/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"deviceToken\": \"$test_token\"}" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local user_id=$(echo "$response" | jq -r '.userId' 2>/dev/null)
        local token=$(echo "$response" | jq -r '.token' 2>/dev/null)
        
        if [ "$user_id" != "null" ] && [ "$token" != "null" ]; then
            verbose_log "Registration test passed"
            return 0
        else
            error "Registration test failed: invalid response format"
            return 1
        fi
    else
        error "Registration test failed: request failed"
        return 1
    fi
}

# Comprehensive health check
comprehensive_check() {
    local overall_health=true
    
    # Basic health endpoint
    if ! check_health; then
        overall_health=false
    fi
    
    # Registration test (only if basic health passes)
    if [ "$overall_health" = true ]; then
        if ! test_registration; then
            overall_health=false
        fi
    fi
    
    return $([ "$overall_health" = true ] && echo 0 || echo 1)
}

# Generate status report
generate_status_report() {
    local uptime_seconds=$(($(date +%s) - start_time))
    local uptime_hours=$((uptime_seconds / 3600))
    local uptime_minutes=$(((uptime_seconds % 3600) / 60))
    
    echo ""
    echo "======================================"
    echo "       Navi Health Monitor Status"
    echo "======================================"
    echo "API Base URL: $API_BASE"
    echo "Monitor Uptime: ${uptime_hours}h ${uptime_minutes}m"
    echo "Check Interval: ${CHECK_INTERVAL}s"
    echo "Consecutive Failures: $consecutive_failures/$MAX_FAILURES"
    echo "Log File: $LOG_FILE"
    echo "Metrics File: $METRICS_FILE"
    echo ""
    
    # Show recent metrics if available
    if [ -f "$METRICS_FILE" ] && command -v jq &> /dev/null; then
        echo "Recent Health Checks:"
        head -n 5 "$METRICS_FILE" | while read -r line; do
            local timestamp=$(echo "$line" | jq -r '.timestamp')
            local status=$(echo "$line" | jq -r '.status')
            local response_time=$(echo "$line" | jq -r '.response_time_ms')
            local human_time=$(date -r "$timestamp" '+%H:%M:%S' 2>/dev/null || echo "unknown")
            
            echo "  $human_time - $status (${response_time}ms)"
        done
        echo ""
    fi
}

# Signal handlers
handle_sigterm() {
    log "Received SIGTERM, shutting down gracefully..."
    cleanup_and_exit 0
}

handle_sigint() {
    echo "" # New line after ^C
    log "Received SIGINT, shutting down gracefully..."
    cleanup_and_exit 0
}

# Cleanup and exit
cleanup_and_exit() {
    local exit_code=${1:-0}
    
    log "Health monitor shutting down"
    generate_status_report
    
    if [ "$DAEMON" = true ]; then
        # Remove PID file if we created one
        [ -f "/tmp/navi_health_monitor.pid" ] && rm -f "/tmp/navi_health_monitor.pid"
    fi
    
    exit $exit_code
}

# Main monitoring loop
monitor_loop() {
    log "Starting health monitoring (interval: ${CHECK_INTERVAL}s, max failures: $MAX_FAILURES)"
    
    # Create initial log entry
    log "Monitor started for $API_BASE"
    
    while true; do
        if comprehensive_check; then
            # Health check passed
            if [ $consecutive_failures -gt 0 ]; then
                # Recovery from previous failures
                success "Service recovered after $consecutive_failures failure(s)"
                send_alert "RECOVERY" "Service is now healthy after $consecutive_failures consecutive failures"
                consecutive_failures=0
            else
                success "Health check passed"
            fi
        else
            # Health check failed
            ((consecutive_failures++))
            error "Health check failed ($consecutive_failures/$MAX_FAILURES)"
            
            if [ $consecutive_failures -ge $MAX_FAILURES ]; then
                error "Maximum consecutive failures reached!"
                send_alert "SERVICE_DOWN" "Service has failed $consecutive_failures consecutive health checks"
            fi
        fi
        
        # Show periodic status in verbose mode
        if [ "$VERBOSE" = true ] && [ $(($(date +%s) % 300)) -eq 0 ]; then
            generate_status_report
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Main execution
main() {
    # Check dependencies
    check_dependencies
    
    # Set up signal handlers
    trap handle_sigterm TERM
    trap handle_sigint INT
    
    # Create log file
    touch "$LOG_FILE"
    
    if [ "$DAEMON" = true ]; then
        log "Starting in daemon mode..."
        
        # Create PID file
        echo $$ > "/tmp/navi_health_monitor.pid"
        
        # Redirect output to log file
        exec > >(tee -a "$LOG_FILE")
        exec 2>&1
        
        # Run in background
        nohup bash -c "$(declare -f monitor_loop); monitor_loop" &
        
        log "Daemon started with PID $!"
        echo "Monitor running in background. Check logs: tail -f $LOG_FILE"
        echo "Stop with: kill \$(cat /tmp/navi_health_monitor.pid)"
    else
        # Interactive mode
        if [ "$QUIET" = false ]; then
            generate_status_report
        fi
        
        monitor_loop
    fi
}

# Show initial status message
if [ "$QUIET" = false ]; then
    echo "======================================"
    echo "     Navi Health Monitor"
    echo "======================================"
    echo "Target: $API_BASE"
    echo "Interval: ${CHECK_INTERVAL}s"
    echo "Max Failures: $MAX_FAILURES"
    echo "Mode: $([ "$DAEMON" = true ] && echo "Daemon" || echo "Interactive")"
    echo ""
fi

# Run main function
main "$@"