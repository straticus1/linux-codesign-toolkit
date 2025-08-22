# Contributors

## Project Creator and Lead Developer

**Ryan Coleman** <coleman.ryan@gmail.com>
- **Role:** Designer and Lead Developer
- **Contribution:** Complete architecture, design, and implementation of the Linux Code Signing Toolkit
- **Responsibilities:**
  - Project conception and planning
  - System architecture and design
  - Implementation of all core functionality
  - Windows binary signing integration (osslsigncode wrapper)
  - Java application signing implementation
  - Adobe AIR file signing custom implementation
  - Apple package signing implementation (.pkg, .ipa, .app)
  - Test suite development
  - Documentation and user guides
  - Build system and deployment scripts

## Project Overview

The Linux Code Signing Toolkit was conceived, designed, and developed entirely by Ryan Coleman to address the need for comprehensive cross-platform code signing capabilities on Linux and macOS systems. 

This toolkit bridges the gap between Windows-centric code signing tools and modern development environments, providing a unified interface for signing applications across multiple platforms and formats.

## Third-Party Components

While the toolkit framework and integration was developed by Ryan Coleman, it incorporates the following third-party components:

- **osslsigncode** - OpenSSL-based Authenticode signing for Windows binaries
  - Repository: https://github.com/mtrojnar/osslsigncode
  - License: GPL-3.0
  - Integration: Custom wrapper and build system by Ryan Coleman

- **JDK Tools** - Java Development Kit signing tools (jarsigner, keytool)
  - Provider: Oracle/OpenJDK
  - Integration: Custom wrapper implementation by Ryan Coleman

- **OpenSSL** - Cryptographic library for certificate operations
  - Provider: OpenSSL Project
  - Integration: Custom AIR and Apple signing implementations by Ryan Coleman

## Recognition

If you use this toolkit in your projects, please provide attribution:

```
Linux Code Signing Toolkit by Ryan Coleman
https://github.com/ryancoleman/linux-codesign-toolkit
```

## Contact

For questions, suggestions, or contributions, please contact:

**Ryan Coleman**  
Email: coleman.ryan@gmail.com  
GitHub: [@ryancoleman](https://github.com/ryancoleman)
