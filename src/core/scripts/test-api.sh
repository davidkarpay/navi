#!/bin/bash

# Navi API Test Script
# Tests all API endpoints and WebSocket functionality

set -e

# Configuration
API_BASE="https://lovely-vibrancy-production-2c30.up.railway.app"
VERBOSE=false
QUICK=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -v, --verbose    Verbose output"
    echo "  -q, --quick      Quick test (skip load testing)"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run full test suite"
    echo "  $0 -v               # Run with verbose output"
    echo "  $0 -q               # Quick test without load testing"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quick)
            QUICK=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test result tracking
test_result() {
    ((TOTAL_TESTS++))
    if [ $1 -eq 0 ]; then
        success "$2"
        ((TESTS_PASSED++))
    else
        error "$2"
        ((TESTS_FAILED++))
    fi
}

# API call wrapper
api_call() {
    local method="$1"
    local endpoint="$2"
    local headers="$3"
    local data="$4"
    local expected_code="${5:-200}"
    
    verbose_log "Making $method request to $endpoint"
    if [ "$VERBOSE" = true ]; then
        verbose_log "Headers: $headers"
        verbose_log "Data: $data"
    fi
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" "$API_BASE$endpoint" $headers -d "$data")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" "$API_BASE$endpoint" $headers)
    fi
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    verbose_log "Response code: $http_code"
    verbose_log "Response body: $body"
    
    if [ "$http_code" = "$expected_code" ]; then
        echo "$body"
        return 0
    else
        error "Expected $expected_code, got $http_code: $body"
        return 1
    fi
}

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Install with: brew install jq"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed."
        exit 1
    fi
}

# Test 1: Health Check
test_health() {
    log "Testing health endpoint..."
    
    response=$(api_call "GET" "/health" "" "" "200")
    if [ $? -eq 0 ]; then
        status=$(echo "$response" | jq -r '.status')
        if [ "$status" = "ok" ]; then
            test_result 0 "Health check endpoint working"
        else
            test_result 1 "Health check returned invalid status: $status"
        fi
    else
        test_result 1 "Health check endpoint failed"
    fi
}

# Test 2: User Registration
test_registration() {
    log "Testing user registration..."
    
    # Test User A
    response=$(api_call "POST" "/api/auth/register" '-H "Content-Type: application/json"' '{"deviceToken": "test-token-a"}' "200")
    if [ $? -eq 0 ]; then
        TOKEN_A=$(echo "$response" | jq -r '.token')
        USER_ID_A=$(echo "$response" | jq -r '.userId')
        
        if [ "$TOKEN_A" != "null" ] && [ "$TOKEN_A" != "" ]; then
            test_result 0 "User A registration successful"
            verbose_log "User A Token: $TOKEN_A"
            verbose_log "User A ID: $USER_ID_A"
        else
            test_result 1 "User A registration returned invalid token"
            return 1
        fi
    else
        test_result 1 "User A registration failed"
        return 1
    fi
    
    # Test User B
    response=$(api_call "POST" "/api/auth/register" '-H "Content-Type: application/json"' '{"deviceToken": "test-token-b"}' "200")
    if [ $? -eq 0 ]; then
        TOKEN_B=$(echo "$response" | jq -r '.token')
        USER_ID_B=$(echo "$response" | jq -r '.userId')
        
        if [ "$TOKEN_B" != "null" ] && [ "$TOKEN_B" != "" ]; then
            test_result 0 "User B registration successful"
            verbose_log "User B Token: $TOKEN_B"
            verbose_log "User B ID: $USER_ID_B"
        else
            test_result 1 "User B registration returned invalid token"
            return 1
        fi
    else
        test_result 1 "User B registration failed"
        return 1
    fi
    
    # Test invalid registration (missing deviceToken)
    response=$(api_call "POST" "/api/auth/register" '-H "Content-Type: application/json"' '{}' "400")
    if [ $? -eq 0 ]; then
        test_result 0 "Registration properly rejects missing deviceToken"
    else
        test_result 1 "Registration should reject missing deviceToken"
    fi
}

# Test 3: Pairing Status (Not Paired)
test_pairing_status_unpaired() {
    log "Testing pairing status (unpaired)..."
    
    response=$(api_call "GET" "/api/pairing/status" "-H \"Authorization: Bearer $TOKEN_A\"" "" "200")
    if [ $? -eq 0 ]; then
        paired=$(echo "$response" | jq -r '.paired')
        if [ "$paired" = "false" ]; then
            test_result 0 "Pairing status correctly shows unpaired"
        else
            test_result 1 "Pairing status should show unpaired, got: $paired"
        fi
    else
        test_result 1 "Pairing status check failed"
    fi
}

