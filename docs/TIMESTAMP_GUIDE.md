# Timestamp Server Guide

**Linux Code Signing Toolkit 1.1**
Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

## What is Timestamping?

Timestamping is a critical feature in code signing that adds a trusted timestamp to your digital signature. This ensures that your signature remains valid even after your code signing certificate expires.

### Why Timestamping is Important

1. **Long-term Validity**: Without timestamps, signatures become invalid when certificates expire
2. **Certificate Expiration**: Code signing certificates typically expire after 1-3 years
3. **Distribution Continuity**: Timestamped signatures remain valid for the lifetime of the signed code
4. **Trust Chain**: Timestamps provide proof of when the code was signed

## Supported Timestamp Servers

The toolkit supports the following timestamp servers:

### DigiCert
- **URL**: `http://timestamp.digicert.com`
- **Protocol**: RFC 3161 Time-Stamp Protocol
- **Hash Algorithm**: SHA-256
- **Availability**: High availability, widely trusted

### Sectigo (formerly Comodo)
- **URL**: `http://timestamp.sectigo.com`
- **Protocol**: RFC 3161 Time-Stamp Protocol
- **Hash Algorithm**: SHA-256
- **Availability**: High availability, widely trusted

### GlobalSign
- **URL**: `http://timestamp.globalsign.com`
- **Protocol**: RFC 3161 Time-Stamp Protocol
- **Hash Algorithm**: SHA-256
- **Availability**: High availability, widely trusted

## Using Timestamps with Different File Types

### Windows Binaries (.exe, .dll, .msi, etc.)

```bash
# Sign with timestamp
./codesign-toolkit sign -type windows \
  -cert certificate.pem \
  -key private-key.pem \
  -pass password \
  -t "http://timestamp.digicert.com" \
  -in app.exe \
  -out app-signed.exe

# Verify timestamp
./codesign-toolkit timestamp -in app-signed.exe
```

**Implementation**: Uses osslsigncode's built-in timestamp support with `-t` parameter.

### Java Applications (.jar)

```bash
# Sign with timestamp
./codesign-toolkit sign -type java \
  -keystore keystore.jks \
  -alias mykey \
  -storepass password \
  -t "http://timestamp.digicert.com" \
  -in app.jar \
  -out app-signed.jar

# Verify timestamp
./codesign-toolkit timestamp -in app-signed.jar
```

**Implementation**: Uses jarsigner's `-tsa` parameter for timestamp authority.

### Adobe AIR Files (.air)

```bash
# Sign with timestamp
./codesign-toolkit sign -type air \
  -cert certificate.p12 \
  -pass password \
  -t "http://timestamp.digicert.com" \
  -in app.air \
  -out app-signed.air

# Verify timestamp
./codesign-toolkit timestamp -in app-signed.air
```

**Implementation**: Uses OpenSSL's `-tsa` parameter for PKCS#7 timestamp support.

### Apple Packages (.pkg, .ipa, .app)

```bash
# Sign with timestamp
./codesign-toolkit sign -type apple \
  -cert certificate.p12 \
  -pass password \
  -t "http://timestamp.digicert.com" \
  -in app.pkg \
  -out app-signed.pkg

# Verify timestamp
./codesign-toolkit timestamp -in app-signed.pkg
```

**Implementation**: 
- **macOS packages (.pkg)**: Uses xar with OpenSSL timestamp requests
- **iOS apps (.ipa)**: Uses isign with timestamp support (if available)
- **macOS apps (.app)**: Uses codesign with `--timestamp` parameter

## Timestamp Verification

The toolkit provides a dedicated `timestamp` command to verify timestamps in signed files:

```bash
# Check timestamp in any supported file type
./codesign-toolkit timestamp -in signed-file.exe
./codesign-toolkit timestamp -in signed-file.jar
./codesign-toolkit timestamp -in signed-file.air
./codesign-toolkit timestamp -in signed-file.pkg
```

### What the Verification Checks

1. **Timestamp Presence**: Whether the file contains a timestamp
2. **Timestamp Validity**: Whether the timestamp is properly formatted
3. **Timestamp Authority**: Information about the timestamp server used
4. **Timestamp Date**: When the file was timestamped

