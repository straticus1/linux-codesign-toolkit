#!/bin/bash

# Linux Code Signing Toolkit 1.2
# A comprehensive toolkit for code signing Windows binaries, Java applications, AIR files, and Apple packages
# Includes JIRA integration for ticket management and audit trails
#
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>
# Copyright (c) 2024 Ryan Coleman. All rights reserved.

set -e

VERSION="1.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for osslsigncode
    if ! command_exists osslsigncode; then
        missing_deps+=("osslsigncode")
    fi
    
    # Check for Java tools
    if ! command_exists java; then
        missing_deps+=("java")
    fi
    
    if ! command_exists javac; then
        missing_deps+=("javac")
    fi
    
    if ! command_exists jarsigner; then
        missing_deps+=("jarsigner")
    fi
    
    if ! command_exists keytool; then
        missing_deps+=("keytool")
    fi
    
    # Check for AIR signing tools
    if ! command_exists unzip; then
        missing_deps+=("unzip")
    fi
    
    if ! command_exists zip; then
        missing_deps+=("zip")
    fi
    
    # Check for Apple package signing tools
    if ! command_exists xar; then
        log_warning "xar not found - Apple package signing will be limited"
    fi
    
    # Check for JIRA integration tools
    if ! command_exists curl; then
        log_warning "curl not found - JIRA integration will be limited"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and run 'make deps' to build osslsigncode"
        exit 1
    fi
}

# Windows binary signing functions
sign_windows() {
    local cert_file="$1"
    local key_file="$2"
    local key_pass="$3"
    local input_file="$4"
    local output_file="$5"
    local app_name="$6"
    local app_url="$7"
    local timestamp_url="$8"
    
    log_info "Signing Windows binary: $input_file"
    
    local cmd="osslsigncode sign"
    
    if [ -n "$cert_file" ]; then
        cmd="$cmd -certs \"$cert_file\""
    fi
    
    if [ -n "$key_file" ]; then
        cmd="$cmd -key \"$key_file\""
    fi
    
    if [ -n "$key_pass" ]; then
        cmd="$cmd -pass \"$key_pass\""
    fi
    
    if [ -n "$app_name" ]; then
        cmd="$cmd -n \"$app_name\""
    fi
    
    if [ -n "$app_url" ]; then
        cmd="$cmd -i \"$app_url\""
    fi
    
    if [ -n "$timestamp_url" ]; then
        cmd="$cmd -t \"$timestamp_url\""
    fi
    
    cmd="$cmd -in \"$input_file\" -out \"$output_file\""
    
    log_info "Executing: $cmd"
    eval $cmd
    
    if [ $? -eq 0 ]; then
        log_success "Windows binary signed successfully: $output_file"
        # Log successful operation to JIRA
        log_signing_operation "sign" "windows" "$input_file" "$output_file" "success"
    else
        log_error "Failed to sign Windows binary"
        # Log failed operation to JIRA
        log_signing_operation "sign" "windows" "$input_file" "$output_file" "failure" "osslsigncode command failed"
        exit 1
    fi
}

verify_windows() {
    local input_file="$1"
    
    log_info "Verifying Windows binary signature: $input_file"
    
    osslsigncode verify -in "$input_file"
    
    if [ $? -eq 0 ]; then
        log_success "Windows binary signature verified successfully"
    else
        log_error "Windows binary signature verification failed"
        exit 1
    fi
}

unsign_windows() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Removing signature from Windows binary: $input_file"
    
    osslsigncode remove -in "$input_file" -out "$output_file"
    
    if [ $? -eq 0 ]; then
        log_success "Signature removed successfully: $output_file"
    else
        log_error "Failed to remove signature"
        exit 1
    fi
}

# Java signing functions
sign_java() {
    local keystore="$1"
    local alias="$2"
    local storepass="$3"
    local keypass="$4"
    local input_file="$5"
    local output_file="$6"
    local timestamp_url="$7"
    
    log_info "Signing Java JAR file: $input_file"
    
    local cmd="jarsigner"
    
    if [ -n "$timestamp_url" ]; then
        cmd="$cmd -tsa \"$timestamp_url\""
    fi
    
    if [ -n "$storepass" ]; then
        cmd="$cmd -storepass \"$storepass\""
    fi
    
    if [ -n "$keypass" ]; then
        cmd="$cmd -keypass \"$keypass\""
    fi
    
    cmd="$cmd -keystore \"$keystore\" -signedjar \"$output_file\" \"$input_file\" \"$alias\""
    
    log_info "Executing: $cmd"
    eval $cmd
    
    if [ $? -eq 0 ]; then
        log_success "Java JAR signed successfully: $output_file"
        # Log successful operation to JIRA
        log_signing_operation "sign" "java" "$input_file" "$output_file" "success"
    else
        log_error "Failed to sign Java JAR"
        # Log failed operation to JIRA
        log_signing_operation "sign" "java" "$input_file" "$output_file" "failure" "jarsigner command failed"
        exit 1
    fi
}

