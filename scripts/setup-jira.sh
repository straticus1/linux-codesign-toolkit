#!/bin/bash

# JIRA Integration Setup Script
# Part of Linux Code Signing Toolkit 1.2
# Designed and Developed by: Ryan Coleman <coleman.ryan@gmail.com>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.jira-config"

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

show_help() {
    cat << EOF
JIRA Integration Setup Script

Usage: $0 [options]

Options:
  -h, --help          Show this help message
  -c, --configure     Interactive configuration
  -t, --test          Test JIRA connection
  -e, --export        Export environment variables
  -i, --import        Import from .jira-config file

Examples:
  $0 --configure      # Interactive setup
  $0 --test           # Test connection
  $0 --export         # Export to environment
EOF
}

interactive_setup() {
    log_info "JIRA Integration Setup"
    echo ""
    
    # Get JIRA URL
    read -p "Enter your JIRA URL (e.g., https://yourcompany.atlassian.net): " jira_url
    if [ -z "$jira_url" ]; then
        log_error "JIRA URL is required"
        exit 1
    fi
    
    # Get JIRA username/email
    read -p "Enter your JIRA username or email: " jira_user
    if [ -z "$jira_user" ]; then
        log_error "JIRA username is required"
        exit 1
    fi
    
    # Get JIRA API token
    echo ""
    log_info "To get your JIRA API token:"
    echo "1. Go to https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "2. Click 'Create API token'"
    echo "3. Give it a name (e.g., 'Code Signing Toolkit')"
    echo "4. Copy the generated token"
    echo ""
    read -s -p "Enter your JIRA API token: " jira_token
    echo ""
    if [ -z "$jira_token" ]; then
        log_error "JIRA API token is required"
        exit 1
    fi
    
    # Get default project key
    read -p "Enter default JIRA project key (e.g., PROJ): " jira_project
    if [ -z "$jira_project" ]; then
        log_warning "No default project set. You'll need to specify project for each ticket."
    fi
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# JIRA Configuration for Linux Code Signing Toolkit
# Generated on $(date)

JIRA_URL="$jira_url"
JIRA_USER="$jira_user"
JIRA_TOKEN="$jira_token"
JIRA_PROJECT="$jira_project"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_success "JIRA configuration saved to $CONFIG_FILE"
    
    # Test connection
    echo ""
    log_info "Testing JIRA connection..."
    test_jira_connection
}

test_jira_connection() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "JIRA configuration file not found. Run setup first."
        exit 1
    fi
    
    # Source configuration
    source "$CONFIG_FILE"
    
    if [ -z "$JIRA_URL" ] || [ -z "$JIRA_USER" ] || [ -z "$JIRA_TOKEN" ]; then
        log_error "Incomplete JIRA configuration"
        exit 1
    fi
    
    log_info "Testing connection to $JIRA_URL..."
    
    # Test basic connection
    local response=$(curl -s -w "%{http_code}" -X GET \
        -H "Authorization: Basic $(echo -n "$JIRA_USER:$JIRA_TOKEN" | base64)" \
        "$JIRA_URL/rest/api/2/myself")
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [ "$http_code" -eq 200 ]; then
        local username=$(echo "$response_body" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        local email=$(echo "$response_body" | grep -o '"emailAddress":"[^"]*"' | cut -d'"' -f4)
        log_success "JIRA connection successful!"
        log_info "Connected as: $username ($email)"
        
        # Test project access if specified
        if [ -n "$JIRA_PROJECT" ]; then
            log_info "Testing access to project: $JIRA_PROJECT"
            local project_response=$(curl -s -w "%{http_code}" -X GET \
                -H "Authorization: Basic $(echo -n "$JIRA_USER:$JIRA_TOKEN" | base64)" \
                "$JIRA_URL/rest/api/2/project/$JIRA_PROJECT")
            
            local project_http_code="${project_response: -3}"
            if [ "$project_http_code" -eq 200 ]; then
                local project_name=$(echo "$project_response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                log_success "Project access confirmed: $project_name"
            else
                log_warning "Cannot access project $JIRA_PROJECT (HTTP $project_http_code)"
            fi
        fi
    else
        log_error "JIRA connection failed (HTTP $http_code)"
        log_error "Response: $response_body"
        exit 1
    fi
}

export_environment() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "JIRA configuration file not found. Run setup first."
        exit 1
    fi
    
    log_info "Exporting JIRA environment variables..."
    echo ""
    echo "# Add these to your shell profile (.bashrc, .zshrc, etc.)"
    echo "# or export them in your current session:"
    echo ""
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        echo "export $key=\"$value\""
    done < "$CONFIG_FILE"
    
    echo ""
    log_info "To use in current session, run:"
    echo "source <($0 --export)"
}

import_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "JIRA configuration file not found at $CONFIG_FILE"
        exit 1
    fi
    
    log_info "Importing JIRA configuration..."
    source "$CONFIG_FILE"
    
    if [ -n "$JIRA_URL" ] && [ -n "$JIRA_USER" ] && [ -n "$JIRA_TOKEN" ]; then
        log_success "JIRA configuration imported successfully"
        log_info "URL: $JIRA_URL"
        log_info "User: $JIRA_USER"
        log_info "Project: ${JIRA_PROJECT:-Not set}"
    else
        log_error "Incomplete JIRA configuration"
        exit 1
    fi
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -c|--configure)
            interactive_setup
            ;;
        -t|--test)
            test_jira_connection
            ;;
        -e|--export)
            export_environment
            ;;
        -i|--import)
            import_config
            ;;
        "")
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