## Best Practices

### 1. Always Use Timestamps

```bash
# Good: Always include timestamp
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -t "http://timestamp.digicert.com" \
  -in app.exe -out app-signed.exe

# Bad: No timestamp (signature expires with certificate)
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -in app.exe -out app-signed.exe
```

### 2. Use Reliable Timestamp Servers

```bash
# Recommended: Use well-known timestamp servers
-t "http://timestamp.digicert.com"
-t "http://timestamp.sectigo.com"
-t "http://timestamp.globalsign.com"

# Avoid: Unknown or unreliable timestamp servers
-t "http://unknown-timestamp-server.com"
```

### 3. Handle Timestamp Failures Gracefully

The toolkit is designed to continue signing even if timestamp servers are unavailable:

```bash
# If timestamp server is down, signing continues without timestamp
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -t "http://timestamp.digicert.com" \
  -in app.exe -out app-signed.exe

# Check if timestamp was added
./codesign-toolkit timestamp -in app-signed.exe
```

### 4. Verify Timestamps After Signing

```bash
# Always verify timestamps after signing
./codesign-toolkit sign -type windows ... -out app-signed.exe
./codesign-toolkit timestamp -in app-signed.exe
```

## Troubleshooting

### Timestamp Server Unavailable

**Error**: `Failed to get timestamp from server`

**Solutions**:
1. Try alternative timestamp servers
2. Check network connectivity
3. Verify timestamp server URL
4. Continue without timestamp (not recommended for production)

### Timestamp Verification Fails

**Error**: `No timestamp found in file`

**Solutions**:
1. Verify the file was signed with timestamp
2. Check if timestamp server was available during signing
3. Re-sign with timestamp if needed

### Certificate Chain Issues

**Error**: `Timestamp certificate not trusted`

**Solutions**:
1. Update certificate trust store
2. Use different timestamp server
3. Verify timestamp server certificate

## Advanced Usage

### Custom Timestamp Servers

You can use any RFC 3161 compliant timestamp server:

```bash
# Custom timestamp server
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -t "http://your-timestamp-server.com" \
  -in app.exe -out app-signed.exe
```

### Batch Signing with Timestamps

```bash
# Sign multiple files with timestamps
for file in *.exe; do
  ./codesign-toolkit sign -type windows \
    -cert cert.pem -key key.pem \
    -t "http://timestamp.digicert.com" \
    -in "$file" -out "${file%.exe}-signed.exe"
done
```

### CI/CD Integration

```yaml
# GitHub Actions example with timestamp
- name: Sign Windows Application
  run: |
    ./codesign-toolkit sign -type windows \
      -cert ${{ secrets.CERT_FILE }} \
      -key ${{ secrets.KEY_FILE }} \
      -t "http://timestamp.digicert.com" \
      -in app.exe -out app-signed.exe
    
    # Verify timestamp was added
    ./codesign-toolkit timestamp -in app-signed.exe
```

## Technical Details

### Timestamp Protocols

- **RFC 3161**: Time-Stamp Protocol (TSP)
- **PKCS#7**: Cryptographic Message Syntax
- **Authenticode**: Microsoft's code signing format

### Hash Algorithms

- **SHA-256**: Standard for modern timestamps
- **SHA-1**: Legacy support (deprecated)

### Timestamp Format

Timestamps are embedded in the signature structure:
- **Windows**: Embedded in Authenticode signature
- **Java**: Embedded in JAR signature
- **AIR**: Embedded in PKCS#7 signature
- **Apple**: Embedded in code signature

## Support

For timestamp-related issues:

1. Check the troubleshooting section above
2. Verify timestamp server availability
3. Test with different timestamp servers
4. Review the signing logs for detailed error messages

## References

- [RFC 3161 - Internet X.509 Public Key Infrastructure Time-Stamp Protocol](https://tools.ietf.org/html/rfc3161)
- [Microsoft Authenticode Timestamping](https://docs.microsoft.com/en-us/windows/win32/seccrypto/authenticode-timestamping)
- [Java Timestamp Authority](https://docs.oracle.com/javase/8/docs/technotes/guides/security/timestamp.html)