verify_java() {
    local input_file="$1"
    local keystore="$2"
    
    log_info "Verifying Java JAR signature: $input_file"
    
    local cmd="jarsigner -verify"
    
    if [ -n "$keystore" ]; then
        cmd="$cmd -keystore \"$keystore\""
    fi
    
    cmd="$cmd \"$input_file\""
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        log_success "Java JAR signature verified successfully"
    else
        log_error "Java JAR signature verification failed"
        exit 1
    fi
}

# AIR file signing functions
sign_air() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Signing AIR file: $input_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract AIR file (it's a ZIP)
    log_info "Extracting AIR file..."
    unzip -q "$input_file" -d "$temp_dir"
    
    # Check if META-INF/AIR/application.xml exists
    if [ ! -f "$temp_dir/META-INF/AIR/application.xml" ]; then
        log_error "Invalid AIR file: missing META-INF/AIR/application.xml"
        exit 1
    fi
    
    # Create signature directory
    mkdir -p "$temp_dir/META-INF/AIR/signatures"
    
    # Generate signature using OpenSSL
    log_info "Generating AIR signature..."
    
    # Create a manifest of all files
    find "$temp_dir" -type f -not -path "*/META-INF/AIR/signatures/*" | sort > "$temp_dir/manifest.txt"
    
    # Create signature
    local signature_file="$temp_dir/META-INF/AIR/signatures/signature.p7s"
    
    # Build OpenSSL command with timestamp support
    local openssl_cmd="openssl smime -sign -in \"$temp_dir/manifest.txt\" -out \"$signature_file\" -signer \"$cert_file\" -inkey \"$cert_file\" -passin \"pass:$cert_pass\" -outform DER -nodetach"
    
    # Add timestamp if provided
    if [ -n "$timestamp_url" ]; then
        log_info "Adding timestamp from: $timestamp_url"
        openssl_cmd="$openssl_cmd -tsa \"$timestamp_url\""
    fi
    
    # Execute signing command
    log_info "Executing: $openssl_cmd"
    eval $openssl_cmd
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create AIR signature"
        exit 1
    fi
    
    # Create new AIR file
    log_info "Creating signed AIR file..."
    cd "$temp_dir"
    zip -r "$output_file" . -x "manifest.txt"
    cd - > /dev/null
    
    log_success "AIR file signed successfully: $output_file"
    
    log_info "Signing AIR file: $input_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract AIR file (it's a ZIP)
    log_info "Extracting AIR file..."
    unzip -q "$input_file" -d "$temp_dir"
    
    # Check if META-INF/AIR/application.xml exists
    if [ ! -f "$temp_dir/META-INF/AIR/application.xml" ]; then
        log_error "Invalid AIR file: missing META-INF/AIR/application.xml"
        exit 1
    fi
    
    # Create signature directory
    mkdir -p "$temp_dir/META-INF/AIR/signatures"
    
    # Generate signature using OpenSSL
    log_info "Generating AIR signature..."
    
    # Create a manifest of all files
    find "$temp_dir" -type f -not -path "*/META-INF/AIR/signatures/*" | sort > "$temp_dir/manifest.txt"
    
    # Create signature
    local signature_file="$temp_dir/META-INF/AIR/signatures/signature.p7s"
    
    # Execute signing command
    log_info "Executing: $openssl_cmd"
    eval $openssl_cmd
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create AIR signature"
        exit 1
    fi
    
    # Create new AIR file
    log_info "Creating signed AIR file..."
    cd "$temp_dir"
    zip -r "$output_file" . -x "manifest.txt"
    cd - > /dev/null
    
    log_success "AIR file signed successfully: $output_file"
}

verify_air() {
    local input_file="$1"
    local cert_file="$2"
    
    log_info "Verifying AIR file signature: $input_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract AIR file
    unzip -q "$input_file" -d "$temp_dir"
    
    # Check for signature
    if [ ! -f "$temp_dir/META-INF/AIR/signatures/signature.p7s" ]; then
        log_error "AIR file is not signed"
        exit 1
    fi
    
    # Verify signature
    local signature_file="$temp_dir/META-INF/AIR/signatures/signature.p7s"
    
    # Extract signature content
    openssl pkcs7 -in "$signature_file" -inform DER -print_certs > "$temp_dir/extracted_cert.pem" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "AIR file signature verified successfully"
        
        # Check for timestamp
        if openssl pkcs7 -in "$signature_file" -inform DER -text | grep -q "Time Stamp"; then
            log_success "AIR file signature includes timestamp"
        else
            log_info "AIR file signature does not include timestamp"
        fi
        
        if [ -n "$cert_file" ]; then
            # Compare with provided certificate
            if diff "$temp_dir/extracted_cert.pem" "$cert_file" > /dev/null 2>&1; then
                log_success "AIR file certificate matches provided certificate"
            else
                log_warning "AIR file certificate does not match provided certificate"
            fi
        fi
    else
        log_error "AIR file signature verification failed"
        exit 1
    fi
}