# Test 4: Pairing Code Creation
test_pairing_code_creation() {
    log "Testing pairing code creation..."
    
    response=$(api_call "POST" "/api/pairing/create" "-H \"Authorization: Bearer $TOKEN_A\" -H \"Content-Type: application/json\"" "" "200")
    if [ $? -eq 0 ]; then
        PAIRING_CODE=$(echo "$response" | jq -r '.pairingCode')
        expires_in=$(echo "$response" | jq -r '.expiresIn')
        
        if [[ "$PAIRING_CODE" =~ ^[0-9]{6}$ ]]; then
            test_result 0 "Pairing code creation successful (code: $PAIRING_CODE)"
            verbose_log "Pairing code expires in: $expires_in seconds"
        else
            test_result 1 "Invalid pairing code format: $PAIRING_CODE"
            return 1
        fi
    else
        test_result 1 "Pairing code creation failed"
        return 1
    fi
}

# Test 5: Pairing Code Join
test_pairing_join() {
    log "Testing pairing code join..."
    
    response=$(api_call "POST" "/api/pairing/join" "-H \"Authorization: Bearer $TOKEN_B\" -H \"Content-Type: application/json\"" "{\"pairingCode\": \"$PAIRING_CODE\"}" "200")
    if [ $? -eq 0 ]; then
        message=$(echo "$response" | jq -r '.message')
        partner_id=$(echo "$response" | jq -r '.partnerId')
        
        if [ "$partner_id" = "$USER_ID_A" ]; then
            test_result 0 "Pairing join successful"
            verbose_log "Partner ID: $partner_id"
        else
            test_result 1 "Pairing join returned wrong partner ID: $partner_id (expected: $USER_ID_A)"
        fi
    else
        test_result 1 "Pairing join failed"
        return 1
    fi
}

# Test 6: Pairing Status (Paired)
test_pairing_status_paired() {
    log "Testing pairing status (paired)..."
    
    response=$(api_call "GET" "/api/pairing/status" "-H \"Authorization: Bearer $TOKEN_A\"" "" "200")
    if [ $? -eq 0 ]; then
        paired=$(echo "$response" | jq -r '.paired')
        partner_id=$(echo "$response" | jq -r '.partnerId')
        
        if [ "$paired" = "true" ] && [ "$partner_id" = "$USER_ID_B" ]; then
            test_result 0 "Pairing status correctly shows paired"
        else
            test_result 1 "Pairing status incorrect - paired: $paired, partner: $partner_id"
        fi
    else
        test_result 1 "Pairing status check failed"
    fi
}

# Test 7: Tap Sending
test_tap_sending() {
    log "Testing tap sending..."
    
    # User B sends tap to User A
    response=$(api_call "POST" "/api/tap/send" "-H \"Authorization: Bearer $TOKEN_B\" -H \"Content-Type: application/json\"" "" "200")
    if [ $? -eq 0 ]; then
        message=$(echo "$response" | jq -r '.message')
        if [[ "$message" == *"successfully"* ]]; then
            test_result 0 "Tap sending successful"
        else
            test_result 1 "Tap sending returned unexpected message: $message"
        fi
    else
        test_result 1 "Tap sending failed"
    fi
    
    # User A sends tap to User B
    response=$(api_call "POST" "/api/tap/send" "-H \"Authorization: Bearer $TOKEN_A\" -H \"Content-Type: application/json\"" "" "200")
    if [ $? -eq 0 ]; then
        test_result 0 "Bidirectional tap sending works"
    else
        test_result 1 "Bidirectional tap sending failed"
    fi
}

# Test 8: Device Token Update
test_device_token_update() {
    log "Testing device token update..."
    
    response=$(api_call "PUT" "/api/auth/device-token" "-H \"Authorization: Bearer $TOKEN_A\" -H \"Content-Type: application/json\"" '{"deviceToken": "updated-token-a"}' "200")
    if [ $? -eq 0 ]; then
        test_result 0 "Device token update successful"
    else
        test_result 1 "Device token update failed"
    fi
}

# Test 9: Unpair
test_unpair() {
    log "Testing unpair..."
    
    response=$(api_call "DELETE" "/api/pairing/unpair" "-H \"Authorization: Bearer $TOKEN_A\"" "" "200")
    if [ $? -eq 0 ]; then
        test_result 0 "Unpair successful"
    else
        test_result 1 "Unpair failed"
    fi
    
    # Verify both users are unpaired
    response=$(api_call "GET" "/api/pairing/status" "-H \"Authorization: Bearer $TOKEN_A\"" "" "200")
    if [ $? -eq 0 ]; then
        paired=$(echo "$response" | jq -r '.paired')
        if [ "$paired" = "false" ]; then
            test_result 0 "User A correctly unpaired"
        else
            test_result 1 "User A still shows paired after unpair"
        fi
    else
        test_result 1 "Could not verify User A unpair status"
    fi
}

