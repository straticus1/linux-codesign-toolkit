#!/bin/bash

# Test suite for Linux Code Signing Toolkit
# This script runs comprehensive tests to verify all functionality
#
# Part of Linux Code Signing Toolkit 1.0
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLKIT="$PROJECT_DIR/codesign-toolkit"
CERT_DIR="$PROJECT_DIR/certs"
TEST_DIR="$SCRIPT_DIR/test-files"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log_info "Running test: $test_name"
    
    if eval "$test_command"; then
        log_success "Test passed: $test_name"
        ((TESTS_PASSED++))
    else
        log_error "Test failed: $test_name"
        ((TESTS_FAILED++))
    fi
}

# Setup test environment
setup_tests() {
    log_info "Setting up test environment..."
    
    # Create test directories
    mkdir -p "$TEST_DIR"
    mkdir -p "$CERT_DIR"
    
    # Generate test certificates if they don't exist
    if [ ! -f "$CERT_DIR/test-cert.pem" ]; then
        log_info "Generating test certificates..."
        "$SCRIPT_DIR/../scripts/create-test-certificates.sh"
    fi
    
    # Create test files
    create_test_files
}

# Create test files for signing
create_test_files() {
    log_info "Creating test files..."
    
    # Create a simple test executable (just a text file for testing)
    echo "#!/bin/bash" > "$TEST_DIR/test-app.sh"
    echo "echo 'Hello, World!'" >> "$TEST_DIR/test-app.sh"
    chmod +x "$TEST_DIR/test-app.sh"
    
    # Create a test JAR file
    cat > "$TEST_DIR/TestApp.java" << 'EOF'
public class TestApp {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF
    
    cd "$TEST_DIR"
    javac TestApp.java
    jar cf test-app.jar TestApp.class
    cd - > /dev/null
    
    # Create a test AIR file structure
    mkdir -p "$TEST_DIR/air-app/META-INF/AIR"
    cat > "$TEST_DIR/air-app/META-INF/AIR/application.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://ns.adobe.com/air/application/1.0">
    <id>com.example.testapp</id>
    <versionNumber>1.0.0</versionNumber>
    <filename>TestApp</filename>
    <name>Test Application</name>
</application>
EOF
    
    echo "Test application content" > "$TEST_DIR/air-app/test.txt"
    
    cd "$TEST_DIR/air-app"
    zip -r ../test-app.air .
    cd - > /dev/null
    
    # Create a test macOS package structure
    mkdir -p "$TEST_DIR/pkg-contents"
    echo "Test package content" > "$TEST_DIR/pkg-contents/test.txt"
    
    # Create a simple test package (this is simplified - real packages are more complex)
    cd "$TEST_DIR/pkg-contents"
    if command -v xar >/dev/null 2>&1; then
        xar -cf ../test-app.pkg .
    else
        # Fallback: create a zip file with .pkg extension for testing
        zip -r ../test-app.pkg .
    fi
    cd - > /dev/null
    
    # Create a test iOS app structure (simplified)
    mkdir -p "$TEST_DIR/ios-app/Payload/TestApp.app"
    cat > "$TEST_DIR/ios-app/Payload/TestApp.app/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.testapp</string>
    <key>CFBundleName</key>
    <string>TestApp</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
    
    echo "Test iOS app content" > "$TEST_DIR/ios-app/Payload/TestApp.app/TestApp"
    
    cd "$TEST_DIR/ios-app"
    zip -r ../test-app.ipa .
    cd - > /dev/null
}

# Test Windows binary signing
test_windows_signing() {
    log_info "Testing Windows binary signing..."
    
    # Test signing with PEM certificate
    run_test "Windows signing with PEM cert" \
        "$TOOLKIT sign -type windows -cert $CERT_DIR/test-cert.pem -key $CERT_DIR/test-key.pem -pass testpass -in $TEST_DIR/test-app.sh -out $TEST_DIR/test-app-signed.exe"
    
    # Test verification
    run_test "Windows signature verification" \
        "$TOOLKIT verify -in $TEST_DIR/test-app-signed.exe"
    
    # Test unsigning
    run_test "Windows signature removal" \
        "$TOOLKIT unsign -in $TEST_DIR/test-app-signed.exe -out $TEST_DIR/test-app-unsigned.exe"
}

# Test Java JAR signing
test_java_signing() {
    log_info "Testing Java JAR signing..."
    
    # Test signing
    run_test "Java JAR signing" \
        "$TOOLKIT sign -type java -keystore $CERT_DIR/test-keystore.jks -alias testkey -storepass testpass -keypass testpass -in $TEST_DIR/test-app.jar -out $TEST_DIR/test-app-signed.jar"
    
    # Test verification
    run_test "Java JAR signature verification" \
        "$TOOLKIT verify -in $TEST_DIR/test-app-signed.jar"
}

# Test AIR file signing
test_air_signing() {
    log_info "Testing AIR file signing..."
    
    # Test signing
    run_test "AIR file signing" \
        "$TOOLKIT sign -type air -cert $CERT_DIR/test-air.p12 -pass testpass -in $TEST_DIR/test-app.air -out $TEST_DIR/test-app-signed.air"
    
    # Test verification
    run_test "AIR file signature verification" \
        "$TOOLKIT verify -in $TEST_DIR/test-app-signed.air"
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test missing input file
    run_test "Missing input file error" \
        "! $TOOLKIT sign -type windows -cert $CERT_DIR/test-cert.pem -key $CERT_DIR/test-key.pem -in nonexistent.exe -out test.exe"
    
    # Test missing certificate
    run_test "Missing certificate error" \
        "! $TOOLKIT sign -type windows -in $TEST_DIR/test-app.sh -out test.exe"
    
    # Test invalid file type
    run_test "Invalid file type error" \
        "! $TOOLKIT sign -type invalid -cert $CERT_DIR/test-cert.pem -in $TEST_DIR/test-app.sh -out test.exe"
}

# Test help and version
test_basic_commands() {
    log_info "Testing basic commands..."
    
    # Test help
    run_test "Help command" \
        "$TOOLKIT help > /dev/null"
    
    # Test version
    run_test "Version command" \
        "$TOOLKIT version > /dev/null"
}

# Cleanup test files
cleanup_tests() {
    log_info "Cleaning up test files..."
    rm -rf "$TEST_DIR"
}

# Main test execution
main() {
    log_info "Starting Linux Code Signing Toolkit test suite..."
    
    # Check if toolkit exists
    if [ ! -f "$TOOLKIT" ]; then
        log_error "Toolkit not found: $TOOLKIT"
        log_info "Please run 'make' to build the toolkit first"
        exit 1
    fi
    
    # Make toolkit executable
    chmod +x "$TOOLKIT"
    
    # Setup tests
    setup_tests
    
    # Run tests
    test_basic_commands
    test_windows_signing
    test_java_signing
    test_air_signing
    test_error_handling
    
    # Cleanup
    cleanup_tests
    
    # Print results
    echo ""
    log_info "Test Results:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Run main function
main "$@"