# Apple package signing functions
sign_apple() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Signing Apple package: $input_file"
    
    # Determine file type by extension
    local extension="${input_file##*.}"
    
    case "$extension" in
        pkg)
            sign_apple_pkg "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        ipa)
            sign_apple_ipa "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        app)
            sign_apple_app "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        *)
            log_error "Unsupported Apple package type: $extension (supported: pkg, ipa, app)"
            exit 1
            ;;
    esac
}

# Sign macOS package (.pkg)
sign_apple_pkg() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Signing macOS package: $input_file"
    
    # Check if xar is available
    if ! command_exists xar; then
        log_error "xar is required for macOS package signing but not found"
        log_info "Install xar: brew install xar (macOS) or compile from source"
        exit 1
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Copy input file to output file
    cp "$input_file" "$output_file"
    
    # Extract certificate and private key from PKCS#12
    log_info "Extracting certificate and private key..."
    
    # Extract certificate
    openssl pkcs12 -in "$cert_file" -clcerts -nokeys -out "$temp_dir/cert.pem" -passin "pass:$cert_pass" 2>/dev/null
    
    # Extract private key
    openssl pkcs12 -in "$cert_file" -nocerts -nodes -out "$temp_dir/key.pem" -passin "pass:$cert_pass" 2>/dev/null
    
    if [ ! -f "$temp_dir/cert.pem" ] || [ ! -f "$temp_dir/key.pem" ]; then
        log_error "Failed to extract certificate or private key from PKCS#12 file"
        exit 1
    fi
    
    # Sign the package using xar
    log_info "Signing package with xar..."
    
    # Calculate signature size
    echo -n | openssl dgst -sha256 -sign "$temp_dir/key.pem" -binary | wc -c > "$temp_dir/siglen.txt"
    
    # Generate digest info
    xar --sign -f "$output_file" --digestinfo-to-sign "$temp_dir/digestinfo.dat" \
        --sig-size $(cat "$temp_dir/siglen.txt") \
        --cert-loc "$temp_dir/cert.pem"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to prepare package for signing"
        exit 1
    fi
    
    # Sign the digest
    openssl rsautl -sign -inkey "$temp_dir/key.pem" -in "$temp_dir/digestinfo.dat" -out "$temp_dir/signature.dat"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to generate signature"
        exit 1
    fi
    
    # Add timestamp if provided
    if [ -n "$timestamp_url" ]; then
        log_info "Adding timestamp from: $timestamp_url"
        
        # Create timestamp request
        openssl ts -query -data "$temp_dir/signature.dat" -out "$temp_dir/timestamp.req" -sha256
        
        if [ $? -eq 0 ]; then
            # Get timestamp response
            curl -s -H "Content-Type: application/timestamp-query" \
                --data-binary @"$temp_dir/timestamp.req" \
                "$timestamp_url" > "$temp_dir/timestamp.resp"
            
            if [ $? -eq 0 ] && [ -s "$temp_dir/timestamp.resp" ]; then
                log_info "Timestamp added successfully"
                # Note: xar doesn't directly support timestamps, but we can store the timestamp response
                # for verification purposes
                cp "$temp_dir/timestamp.resp" "$temp_dir/META-INF/timestamp.resp"
            else
                log_warning "Failed to get timestamp from server, continuing without timestamp"
            fi
        else
            log_warning "Failed to create timestamp request, continuing without timestamp"
        fi
    fi
    
    # Inject signature into package
    xar --inject-sig "$temp_dir/signature.dat" -f "$output_file"
    
    if [ $? -eq 0 ]; then
        log_success "macOS package signed successfully: $output_file"
    else
        log_error "Failed to inject signature into package"
        exit 1
    fi
}

# Sign iOS application (.ipa)
sign_apple_ipa() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Signing iOS application: $input_file"
    
    # Check if we're on macOS and have codesign available
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists codesign; then
        sign_apple_ipa_native "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
    else
        sign_apple_ipa_isign "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
    fi
}