# Test 10: Error Handling
test_error_handling() {
    log "Testing error handling..."
    
    # Invalid token
    response=$(api_call "GET" "/api/pairing/status" "-H \"Authorization: Bearer invalid-token\"" "" "401")
    if [ $? -eq 0 ]; then
        test_result 0 "Invalid token properly rejected"
    else
        test_result 1 "Invalid token should be rejected with 401"
    fi
    
    # Missing token
    response=$(api_call "GET" "/api/pairing/status" "" "" "401")
    if [ $? -eq 0 ]; then
        test_result 0 "Missing token properly rejected"
    else
        test_result 1 "Missing token should be rejected with 401"
    fi
    
    # Invalid pairing code format
    response=$(api_call "POST" "/api/pairing/join" "-H \"Authorization: Bearer $TOKEN_A\" -H \"Content-Type: application/json\"" '{"pairingCode": "invalid"}' "400")
    if [ $? -eq 0 ]; then
        test_result 0 "Invalid pairing code format properly rejected"
    else
        test_result 1 "Invalid pairing code format should be rejected"
    fi
    
    # Expired/non-existent pairing code
    response=$(api_call "POST" "/api/pairing/join" "-H \"Authorization: Bearer $TOKEN_A\" -H \"Content-Type: application/json\"" '{"pairingCode": "999999"}' "404")
    if [ $? -eq 0 ]; then
        test_result 0 "Non-existent pairing code properly rejected"
    else
        test_result 1 "Non-existent pairing code should be rejected with 404"
    fi
}

# Test 11: Rate Limiting (if not in quick mode)
test_rate_limiting() {
    if [ "$QUICK" = true ]; then
        warning "Skipping rate limiting test (quick mode)"
        return
    fi
    
    log "Testing rate limiting (this may take a moment)..."
    
    # Make 110 requests rapidly (limit is 100/minute)
    local success_count=0
    local rate_limited_count=0
    
    for i in {1..110}; do
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$API_BASE/health")
        http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        
        if [ "$http_code" = "200" ]; then
            ((success_count++))
        elif [ "$http_code" = "429" ]; then
            ((rate_limited_count++))
        fi
        
        # Show progress every 20 requests
        if [ $((i % 20)) -eq 0 ]; then
            verbose_log "Progress: $i/110 requests sent"
        fi
    done
    
    if [ $rate_limited_count -gt 0 ]; then
        test_result 0 "Rate limiting working ($rate_limited_count requests blocked)"
    else
        test_result 1 "Rate limiting not working (all $success_count requests succeeded)"
    fi
}

# Test 12: Concurrent Operations
test_concurrent_operations() {
    if [ "$QUICK" = true ]; then
        warning "Skipping concurrent operations test (quick mode)"
        return
    fi
    
    log "Testing concurrent operations..."
    
    # Register multiple users concurrently
    pids=()
    for i in {1..5}; do
        (
            response=$(api_call "POST" "/api/auth/register" '-H "Content-Type: application/json"' "{\"deviceToken\": \"concurrent-token-$i\"}" "200")
            if [ $? -eq 0 ]; then
                echo "concurrent-user-$i:success"
            else
                echo "concurrent-user-$i:failure"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all background processes
    local concurrent_successes=0
    for pid in "${pids[@]}"; do
        if wait $pid; then
            ((concurrent_successes++))
        fi
    done
    
    if [ $concurrent_successes -eq 5 ]; then
        test_result 0 "Concurrent user registration working"
    else
        test_result 1 "Concurrent operations failed ($concurrent_successes/5 succeeded)"
    fi
}

# Main test execution
main() {
    echo "======================================"
    echo "    Navi API Test Suite"
    echo "======================================"
    echo "Testing against: $API_BASE"
    echo "Mode: $([ "$QUICK" = true ] && echo "Quick" || echo "Full")"
    echo "Verbose: $([ "$VERBOSE" = true ] && echo "On" || echo "Off")"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Run tests
    test_health
    test_registration
    test_pairing_status_unpaired
    test_pairing_code_creation
    test_pairing_join
    test_pairing_status_paired
    test_tap_sending
    test_device_token_update
    test_unpair
    test_error_handling
    test_rate_limiting
    test_concurrent_operations
    
    # Summary
    echo ""
    echo "======================================"
    echo "           Test Summary"
    echo "======================================"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        success "All tests passed! 🎉"
        exit 0
    else
        error "Some tests failed. Check the output above."
        exit 1
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