# JIRA Integration Guide

**Linux Code Signing Toolkit 1.2**
Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

## Overview

The Linux Code Signing Toolkit includes comprehensive JIRA integration for creating audit trails, tracking signing operations, and maintaining compliance records. This integration allows you to automatically create and update JIRA tickets for all code signing activities.

## Features

### Automatic Ticket Creation
- **Success Tracking**: Creates tickets for successful signing operations
- **Failure Reporting**: Creates high-priority tickets for failed operations
- **Audit Trails**: Maintains complete records of all signing activities
- **Compliance**: Supports regulatory and security compliance requirements

### Manual Ticket Management
- **Create Tickets**: Manually create JIRA tickets with custom content
- **Update Tickets**: Add comments and update status of existing tickets
- **Project Integration**: Works with any JIRA project and issue types

## Setup

### 1. Prerequisites

- JIRA instance (cloud or server)
- JIRA API token
- curl (for API communication)
- Appropriate JIRA permissions

### 2. Interactive Setup

Use the provided setup script for easy configuration:

```bash
# Run interactive setup
./scripts/setup-jira.sh --configure
```

The setup script will guide you through:
- JIRA URL configuration
- Username/email setup
- API token generation
- Default project selection
- Connection testing

### 3. Manual Configuration

Alternatively, set environment variables manually:

```bash
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_USER="your-email@company.com"
export JIRA_TOKEN="your-api-token"
export JIRA_PROJECT="PROJ"
```

### 4. API Token Generation

To get your JIRA API token:

1. Go to [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click "Create API token"
3. Give it a descriptive name (e.g., "Code Signing Toolkit")
4. Copy the generated token
5. Store it securely (never commit to version control)

## Usage

### Automatic Logging

The toolkit automatically creates JIRA tickets for signing operations:

```bash
# Sign a file (automatically creates JIRA ticket)
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -in app.exe -out app-signed.exe

# If successful: Creates a "Task" ticket with success details
# If failed: Creates a "Bug" ticket with error information
```

### Manual Ticket Creation

Create custom JIRA tickets:

```bash
# Create a new ticket
./codesign-toolkit jira -create \
  -project PROJ \
  -type Task \
  -summary "Code signing operation completed" \
  -description "Windows application signed successfully with timestamp" \
  -priority Medium

# Create a bug ticket
./codesign-toolkit jira -create \
  -project PROJ \
  -type Bug \
  -summary "Code signing failed" \
  -description "Failed to sign application due to certificate issues" \
  -priority High
```

### Ticket Updates

Update existing tickets:

```bash
# Add a comment to an existing ticket
./codesign-toolkit jira -update \
  -issue PROJ-123 \
  -comment "Verification completed successfully"

# Update ticket status
./codesign-toolkit jira -update \
  -issue PROJ-123 \
  -status "Done"

# Both comment and status update
./codesign-toolkit jira -update \
  -issue PROJ-123 \
  -comment "All tests passed" \
  -status "In Review"
```

## Ticket Types and Content

### Automatic Success Tickets

**Type**: Task  
**Priority**: Low  
**Content**:
- Operation type (sign, verify, etc.)
- File type (windows, java, air, apple)
- Input and output file paths
- Timestamp of operation
- User and host information
- Success status

### Automatic Failure Tickets

**Type**: Bug  
**Priority**: High  
**Content**:
- Operation type and file type
- Input and output file paths
- Detailed error message
- Timestamp of operation
- User and host information
- Failure status

### Manual Tickets

**Customizable**:
- Issue type (Task, Bug, Story, etc.)
- Summary and description
- Priority level
- Project assignment

## Integration Examples

### CI/CD Pipeline Integration

```yaml
# GitHub Actions example
- name: Sign Application
  env:
    JIRA_URL: ${{ secrets.JIRA_URL }}
    JIRA_USER: ${{ secrets.JIRA_USER }}
    JIRA_TOKEN: ${{ secrets.JIRA_TOKEN }}
    JIRA_PROJECT: ${{ secrets.JIRA_PROJECT }}
  run: |
    ./codesign-toolkit sign -type windows \
      -cert ${{ secrets.CERT_FILE }} \
      -key ${{ secrets.KEY_FILE }} \
      -t "http://timestamp.digicert.com" \
      -in app.exe -out app-signed.exe
    
    # Create deployment ticket
    ./codesign-toolkit jira -create \
      -project ${{ secrets.JIRA_PROJECT }} \
      -type Task \
      -summary "Application signed for deployment" \
      -description "Version 1.2.3 signed and ready for production deployment"
```

### Batch Processing

```bash
#!/bin/bash
# Batch signing with JIRA tracking

for file in *.exe; do
  echo "Signing $file..."
  
  ./codesign-toolkit sign -type windows \
    -cert cert.pem -key key.pem \
    -t "http://timestamp.digicert.com" \
    -in "$file" -out "${file%.exe}-signed.exe"
  
  if [ $? -eq 0 ]; then
    echo "Successfully signed $file"
  else
    echo "Failed to sign $file"
  fi
done

# Create summary ticket
./codesign-toolkit jira -create \
  -project PROJ \
  -type Task \
  -summary "Batch signing completed" \
  -description "Processed $(ls *.exe | wc -l) files"
```

### Compliance Reporting

```bash
#!/bin/bash
# Compliance audit script

# Sign with compliance tracking
./codesign-toolkit sign -type windows \
  -cert cert.pem -key key.pem \
  -in app.exe -out app-signed.exe

# Create compliance ticket
./codesign-toolkit jira -create \
  -project COMPLIANCE \
  -type Task \
  -summary "Code signing compliance audit" \
  -description "Application signed according to company security policy. Certificate: $CERT_SERIAL, Timestamp: $(date -u)"
```

## Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `JIRA_URL` | Your JIRA instance URL | `https://company.atlassian.net` |
| `JIRA_USER` | Your JIRA username/email | `user@company.com` |
| `JIRA_TOKEN` | Your JIRA API token | `abc123def456...` |
| `JIRA_PROJECT` | Default project key | `PROJ` |

### Configuration File

The setup script creates a `.jira-config` file:

```bash
# JIRA Configuration for Linux Code Signing Toolkit
# Generated on 2024-01-15 10:30:00

JIRA_URL="https://company.atlassian.net"
JIRA_USER="user@company.com"
JIRA_TOKEN="your-api-token"
JIRA_PROJECT="PROJ"
```

**Security Note**: The configuration file has restricted permissions (600) and should never be committed to version control.

## Troubleshooting

### Common Issues

#### 1. Authentication Failed

**Error**: `HTTP 401 Unauthorized`

**Solutions**:
- Verify JIRA username and API token
- Check API token permissions
- Ensure token hasn't expired

#### 2. Project Access Denied

**Error**: `HTTP 403 Forbidden`

**Solutions**:
- Verify project key is correct
- Check user permissions for the project
- Ensure project exists and is accessible

#### 3. Invalid Issue Type

**Error**: `Issue type not found`

**Solutions**:
- Verify issue type name (Task, Bug, Story, etc.)
- Check project configuration for available issue types
- Use exact case-sensitive names

#### 4. Network Connectivity

**Error**: `Connection failed`

**Solutions**:
- Check network connectivity to JIRA
- Verify JIRA URL is correct
- Check firewall/proxy settings

### Testing Connection

Test your JIRA configuration:

```bash
# Test basic connection
./scripts/setup-jira.sh --test

# Export environment variables
./scripts/setup-jira.sh --export
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
export DEBUG=1
./codesign-toolkit jira -create -project PROJ -type Task -summary "Test"
```

## Best Practices

### 1. Security

- Store API tokens securely
- Use environment variables in CI/CD
- Never commit credentials to version control
- Rotate API tokens regularly

### 2. Ticket Management

- Use descriptive summaries
- Include relevant details in descriptions
- Set appropriate priorities
- Update ticket status promptly

### 3. Automation

- Integrate with CI/CD pipelines
- Use consistent project and issue types
- Implement proper error handling
- Monitor ticket creation success

### 4. Compliance

- Create audit trails for all operations
- Document certificate usage
- Track timestamp server usage
- Maintain signing history

## API Reference

### JIRA REST API Endpoints

The toolkit uses the following JIRA REST API endpoints:

- `POST /rest/api/2/issue` - Create new issue
- `POST /rest/api/2/issue/{key}/comment` - Add comment
- `POST /rest/api/2/issue/{key}/transitions` - Update status
- `GET /rest/api/2/issue/{key}/transitions` - Get available transitions
- `GET /rest/api/2/myself` - Verify authentication
- `GET /rest/api/2/project/{key}` - Verify project access

### Response Codes

- `200` - Success (GET requests)
- `201` - Created (POST requests)
- `204` - No content (status updates)
- `400` - Bad request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not found

## Support

For JIRA integration issues:

1. Check the troubleshooting section above
2. Verify JIRA configuration
3. Test connection with setup script
4. Review JIRA API documentation
5. Check JIRA permissions and project access

## References

- [JIRA REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
- [JIRA Issue Types](https://confluence.atlassian.com/adminjiraserver/defining-issue-types-938847039.html)