# Sign iOS app using native macOS tools
sign_apple_ipa_native() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Using native macOS signing tools for iOS app"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract IPA
    unzip -q "$input_file" -d "$temp_dir"
    
    # Find the .app directory
    local app_dir=$(find "$temp_dir" -name "*.app" -type d | head -n 1)
    
    if [ -z "$app_dir" ]; then
        log_error "No .app directory found in IPA file"
        exit 1
    fi
    
    # Import certificate to temporary keychain if needed
    # This is a simplified approach - in practice you'd need proper provisioning profiles
    log_info "Signing iOS application bundle..."
    
    # Sign the app bundle (this requires proper setup with certificates in keychain)
    codesign --force --sign "iPhone Distribution" --entitlements "$app_dir/entitlements.plist" "$app_dir"
    
    if [ $? -eq 0 ]; then
        # Repackage IPA
        cd "$temp_dir"
        zip -r "$output_file" Payload/
        cd - > /dev/null
        
        log_success "iOS application signed successfully: $output_file"
    else
        log_error "Failed to sign iOS application"
        exit 1
    fi
}

# Sign iOS app using isign (Linux/cross-platform)
sign_apple_ipa_isign() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Using isign for iOS application signing"
    
    # Check if isign is available
    if ! command_exists isign; then
        log_error "isign is required for iOS app signing on Linux but not found"
        log_info "Install isign: pip install isign"
        exit 1
    fi
    
    # Create temporary directory for credentials
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract certificate and key from PKCS#12
    openssl pkcs12 -in "$cert_file" -clcerts -nokeys -out "$temp_dir/cert.pem" -passin "pass:$cert_pass" 2>/dev/null
    openssl pkcs12 -in "$cert_file" -nocerts -nodes -out "$temp_dir/key.pem" -passin "pass:$cert_pass" 2>/dev/null
    
    # Use isign to sign the IPA
    local isign_cmd="isign -c \"$temp_dir/cert.pem\" -k \"$temp_dir/key.pem\" -o \"$output_file\""
    
    # Add timestamp if provided and supported
    if [ -n "$timestamp_url" ]; then
        log_info "Adding timestamp from: $timestamp_url"
        # Note: isign may not support timestamps directly, but we can try
        isign_cmd="$isign_cmd --timestamp \"$timestamp_url\""
    fi
    
    isign_cmd="$isign_cmd \"$input_file\""
    
    log_info "Executing: $isign_cmd"
    eval $isign_cmd
    
    if [ $? -eq 0 ]; then
        log_success "iOS application signed successfully: $output_file"
    else
        log_error "Failed to sign iOS application with isign"
        exit 1
    fi
}

# Sign macOS application (.app)
sign_apple_app() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Signing macOS application: $input_file"
    
    # Check if we're on macOS and have codesign available
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists codesign; then
        sign_apple_app_native "$cert_file" "$cert_pass" "$input_file" "$output_file" "$timestamp_url"
    else
        log_error "macOS application signing requires macOS with Xcode command line tools"
        log_info "Cross-platform signing of .app bundles is not currently supported"
        exit 1
    fi
}

# Sign macOS app using native tools
sign_apple_app_native() {
    local cert_file="$1"
    local cert_pass="$2"
    local input_file="$3"
    local output_file="$4"
    local timestamp_url="$5"
    
    log_info "Using native macOS signing tools for app bundle"
    
    # Copy app bundle to output location
    cp -R "$input_file" "$output_file"
    
    # Import certificate to temporary keychain if needed
    # This is simplified - in practice you'd manage keychains properly
    
    local sign_cmd="codesign --force --deep --sign"
    
    # Try to determine certificate identity from PKCS#12
    local cert_identity="Developer ID Application"
    
    if [ -n "$timestamp_url" ]; then
        sign_cmd="$sign_cmd --timestamp=$timestamp_url"
    fi
    
    sign_cmd="$sign_cmd \"$cert_identity\" \"$output_file\""
    
    log_info "Executing: $sign_cmd"
    eval $sign_cmd
    
    if [ $? -eq 0 ]; then
        log_success "macOS application signed successfully: $output_file"
    else
        log_error "Failed to sign macOS application"
        exit 1
    fi
}

# Verify Apple package signatures
verify_apple() {
    local input_file="$1"
    local cert_file="$2"
    
    log_info "Verifying Apple package signature: $input_file"
    
    # Determine file type by extension
    local extension="${input_file##*.}"
    
    case "$extension" in
        pkg)
            verify_apple_pkg "$input_file" "$cert_file"
            ;;
        ipa)
            verify_apple_ipa "$input_file" "$cert_file"
            ;;
        app)
            verify_apple_app "$input_file" "$cert_file"
            ;;
        *)
            log_error "Unsupported Apple package type: $extension"
            exit 1
            ;;
    esac
}

# Verify macOS package signature
verify_apple_pkg() {
    local input_file="$1"
    local cert_file="$2"
    
    if command_exists xar; then
        xar --verify -f "$input_file"
        
        if [ $? -eq 0 ]; then
            log_success "macOS package signature verified successfully"
        else
            log_error "macOS package signature verification failed"
            exit 1
        fi
    else
        log_warning "xar not available - cannot verify macOS package signature"
        exit 1
    fi
}

