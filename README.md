# Linux Code Signing Toolkit 1.0

A comprehensive toolkit for code signing Windows binaries, Java applications, AIR files, and Apple packages on Linux and macOS systems.

**Designed and Developed by:** Ryan Coleman <coleman.ryan@gmail.com>

## Features

- **Windows Binary Signing**: Sign PE, CAB, CAT, MSI, APPX, and script files using osslsigncode
- **Java Code Signing**: Support for JAR signing using jarsigner and keytool
- **AIR File Signing**: Sign Adobe AIR (.air) files for distribution
- **Apple Package Signing**: Sign macOS packages (.pkg), iOS apps (.ipa), and macOS apps (.app)
- **Signature Management**: Sign, unsign, resign, verify, and delete signatures
- **Cross-Platform**: Works on Linux and macOS

## Supported Operations

### Windows Binaries (via osslsigncode)
- Sign executables with Authenticode certificates
- Add timestamps to signatures (recommended for long-term validity)
- Verify existing signatures
- Remove signatures (where applicable)
- Resign files with new certificates

### Java Applications (via JDK tools)
- Sign JAR files with jarsigner
- Create and manage keystores with keytool
- Verify JAR signatures
- Manage certificate chains

### Adobe AIR Files
- Sign AIR files for distribution
- Verify AIR signatures
- Manage AIR certificates
- Support for timestamping (PKCS#7 timestamps)

### Apple Packages
- Sign macOS installer packages (.pkg)
- Sign iOS applications (.ipa)
- Sign macOS applications (.app)
- Support for timestamping (where applicable)
- Support for notarization workflows

## Prerequisites

- CMake 3.17 or newer
- OpenSSL development libraries
- Java Development Kit (JDK) 8 or newer
- Build tools (gcc/clang, make)
- xar (for macOS package signing)
- isign (for iOS app signing on Linux)

## Installation

### Ubuntu/Debian
```bash
sudo apt update && sudo apt install cmake libssl-dev libcurl4-openssl-dev zlib1g-dev python3 openjdk-11-jdk
# For Apple package signing
pip install isign
```

### macOS
```bash
brew install cmake pkg-config openssl@1.1 openjdk xar
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
# For iOS signing on macOS
pip install isign
```

## Building

```bash
# Clone and build osslsigncode
git clone https://github.com/mtrojnar/osslsigncode.git
cd osslsigncode
mkdir build && cd build
cmake -S ..
cmake --build .
sudo cmake --install .

# Build the toolkit wrapper
cd ../..
make
```

## Usage

```bash
# Sign a Windows executable
./codesign-toolkit sign -type windows -cert cert.pem -key key.pem -in app.exe -out app-signed.exe

# Sign a JAR file
./codesign-toolkit sign -type java -keystore keystore.jks -alias mykey -in app.jar -out app-signed.jar

# Sign an AIR file
./codesign-toolkit sign -type air -cert air-cert.p12 -pass password -in app.air -out app-signed.air

# Sign an Apple package
./codesign-toolkit sign -type apple -cert apple-cert.p12 -pass password -in app.pkg -out app-signed.pkg

# Verify signatures
./codesign-toolkit verify -in app-signed.exe
./codesign-toolkit verify -in app-signed.jar
./codesign-toolkit verify -in app-signed.air
./codesign-toolkit verify -in app-signed.pkg

# Check timestamp in signed file
./codesign-toolkit timestamp -in app-signed.exe

# Remove signatures
./codesign-toolkit unsign -in app-signed.exe -out app-unsigned.exe
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

**Note:** This project incorporates osslsigncode which is licensed under GPL-3.0. The osslsigncode component retains its original GPL-3.0 license, while the toolkit wrapper and additional functionality is MIT licensed.

## Author

**Ryan Coleman**  
Email: coleman.ryan@gmail.com  
GitHub: [Ryan Coleman](https://github.com/ryancoleman)

Designed and developed the Linux Code Signing Toolkit to provide comprehensive cross-platform code signing capabilities for Windows, Java, AIR, and Apple package formats.
