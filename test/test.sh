#!/usr/bin/env bash

set -euo pipefail

# Test configuration
TEST_DIR="test_certs"
CA_NAME="TestCA"
SERVER_DOMAIN="test.example.com"
CLIENT_NAME="testclient"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED+1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

run_test() {
    TESTS_RUN=$((TESTS_RUN+1))
    local test_name="$1"
    local test_command="$2"

    log_info "Running: $test_name"
    if eval "$test_command"; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test directory..."
    rm -rf "$TEST_DIR"
    rm -f /tmp/client_ext.cnf /tmp/server_ext.cnf
}

# Setup test environment
setup() {
    log_info "Setting up test environment..."
    cleanup
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
}

# Test CA generation
test_ca_generation() {
    run_test "CA script execution" "../ca.sh $CA_NAME"
    run_test "CA directory created" "[ -d '$CA_NAME' ]"
    run_test "CA private key exists" "[ -f '$CA_NAME/ca.key' ]"
    run_test "CA certificate exists" "[ -f '$CA_NAME/ca.pem' ]"
    run_test "CA key is valid RSA" "openssl rsa -in '$CA_NAME/ca.key' -check -noout"
    run_test "CA certificate is valid" "openssl x509 -in '$CA_NAME/ca.pem' -text -noout > /dev/null"
    run_test "CA is self-signed" "openssl verify -CAfile '$CA_NAME/ca.pem' '$CA_NAME/ca.pem'"
    run_test "CA has correct subject CN" "openssl x509 -in '$CA_NAME/ca.pem' -subject -noout | grep -E 'CN\s*=\s*$CA_NAME'"
    run_test "CA has CA:TRUE constraint" "openssl x509 -in '$CA_NAME/ca.pem' -text -noout | grep 'CA:TRUE'"
    run_test "CA has key cert sign usage" "openssl x509 -in '$CA_NAME/ca.pem' -text -noout | grep 'Certificate Sign'"
}

# Test server certificate generation
test_server_generation() {
    run_test "Server script execution" "../server.sh $SERVER_DOMAIN $CA_NAME"
    run_test "Server directory created" "[ -d '$SERVER_DOMAIN' ]"
    run_test "Server private key exists" "[ -f '$SERVER_DOMAIN/server.key' ]"
    run_test "Server certificate exists" "[ -f '$SERVER_DOMAIN/server.pem' ]"
    run_test "Server bundle exists" "[ -f '$SERVER_DOMAIN/server-bundle.pem' ]"
    run_test "Server key is valid RSA" "openssl rsa -in '$SERVER_DOMAIN/server.key' -check -noout"
    run_test "Server certificate is valid" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -text -noout > /dev/null"
    run_test "Server cert signed by CA" "openssl verify -CAfile '$CA_NAME/ca.pem' '$SERVER_DOMAIN/server.pem'"
    run_test "Server has correct CN" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -subject -noout | grep -E 'CN\s*=\s*$SERVER_DOMAIN'"
    run_test "Server has SAN extension" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -text -noout | grep 'DNS:$SERVER_DOMAIN'"
    run_test "Server has serverAuth usage" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -text -noout | grep 'TLS Web Server Authentication'"
    run_test "Server is not CA" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -text -noout | grep 'CA:FALSE'"
}

# Test client certificate generation
test_client_generation() {
    run_test "Client script execution" "../client.sh $CLIENT_NAME $CA_NAME"
    run_test "Client directory created" "[ -d '$CLIENT_NAME' ]"
    run_test "Client private key exists" "[ -f '$CLIENT_NAME/client.key' ]"
    run_test "Client certificate exists" "[ -f '$CLIENT_NAME/client.pem' ]"
    run_test "Client bundle exists" "[ -f '$CLIENT_NAME/client-bundle.pem' ]"
    run_test "Client key is valid RSA" "openssl rsa -in '$CLIENT_NAME/client.key' -check -noout"
    run_test "Client certificate is valid" "openssl x509 -in '$CLIENT_NAME/client.pem' -text -noout > /dev/null"
    run_test "Client cert signed by CA" "openssl verify -CAfile '$CA_NAME/ca.pem' '$CLIENT_NAME/client.pem'"
    run_test "Client has correct CN" "openssl x509 -in '$CLIENT_NAME/client.pem' -subject -noout | grep -E 'CN\s*=\s*$CLIENT_NAME'"
    run_test "Client has clientAuth usage" "openssl x509 -in '$CLIENT_NAME/client.pem' -text -noout | grep 'TLS Web Client Authentication'"
    run_test "Client is not CA" "openssl x509 -in '$CLIENT_NAME/client.pem' -text -noout | grep 'CA:FALSE'"
}

# Test certificate chain validation
test_certificate_chains() {
    run_test "Server bundle validates" "openssl verify -CAfile '$CA_NAME/ca.pem' '$SERVER_DOMAIN/server-bundle.pem'"
    run_test "Client bundle validates" "openssl verify -CAfile '$CA_NAME/ca.pem' '$CLIENT_NAME/client-bundle.pem'"
    run_test "Server bundle contains CA" "grep -q 'BEGIN CERTIFICATE' '$SERVER_DOMAIN/server-bundle.pem' && [ \$(grep -c 'BEGIN CERTIFICATE' '$SERVER_DOMAIN/server-bundle.pem') -eq 2 ]"
    run_test "Client bundle contains CA" "grep -q 'BEGIN CERTIFICATE' '$CLIENT_NAME/client-bundle.pem' && [ \$(grep -c 'BEGIN CERTIFICATE' '$CLIENT_NAME/client-bundle.pem') -eq 2 ]"
}

# Test certificate expiration dates
test_certificate_dates() {
    local ca_days=$(openssl x509 -in "$CA_NAME/ca.pem" -noout -dates | grep notAfter | cut -d= -f2)
    local server_days=$(openssl x509 -in "$SERVER_DOMAIN/server.pem" -noout -dates | grep notAfter | cut -d= -f2)
    local client_days=$(openssl x509 -in "$CLIENT_NAME/client.pem" -noout -dates | grep notAfter | cut -d= -f2)

    run_test "CA certificate not expired" "openssl x509 -in '$CA_NAME/ca.pem' -checkend 0"
    run_test "Server certificate not expired" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -checkend 0"
    run_test "Client certificate not expired" "openssl x509 -in '$CLIENT_NAME/client.pem' -checkend 0"

    # Check if certificates expire in reasonable timeframes (CA: ~10 years, others: ~2 years)
    run_test "CA expires in future (>1 year)" "openssl x509 -in '$CA_NAME/ca.pem' -checkend 31536000"
    run_test "Server expires in future (>30 days)" "openssl x509 -in '$SERVER_DOMAIN/server.pem' -checkend 2592000"
    run_test "Client expires in future (>30 days)" "openssl x509 -in '$CLIENT_NAME/client.pem' -checkend 2592000"
}

# Test error conditions
test_error_conditions() {
    run_test "Server script fails without CA" "! ../server.sh test.com NonExistentCA 2>/dev/null"
    run_test "Client script fails without CA" "! ../client.sh testuser NonExistentCA 2>/dev/null"
}

# Main test execution
main() {
    log_info "Starting certificate generation tests..."

    setup

    # Run test suites
    test_ca_generation
    test_server_generation
    test_client_generation
    test_certificate_chains
    test_certificate_dates
    test_error_conditions

    # Cleanup
    cd ..
    cleanup

    # Results
    echo
    log_info "Test Results: $TESTS_PASSED/$TESTS_RUN tests passed"

    if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Run tests
main "$@"