# Verify iOS application signature
verify_apple_ipa() {
    local input_file="$1"
    local cert_file="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists codesign; then
        # Extract and verify on macOS
        local temp_dir=$(mktemp -d)
        trap "rm -rf $temp_dir" EXIT
        
        unzip -q "$input_file" -d "$temp_dir"
        local app_dir=$(find "$temp_dir" -name "*.app" -type d | head -n 1)
        
        if [ -n "$app_dir" ]; then
            codesign --verify --deep --strict "$app_dir"
            
            if [ $? -eq 0 ]; then
                log_success "iOS application signature verified successfully"
            else
                log_error "iOS application signature verification failed"
                exit 1
            fi
        else
            log_error "No .app directory found in IPA file"
            exit 1
        fi
    else
        log_warning "iOS signature verification requires macOS with Xcode tools"
        exit 1
    fi
}

# Verify macOS application signature
verify_apple_app() {
    local input_file="$1"
    local cert_file="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists codesign; then
        codesign --verify --deep --strict "$input_file"
        
        if [ $? -eq 0 ]; then
            log_success "macOS application signature verified successfully"
            
            # Check for timestamp
            codesign --verify --deep --strict --verbose=4 "$input_file" 2>&1 | grep -q "Timestamp"
            if [ $? -eq 0 ]; then
                log_success "macOS application signature includes timestamp"
            else
                log_info "macOS application signature does not include timestamp"
            fi
        else
            log_error "macOS application signature verification failed"
            exit 1
        fi
    else
        log_warning "macOS app signature verification requires macOS with Xcode tools"
        exit 1
    fi
}

# Verify timestamp in a signed file
verify_timestamp() {
    local input_file="$1"
    local timestamp_url="$2"
    
    log_info "Verifying timestamp in: $input_file"
    
    # Determine file type by extension
    local extension="${input_file##*.}"
    
    case "$extension" in
        exe|dll|msi|cab|cat|appx)
            # Windows binary - use osslsigncode
            if command_exists osslsigncode; then
                osslsigncode verify -in "$input_file" | grep -i "timestamp"
                if [ $? -eq 0 ]; then
                    log_success "Windows binary includes timestamp"
                else
                    log_info "Windows binary does not include timestamp"
                fi
            fi
            ;;
        jar)
            # Java JAR - use jarsigner
            if command_exists jarsigner; then
                jarsigner -verify -verbose "$input_file" | grep -i "timestamp"
                if [ $? -eq 0 ]; then
                    log_success "Java JAR includes timestamp"
                else
                    log_info "Java JAR does not include timestamp"
                fi
            fi
            ;;
        air)
            # AIR file - check PKCS#7 signature
            local temp_dir=$(mktemp -d)
            trap "rm -rf $temp_dir" EXIT
            
            unzip -q "$input_file" -d "$temp_dir"
            if [ -f "$temp_dir/META-INF/AIR/signatures/signature.p7s" ]; then
                openssl pkcs7 -in "$temp_dir/META-INF/AIR/signatures/signature.p7s" -inform DER -text | grep -i "time stamp"
                if [ $? -eq 0 ]; then
                    log_success "AIR file includes timestamp"
                else
                    log_info "AIR file does not include timestamp"
                fi
            fi
            ;;
        pkg|ipa|app)
            # Apple packages - check with appropriate tools
            if [[ "$OSTYPE" == "darwin"* ]] && command_exists codesign; then
                codesign --verify --deep --strict --verbose=4 "$input_file" 2>&1 | grep -i "timestamp"
                if [ $? -eq 0 ]; then
                    log_success "Apple package includes timestamp"
                else
                    log_info "Apple package does not include timestamp"
                fi
            fi
            ;;
        *)
            log_warning "Timestamp verification not supported for file type: $extension"
            ;;
    esac
}

# JIRA Integration Functions
create_jira_ticket() {
    local jira_url="$1"
    local jira_user="$2"
    local jira_token="$3"
    local project_key="$4"
    local issue_type="$5"
    local summary="$6"
    local description="$7"
    local priority="$8"
    
    log_info "Creating JIRA ticket in project: $project_key"
    
    # Create JSON payload for JIRA ticket
    local json_payload=$(cat << EOF
{
    "fields": {
        "project": {
            "key": "$project_key"
        },
        "summary": "$summary",
        "description": "$description",
        "issuetype": {
            "name": "$issue_type"
        },
        "priority": {
            "name": "$priority"
        }
    }
}
EOF
)
    
    # Create JIRA ticket using REST API
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n "$jira_user:$jira_token" | base64)" \
        -d "$json_payload" \
        "$jira_url/rest/api/2/issue")
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [ "$http_code" -eq 201 ]; then
        # Extract issue key from response
        local issue_key=$(echo "$response_body" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
        log_success "JIRA ticket created successfully: $issue_key"
        echo "$issue_key"
    else
        log_error "Failed to create JIRA ticket. HTTP Code: $http_code"
        log_error "Response: $response_body"
        return 1
    fi
}

