#!/bin/bash

# Create test certificates for development and testing
# This script generates self-signed certificates for testing the code signing toolkit
#
# Part of Linux Code Signing Toolkit 1.0
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

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

# Create certificates directory
mkdir -p "$CERT_DIR"

log_info "Creating test certificates in $CERT_DIR"

# Generate OpenSSL configuration
cat > "$CERT_DIR/openssl.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = Test Organization
OU = Test Unit
CN = test.example.com

[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = codeSigning
subjectAltName = @alt_names

[alt_names]
DNS.1 = test.example.com
DNS.2 = *.test.example.com
EOF

# Generate private key
log_info "Generating private key..."
openssl genrsa -out "$CERT_DIR/test-key.pem" 2048

# Generate certificate signing request
log_info "Generating certificate signing request..."
openssl req -new -key "$CERT_DIR/test-key.pem" -out "$CERT_DIR/test.csr" -config "$CERT_DIR/openssl.conf"

# Generate self-signed certificate
log_info "Generating self-signed certificate..."
openssl x509 -req -in "$CERT_DIR/test.csr" -signkey "$CERT_DIR/test-key.pem" -out "$CERT_DIR/test-cert.pem" -days 365 -extensions v3_req -extfile "$CERT_DIR/openssl.conf"

# Create PKCS#12 file for AIR signing
log_info "Creating PKCS#12 certificate for AIR signing..."
openssl pkcs12 -export -out "$CERT_DIR/test-air.p12" -inkey "$CERT_DIR/test-key.pem" -in "$CERT_DIR/test-cert.pem" -passout pass:testpass

# Create Java keystore
log_info "Creating Java keystore..."
keytool -genkeypair -alias testkey -keyalg RSA -keysize 2048 -validity 365 \
    -keystore "$CERT_DIR/test-keystore.jks" \
    -storepass testpass -keypass testpass \
    -dname "CN=Test Organization, OU=Test Unit, O=Test Organization, L=San Francisco, ST=California, C=US"

# Create DER format certificate for Windows signing
log_info "Creating DER format certificate..."
openssl x509 -in "$CERT_DIR/test-cert.pem" -outform DER -out "$CERT_DIR/test-cert.der"

# Create DER format private key for Windows signing
log_info "Creating DER format private key..."
openssl rsa -in "$CERT_DIR/test-key.pem" -outform DER -out "$CERT_DIR/test-key.der"

# Create SPC file for Windows signing (if osslsigncode is available)
if command -v osslsigncode >/dev/null 2>&1; then
    log_info "Creating SPC file for Windows signing..."
    osslsigncode extract-certificate -in "$CERT_DIR/test-cert.pem" -out "$CERT_DIR/test-cert.spc"
else
    log_warning "osslsigncode not found, skipping SPC file creation"
fi

# Set permissions
chmod 600 "$CERT_DIR"/*.pem "$CERT_DIR"/*.der "$CERT_DIR"/*.p12 "$CERT_DIR"/*.jks

log_success "Test certificates created successfully!"
log_info "Generated files:"
echo "  - test-key.pem: Private key (PEM format)"
echo "  - test-cert.pem: Certificate (PEM format)"
echo "  - test-key.der: Private key (DER format)"
echo "  - test-cert.der: Certificate (DER format)"
echo "  - test-air.p12: PKCS#12 certificate for AIR signing (password: testpass)"
echo "  - test-keystore.jks: Java keystore (password: testpass)"
if [ -f "$CERT_DIR/test-cert.spc" ]; then
    echo "  - test-cert.spc: SPC certificate for Windows signing"
fi

log_warning "These are test certificates only. Do not use in production!"
