# Code Signing Guide

This guide provides comprehensive information about code signing and how to use the Linux Code Signing Toolkit.

**Linux Code Signing Toolkit 1.0**  
Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

## What is Code Signing?

Code signing is a security technology that uses digital certificates to verify the authenticity and integrity of software. When you sign code, you're essentially adding a digital signature that proves:

1. **Authenticity**: The code comes from a trusted source
2. **Integrity**: The code hasn't been tampered with since it was signed
3. **Non-repudiation**: The signer cannot deny they signed the code

## Supported File Types

### 1. Windows Binaries (via osslsigncode)

**Supported formats:**
- PE files (.exe, .dll)
- MSI installers (.msi)
- CAB files (.cab)
- CAT files (.cat)
- APPX packages (.appx)
- Script files

**Certificate requirements:**
- Authenticode certificate (SPC format or PEM)
- Private key (DER, PEM, or PVK format)
- Code signing extended key usage

**Example:**
```bash
./codesign-toolkit sign -type windows \
  -cert certificate.pem \
  -key private-key.pem \
  -pass password \
  -n "My Application" \
  -i "https://mycompany.com" \
  -t "http://timestamp.digicert.com" \
  -in app.exe \
  -out app-signed.exe
```

### 2. Java Applications (via JDK tools)

**Supported formats:**
- JAR files (.jar)
- Java applets
- Java Web Start applications

**Certificate requirements:**
- Java keystore (.jks or .p12)
- Valid certificate chain
- Code signing extended key usage

**Example:**
```bash
./codesign-toolkit sign -type java \
  -keystore keystore.jks \
  -alias mykey \
  -storepass keystore_password \
  -keypass key_password \
  -t "http://timestamp.digicert.com" \
  -in app.jar \
  -out app-signed.jar
```

### 3. Adobe AIR Files

**Supported formats:**
- AIR packages (.air)

**Certificate requirements:**
- PKCS#12 certificate (.p12)
- Valid certificate chain
- Code signing extended key usage

**Example:**
```bash
./codesign-toolkit sign -type air \
  -cert certificate.p12 \
  -pass password \
  -t "http://timestamp.digicert.com" \
  -in app.air \
  -out app-signed.air
```

## Certificate Management

### Obtaining Certificates

#### Windows Code Signing Certificates

1. **Commercial Certificate Authorities:**
   - DigiCert
   - Sectigo
   - GlobalSign
   - Comodo

2. **Requirements:**
   - Extended Validation (EV) for Windows SmartScreen
   - Code signing extended key usage
   - Hardware security module (HSM) for EV certificates

#### Java Code Signing Certificates

1. **Commercial Certificate Authorities:**
   - Same as Windows certificates
   - Java-specific certificates available

2. **Self-signed certificates:**
   - Suitable for internal use
   - Not trusted by default

#### Adobe AIR Certificates

1. **Adobe Certificate Authority:**
   - Adobe AIR Developer Certificate
   - Commercial certificates from CAs

2. **Self-signed certificates:**
   - Limited to development/testing

### Certificate Formats

#### Windows Signing
- **SPC**: Software Publisher Certificate (binary)
- **PEM**: Privacy Enhanced Mail (text)
- **DER**: Distinguished Encoding Rules (binary)

#### Java Signing
- **JKS**: Java KeyStore (Sun/Oracle format)
- **PKCS#12**: Personal Information Exchange (.p12)

#### AIR Signing
- **PKCS#12**: Personal Information Exchange (.p12)

## Best Practices

### 1. Certificate Security

- Store private keys securely (HSM recommended)
- Use strong passwords
- Regularly rotate certificates
- Backup certificates and keys safely

### 2. Timestamping

Always use timestamping to ensure signatures remain valid after certificate expiration:

```bash
-t "http://timestamp.digicert.com"
-t "http://timestamp.sectigo.com"
-t "http://timestamp.globalsign.com"
```

### 3. Multiple Signatures

For maximum compatibility, consider multiple signatures:

```bash
# Sign with SHA-256
./codesign-toolkit sign -type windows -sha256 ...

# Sign with SHA-1 (legacy support)
./codesign-toolkit sign -type windows -sha1 ...
```

### 4. Testing

Always test signed applications:
- Verify signatures work correctly
- Test on target platforms
- Check compatibility with security software

## Troubleshooting

### Common Issues

#### 1. Certificate Not Found
```
Error: Certificate file not found
```
**Solution:** Check certificate path and format

#### 2. Invalid Certificate
```
Error: Certificate is not valid for code signing
```
**Solution:** Ensure certificate has code signing extended key usage

#### 3. Timestamp Server Unavailable
```
Error: Timestamp server not responding
```
**Solution:** Try alternative timestamp servers or sign without timestamping

#### 4. Java Keystore Issues
```
Error: Invalid keystore format
```
**Solution:** Verify keystore format and password

### Debug Mode

Enable debug output for troubleshooting:

```bash
export DEBUG=1
./codesign-toolkit sign ...
```

## Security Considerations

### 1. Private Key Protection

- Never share private keys
- Use hardware security modules (HSM)
- Implement key rotation policies
- Monitor for key compromise

### 2. Certificate Validation

- Verify certificate authenticity
- Check certificate expiration
- Validate certificate chain
- Monitor certificate revocation

### 3. Build Security

- Sign code in secure environments
- Use CI/CD pipelines with proper security
- Implement code review processes
- Monitor for unauthorized signing

## Compliance and Standards

### 1. Windows Requirements

- **Windows SmartScreen**: Requires EV certificates
- **Windows Defender**: Validates signatures
- **Microsoft Store**: Specific requirements

### 2. Java Requirements

- **Oracle JRE**: Validates JAR signatures
- **OpenJDK**: Compatible signature validation
- **Applet Security**: Requires valid certificates

### 3. Adobe AIR Requirements

- **AIR Runtime**: Validates AIR signatures
- **Adobe Distribution**: Specific requirements
- **Enterprise Deployment**: Internal certificates

## Advanced Features

### 1. Batch Signing

Sign multiple files at once:

```bash
for file in *.exe; do
  ./codesign-toolkit sign -type windows \
    -cert cert.pem -key key.pem \
    -in "$file" -out "${file%.exe}-signed.exe"
done
```

### 2. Automated Signing

Integrate with CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Sign Windows Application
  run: |
    ./codesign-toolkit sign -type windows \
      -cert ${{ secrets.CERT_FILE }} \
      -key ${{ secrets.KEY_FILE }} \
      -pass ${{ secrets.KEY_PASSWORD }} \
      -in app.exe -out app-signed.exe
```

### 3. Signature Verification

Verify signatures in automated processes:

```bash
# Verify and exit with error if invalid
./codesign-toolkit verify -in app-signed.exe || exit 1
```

## Resources

### Official Documentation
- [osslsigncode Documentation](https://github.com/mtrojnar/osslsigncode)
- [Java Security Documentation](https://docs.oracle.com/javase/8/docs/technotes/guides/security/)
- [Adobe AIR Documentation](https://help.adobe.com/en_US/air/build/)

### Certificate Authorities
- [DigiCert](https://www.digicert.com/)
- [Sectigo](https://www.sectigo.com/)
- [GlobalSign](https://www.globalsign.com/)
- [Comodo](https://www.comodo.com/)

### Timestamp Servers
- DigiCert: `http://timestamp.digicert.com`
- Sectigo: `http://timestamp.sectigo.com`
- GlobalSign: `http://timestamp.globalsign.com`

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the test suite
3. Examine example usage
4. Create an issue on the project repository