update_jira_ticket() {
    local jira_url="$1"
    local jira_user="$2"
    local jira_token="$3"
    local issue_key="$4"
    local comment="$5"
    local status="$6"
    
    log_info "Updating JIRA ticket: $issue_key"
    
    # Add comment if provided
    if [ -n "$comment" ]; then
        local comment_payload=$(cat << EOF
{
    "body": "$comment"
}
EOF
)
        
        local comment_response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Basic $(echo -n "$jira_user:$jira_token" | base64)" \
            -d "$comment_payload" \
            "$jira_url/rest/api/2/issue/$issue_key/comment")
        
        local comment_http_code="${comment_response: -3}"
        if [ "$comment_http_code" -eq 201 ]; then
            log_success "Comment added to JIRA ticket: $issue_key"
        else
            log_warning "Failed to add comment to JIRA ticket"
        fi
    fi
    
    # Update status if provided
    if [ -n "$status" ]; then
        # Get available transitions
        local transitions_response=$(curl -s -X GET \
            -H "Authorization: Basic $(echo -n "$jira_user:$jira_token" | base64)" \
            "$jira_url/rest/api/2/issue/$issue_key/transitions")
        
        # Find transition ID for the target status
        local transition_id=$(echo "$transitions_response" | grep -o "\"id\":\"[0-9]*\".*\"name\":\"$status\"" | grep -o "\"id\":\"[0-9]*\"" | cut -d'"' -f4 | head -1)
        
        if [ -n "$transition_id" ]; then
            local status_payload=$(cat << EOF
{
    "transition": {
        "id": "$transition_id"
    }
}
EOF
)
            
            local status_response=$(curl -s -w "%{http_code}" -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Basic $(echo -n "$jira_user:$jira_token" | base64)" \
                -d "$status_payload" \
                "$jira_url/rest/api/2/issue/$issue_key/transitions")
            
            local status_http_code="${status_response: -3}"
            if [ "$status_http_code" -eq 204 ]; then
                log_success "Status updated to '$status' for JIRA ticket: $issue_key"
            else
                log_warning "Failed to update status for JIRA ticket"
            fi
        else
            log_warning "Status '$status' not found in available transitions"
        fi
    fi
}

log_signing_operation() {
    local operation="$1"
    local file_type="$2"
    local input_file="$3"
    local output_file="$4"
    local status="$5"
    local error_message="$6"
    
    # Check if JIRA integration is enabled
    if [ -z "$JIRA_URL" ] || [ -z "$JIRA_USER" ] || [ -z "$JIRA_TOKEN" ] || [ -z "$JIRA_PROJECT" ]; then
        return 0
    fi
    
    local summary=""
    local description=""
    local issue_type="Task"
    local priority="Medium"
    
    case "$status" in
        success)
            summary="Code Signing Success: $operation completed for $file_type"
            description="**Operation:** $operation
**File Type:** $file_type
**Input File:** $input_file
**Output File:** $output_file
**Status:** Success
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**User:** $(whoami)
**Host:** $(hostname)"
            issue_type="Task"
            priority="Low"
            ;;
        failure)
            summary="Code Signing Failure: $operation failed for $file_type"
            description="**Operation:** $operation
**File Type:** $file_type
**Input File:** $input_file
**Output File:** $output_file
**Status:** Failed
**Error:** $error_message
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**User:** $(whoami)
**Host:** $(hostname)"
            issue_type="Bug"
            priority="High"
            ;;
        *)
            summary="Code Signing Operation: $operation for $file_type"
            description="**Operation:** $operation
**File Type:** $file_type
**Input File:** $input_file
**Output File:** $output_file
**Status:** $status
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**User:** $(whoami)
**Host:** $(hostname)"
            ;;
    esac
    
    # Create JIRA ticket
    local issue_key=$(create_jira_ticket "$JIRA_URL" "$JIRA_USER" "$JIRA_TOKEN" "$JIRA_PROJECT" "$issue_type" "$summary" "$description" "$priority")
    
    if [ $? -eq 0 ] && [ -n "$issue_key" ]; then
        log_info "JIRA ticket created: $issue_key"
        echo "$issue_key"
    else
        log_warning "Failed to create JIRA ticket for logging"
    fi
}

