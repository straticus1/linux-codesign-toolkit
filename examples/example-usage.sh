#!/bin/bash

# Example usage of Linux Code Signing Toolkit
# This script demonstrates various signing operations
#
# Part of Linux Code Signing Toolkit 1.0
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLKIT="$PROJECT_DIR/codesign-toolkit"
CERT_DIR="$PROJECT_DIR/certs"
EXAMPLE_DIR="$SCRIPT_DIR/example-files"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Create example files
create_example_files() {
    log_info "Creating example files..."
    
    mkdir -p "$EXAMPLE_DIR"
    
    # Create a simple Windows executable (text file for demo)
    cat > "$EXAMPLE_DIR/example-app.exe" << 'EOF'
#!/bin/bash
echo "This is an example Windows application"
echo "In a real scenario, this would be a compiled .exe file"
EOF
    
    # Create a Java application
    cat > "$EXAMPLE_DIR/ExampleApp.java" << 'EOF'
public class ExampleApp {
    public static void main(String[] args) {
        System.out.println("This is an example Java application");
        System.out.println("Version: 1.0.0");
    }
}
EOF
    
    # Compile and create JAR
    cd "$EXAMPLE_DIR"
    javac ExampleApp.java
    jar cf example-app.jar ExampleApp.class
    cd - > /dev/null
    
    # Create AIR application structure
    mkdir -p "$EXAMPLE_DIR/air-app/META-INF/AIR"
    cat > "$EXAMPLE_DIR/air-app/META-INF/AIR/application.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://ns.adobe.com/air/application/1.0">
    <id>com.example.myapp</id>
    <versionNumber>1.0.0</versionNumber>
    <filename>MyApp</filename>
    <name>My Example Application</name>
    <description>An example AIR application</description>
    <copyright>2024 Example Corp</copyright>
</application>
EOF
    
    echo "Example AIR application content" > "$EXAMPLE_DIR/air-app/app.txt"
    
    cd "$EXAMPLE_DIR/air-app"
    zip -r ../example-app.air .
    cd - > /dev/null
}

# Example 1: Sign Windows executable
example_windows_signing() {
    log_info "Example 1: Signing Windows executable"
    
    echo "Command:"
    echo "  $TOOLKIT sign -type windows \\"
    echo "    -cert $CERT_DIR/test-cert.pem \\"
    echo "    -key $CERT_DIR/test-key.pem \\"
    echo "    -pass testpass \\"
    echo "    -n \"Example Application\" \\"
    echo "    -i \"https://example.com\" \\"
    echo "    -t \"http://timestamp.digicert.com\" \\"
    echo "    -in $EXAMPLE_DIR/example-app.exe \\"
    echo "    -out $EXAMPLE_DIR/example-app-signed.exe"
    echo ""
    
    $TOOLKIT sign -type windows \
        -cert "$CERT_DIR/test-cert.pem" \
        -key "$CERT_DIR/test-key.pem" \
        -pass testpass \
        -n "Example Application" \
        -i "https://example.com" \
        -t "http://timestamp.digicert.com" \
        -in "$EXAMPLE_DIR/example-app.exe" \
        -out "$EXAMPLE_DIR/example-app-signed.exe"
    
    log_success "Windows executable signed successfully!"
    echo ""
}

# Example 2: Sign Java JAR
example_java_signing() {
    log_info "Example 2: Signing Java JAR file"
    
    echo "Command:"
    echo "  $TOOLKIT sign -type java \\"
    echo "    -keystore $CERT_DIR/test-keystore.jks \\"
    echo "    -alias testkey \\"
    echo "    -storepass testpass \\"
    echo "    -keypass testpass \\"
    echo "    -t \"http://timestamp.digicert.com\" \\"
    echo "    -in $EXAMPLE_DIR/example-app.jar \\"
    echo "    -out $EXAMPLE_DIR/example-app-signed.jar"
    echo ""
    
    $TOOLKIT sign -type java \
        -keystore "$CERT_DIR/test-keystore.jks" \
        -alias testkey \
        -storepass testpass \
        -keypass testpass \
        -t "http://timestamp.digicert.com" \
        -in "$EXAMPLE_DIR/example-app.jar" \
        -out "$EXAMPLE_DIR/example-app-signed.jar"
    
    log_success "Java JAR signed successfully!"
    echo ""
}

# Example 3: Sign AIR file
example_air_signing() {
    log_info "Example 3: Signing AIR file"
    
    echo "Command:"
    echo "  $TOOLKIT sign -type air \\"
    echo "    -cert $CERT_DIR/test-air.p12 \\"
    echo "    -pass testpass \\"
    echo "    -t \"http://timestamp.digicert.com\" \\"
    echo "    -in $EXAMPLE_DIR/example-app.air \\"
    echo "    -out $EXAMPLE_DIR/example-app-signed.air"
    echo ""
    
    $TOOLKIT sign -type air \
        -cert "$CERT_DIR/test-air.p12" \
        -pass testpass \
        -t "http://timestamp.digicert.com" \
        -in "$EXAMPLE_DIR/example-app.air" \
        -out "$EXAMPLE_DIR/example-app-signed.air"
    
    log_success "AIR file signed successfully!"
    echo ""
}

# Example 4: Verify signatures
example_verification() {
    log_info "Example 4: Verifying signatures"
    
    echo "Verifying Windows executable:"
    $TOOLKIT verify -in "$EXAMPLE_DIR/example-app-signed.exe"
    echo ""
    
    echo "Verifying Java JAR:"
    $TOOLKIT verify -in "$EXAMPLE_DIR/example-app-signed.jar"
    echo ""
    
    echo "Verifying AIR file:"
    $TOOLKIT verify -in "$EXAMPLE_DIR/example-app-signed.air"
    echo ""
    
    log_success "All signatures verified successfully!"
}

# Example 5: Remove signature (Windows only)
example_unsigning() {
    log_info "Example 5: Removing signature from Windows executable"
    
    echo "Command:"
    echo "  $TOOLKIT unsign \\"
    echo "    -in $EXAMPLE_DIR/example-app-signed.exe \\"
    echo "    -out $EXAMPLE_DIR/example-app-unsigned.exe"
    echo ""
    
    $TOOLKIT unsign \
        -in "$EXAMPLE_DIR/example-app-signed.exe" \
        -out "$EXAMPLE_DIR/example-app-unsigned.exe"
    
    log_success "Signature removed successfully!"
}

# Main execution
main() {
    log_info "Linux Code Signing Toolkit - Example Usage"
    echo ""
    
    # Check if toolkit exists
    if [ ! -f "$TOOLKIT" ]; then
        echo "Error: Toolkit not found. Please run 'make' to build it first."
        exit 1
    fi
    
    # Check if certificates exist
    if [ ! -f "$CERT_DIR/test-cert.pem" ]; then
        echo "Error: Test certificates not found. Please run 'scripts/create-test-certificates.sh' first."
        exit 1
    fi
    
    # Create example files
    create_example_files
    
    # Run examples
    example_windows_signing
    example_java_signing
    example_air_signing
    example_verification
    example_unsigning
    
    echo ""
    log_success "All examples completed successfully!"
    echo ""
    echo "Generated files:"
    echo "  - $EXAMPLE_DIR/example-app-signed.exe"
    echo "  - $EXAMPLE_DIR/example-app-signed.jar"
    echo "  - $EXAMPLE_DIR/example-app-signed.air"
    echo "  - $EXAMPLE_DIR/example-app-unsigned.exe"
}

# Run main function
main "$@"