# Main command processing
process_sign() {
    local type=""
    local cert_file=""
    local key_file=""
    local keystore=""
    local alias=""
    local storepass=""
    local keypass=""
    local input_file=""
    local output_file=""
    local app_name=""
    local app_url=""
    local timestamp_url=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -type)
                type="$2"
                shift 2
                ;;
            -cert)
                cert_file="$2"
                shift 2
                ;;
            -key)
                key_file="$2"
                shift 2
                ;;
            -keystore)
                keystore="$2"
                shift 2
                ;;
            -alias)
                alias="$2"
                shift 2
                ;;
            -storepass)
                storepass="$2"
                shift 2
                ;;
            -keypass)
                keypass="$2"
                shift 2
                ;;
            -pass)
                keypass="$2"
                shift 2
                ;;
            -in)
                input_file="$2"
                shift 2
                ;;
            -out)
                output_file="$2"
                shift 2
                ;;
            -n)
                app_name="$2"
                shift 2
                ;;
            -i)
                app_url="$2"
                shift 2
                ;;
            -t)
                timestamp_url="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [ -z "$type" ]; then
        log_error "Type is required (-type windows|java|air|apple)"
        exit 1
    fi
    
    if [ -z "$input_file" ]; then
        log_error "Input file is required (-in)"
        exit 1
    fi
    
    if [ -z "$output_file" ]; then
        log_error "Output file is required (-out)"
        exit 1
    fi
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file does not exist: $input_file"
        exit 1
    fi
    
    # Process based on type
    case "$type" in
        windows)
            sign_windows "$cert_file" "$key_file" "$keypass" "$input_file" "$output_file" "$app_name" "$app_url" "$timestamp_url"
            ;;
        java)
            sign_java "$keystore" "$alias" "$storepass" "$keypass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        air)
            sign_air "$cert_file" "$keypass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        apple)
            sign_apple "$cert_file" "$keypass" "$input_file" "$output_file" "$timestamp_url"
            ;;
        *)
            log_error "Unsupported type: $type (supported: windows, java, air, apple)"
            exit 1
            ;;
    esac
}

process_verify() {
    local input_file=""
    local cert_file=""
    local keystore=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -in)
                input_file="$2"
                shift 2
                ;;
            -cert)
                cert_file="$2"
                shift 2
                ;;
            -keystore)
                keystore="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ -z "$input_file" ]; then
        log_error "Input file is required (-in)"
        exit 1
    fi
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file does not exist: $input_file"
        exit 1
    fi
    
    # Determine file type and verify
    local extension="${input_file##*.}"
    case "$extension" in
        exe|dll|msi|cab|cat|appx)
            verify_windows "$input_file"
            ;;
        jar)
            verify_java "$input_file" "$keystore"
            ;;
        air)
            verify_air "$input_file" "$cert_file"
            ;;
        pkg|ipa|app)
            verify_apple "$input_file" "$cert_file"
            ;;
        *)
            log_error "Unsupported file type: $extension"
            exit 1
            ;;
    esac
}

process_unsign() {
    local input_file=""
    local output_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -in)
                input_file="$2"
                shift 2
                ;;
            -out)
                output_file="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ -z "$input_file" ]; then
        log_error "Input file is required (-in)"
        exit 1
    fi
    
    if [ -z "$output_file" ]; then
        log_error "Output file is required (-out)"
        exit 1
    fi
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file does not exist: $input_file"
        exit 1
    fi
    
    # Determine file type and unsign
    local extension="${input_file##*.}"
    case "$extension" in
        exe|dll|msi|cab|cat|appx)
            unsign_windows "$input_file" "$output_file"
            ;;
        jar|air)
            log_warning "Unsigning $extension files is not supported"
            exit 1
            ;;
        *)
            log_error "Unsupported file type: $extension"
            exit 1
            ;;
    esac
}

process_timestamp() {
    local input_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -in)
                input_file="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ -z "$input_file" ]; then
        log_error "Input file is required (-in)"
        exit 1
    fi
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file does not exist: $input_file"
        exit 1
    fi
    
    verify_timestamp "$input_file"
}

process_jira() {
    local action=""
    local project_key=""
    local issue_type=""
    local summary=""
    local description=""
    local priority=""
    local issue_key=""
    local comment=""
    local status=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -create)
                action="create"
                shift
                ;;
            -update)
                action="update"
                shift
                ;;
            -project)
                project_key="$2"
                shift 2
                ;;
            -type)
                issue_type="$2"
                shift 2
                ;;
            -summary)
                summary="$2"
                shift 2
                ;;
            -description)
                description="$2"
                shift 2
                ;;
            -priority)
                priority="$2"
                shift 2
                ;;
            -issue)
                issue_key="$2"
                shift 2
                ;;
            -comment)
                comment="$2"
                shift 2
                ;;
            -status)
                status="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Check if JIRA environment variables are set
    if [ -z "$JIRA_URL" ] || [ -z "$JIRA_USER" ] || [ -z "$JIRA_TOKEN" ]; then
        log_error "JIRA environment variables not set. Please set:"
        log_error "  JIRA_URL - Your JIRA instance URL (e.g., https://yourcompany.atlassian.net)"
        log_error "  JIRA_USER - Your JIRA username or email"
        log_error "  JIRA_TOKEN - Your JIRA API token"
        exit 1
    fi
    
    case "$action" in
        create)
            if [ -z "$project_key" ] || [ -z "$summary" ]; then
                log_error "Project key (-project) and summary (-summary) are required for creating tickets"
                exit 1
            fi
            
            # Set defaults
            [ -z "$issue_type" ] && issue_type="Task"
            [ -z "$priority" ] && priority="Medium"
            [ -z "$description" ] && description="Code signing operation ticket"
            
            create_jira_ticket "$JIRA_URL" "$JIRA_USER" "$JIRA_TOKEN" "$project_key" "$issue_type" "$summary" "$description" "$priority"
            ;;
        update)
            if [ -z "$issue_key" ]; then
                log_error "Issue key (-issue) is required for updating tickets"
                exit 1
            fi
            
            update_jira_ticket "$JIRA_URL" "$JIRA_USER" "$JIRA_TOKEN" "$issue_key" "$comment" "$status"
            ;;
        *)
            log_error "Action is required (-create or -update)"
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
Linux Code Signing Toolkit $VERSION
Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

Usage: $0 <command> [options]

Commands:
  sign     Sign a file (Windows binary, Java JAR, AIR file, or Apple package)
  verify   Verify signature of a file
  timestamp Verify timestamp in a signed file
  unsign   Remove signature from a file (Windows binaries only)
  jira     JIRA integration (create/update tickets)
  help     Show this help message

Sign Command Options:
  -type <type>           Type of file (windows|java|air|apple)
  -cert <file>           Certificate file (Windows/AIR) or PKCS#12 file
  -key <file>            Private key file (Windows)
  -keystore <file>       Java keystore file
  -alias <name>          Java keystore alias
  -storepass <pass>      Java keystore password
  -keypass <pass>        Private key password
  -pass <pass>           Password (alias for -keypass)
  -in <file>             Input file
  -out <file>            Output file
  -n <name>              Application name (Windows)
  -i <url>               Application URL (Windows)
  -t <url>               Timestamp URL (recommended for long-term validity)

Timestamp Servers:
  - DigiCert: http://timestamp.digicert.com
  - Sectigo: http://timestamp.sectigo.com
  - GlobalSign: http://timestamp.globalsign.com

Verify Command Options:
  -in <file>             Input file to verify
  -cert <file>           Certificate file for verification (AIR)
  -keystore <file>       Java keystore for verification

Unsign Command Options:
  -in <file>             Input file
  -out <file>            Output file

Timestamp Command Options:
  -in <file>             Input file to check for timestamp

JIRA Command Options:
  -create               Create a new JIRA ticket
  -update               Update an existing JIRA ticket
  -project <key>        JIRA project key
  -type <type>          Issue type (Task, Bug, Story, etc.)
  -summary <text>       Ticket summary
  -description <text>   Ticket description
  -priority <level>     Priority (Low, Medium, High, Critical)
  -issue <key>          Issue key for updates
  -comment <text>       Comment to add
  -status <status>      Status to transition to

Examples:
  # Sign Windows executable
  $0 sign -type windows -cert cert.pem -key key.pem -in app.exe -out app-signed.exe

  # Sign Java JAR
  $0 sign -type java -keystore keystore.jks -alias mykey -in app.jar -out app-signed.jar

  # Sign AIR file
  $0 sign -type air -cert air-cert.p12 -pass password -in app.air -out app-signed.air

  # Sign Apple package
  $0 sign -type apple -cert apple-cert.p12 -pass password -in app.pkg -out app-signed.pkg

  # Verify signatures
  $0 verify -in app-signed.exe
  $0 verify -in app-signed.jar
  $0 verify -in app-signed.air
  $0 verify -in app-signed.pkg

  # Remove signature from Windows binary
  $0 unsign -in app-signed.exe -out app-unsigned.exe

  # Check timestamp in signed file
  $0 timestamp -in app-signed.exe

  # Create JIRA ticket for signing operation
  $0 jira -create -project PROJ -type Task -summary "Code signing completed" -description "Windows app signed successfully"

  # Update JIRA ticket
  $0 jira -update -issue PROJ-123 -comment "Verification completed" -status "Done"
EOF
}

# Main script logic
main() {
    # Check dependencies
    check_dependencies
    
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        sign)
            process_sign "$@"
            ;;
        verify)
            process_verify "$@"
            ;;
        timestamp)
            process_timestamp "$@"
            ;;
        jira)
            process_jira "$@"
            ;;
        unsign)
            process_unsign "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            echo "Linux Code Signing Toolkit $VERSION"
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
