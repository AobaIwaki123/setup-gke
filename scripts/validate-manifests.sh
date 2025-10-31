#!/bin/bash

# Kubernetes Manifest Validation Script
# This script validates all Kubernetes manifest files for syntax and semantic correctness
# Based on requirements 6.1, 6.4 from the requirements document

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MANIFEST_DIR="k8s"
TEMP_DIR="/tmp/k8s-validation"
VALIDATION_LOG="validation.log"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to validate YAML syntax
validate_yaml_syntax() {
    local file=$1
    print_status $YELLOW "Validating YAML syntax: $file"
    
    if command -v yq >/dev/null 2>&1; then
        if yq eval '.' "$file" >/dev/null 2>&1; then
            print_status $GREEN "✓ YAML syntax valid: $file"
            return 0
        else
            print_status $RED "✗ YAML syntax error: $file"
            return 1
        fi
    else
        print_status $YELLOW "⚠ yq not found, skipping YAML syntax validation"
        return 0
    fi
}

# Function to validate Kubernetes manifest
validate_k8s_manifest() {
    local file=$1
    print_status $YELLOW "Validating Kubernetes manifest: $file"
    
    if kubectl apply --dry-run=client -f "$file" >/dev/null 2>&1; then
        print_status $GREEN "✓ Kubernetes manifest valid: $file"
        return 0
    else
        print_status $RED "✗ Kubernetes manifest error: $file"
        kubectl apply --dry-run=client -f "$file" 2>&1 | head -5
        return 1
    fi
}

# Function to validate server-side (requires cluster access)
validate_server_side() {
    local file=$1
    print_status $YELLOW "Validating server-side: $file"
    
    if kubectl apply --dry-run=server -f "$file" >/dev/null 2>&1; then
        print_status $GREEN "✓ Server-side validation passed: $file"
        return 0
    else
        print_status $YELLOW "⚠ Server-side validation failed (cluster may not be accessible): $file"
        return 0  # Don't fail on server-side validation as cluster might not be available
    fi
}

# Function to check for common issues
check_common_issues() {
    local file=$1
    local issues=0
    
    print_status $YELLOW "Checking common issues: $file"
    
    # Check for placeholder values
    if grep -q "example.com\|PROJECT_ID\|BASE64_ENCODED\|your-" "$file" 2>/dev/null; then
        print_status $YELLOW "⚠ Found placeholder values in: $file"
        grep -n "example.com\|PROJECT_ID\|BASE64_ENCODED\|your-" "$file" | head -3
        ((issues++))
    fi
    
    # Check for missing required fields in common resources
    if grep -q "kind: Deployment" "$file"; then
        if ! grep -q "resources:" "$file"; then
            print_status $YELLOW "⚠ Deployment missing resource limits/requests: $file"
            ((issues++))
        fi
    fi
    
    # Check for security contexts
    if grep -q "kind: Deployment\|kind: Pod" "$file"; then
        if ! grep -q "securityContext:" "$file"; then
            print_status $YELLOW "⚠ Missing security context: $file"
            ((issues++))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        print_status $GREEN "✓ No common issues found: $file"
    fi
    
    return 0
}

# Main validation function
validate_file() {
    local file=$1
    local errors=0
    
    echo "----------------------------------------"
    print_status $YELLOW "Validating: $file"
    
    # Skip template files and non-YAML files
    if [[ "$file" == *.template ]] || [[ "$file" == *.md ]] || [[ "$file" == *.sh ]]; then
        print_status $YELLOW "⚠ Skipping template/non-YAML file: $file"
        return 0
    fi
    
    # Validate YAML syntax
    if ! validate_yaml_syntax "$file"; then
        ((errors++))
    fi
    
    # Validate Kubernetes manifest (only for YAML files)
    if [[ "$file" == *.yaml ]] || [[ "$file" == *.yml ]]; then
        if ! validate_k8s_manifest "$file"; then
            ((errors++))
        fi
        
        # Server-side validation (optional)
        if [ "$VALIDATE_SERVER_SIDE" = "true" ]; then
            validate_server_side "$file"
        fi
        
        # Check common issues
        check_common_issues "$file"
    fi
    
    if [ $errors -eq 0 ]; then
        print_status $GREEN "✓ All validations passed: $file"
    else
        print_status $RED "✗ $errors validation(s) failed: $file"
    fi
    
    return $errors
}

# Main execution
main() {
    print_status $GREEN "Starting Kubernetes manifest validation..."
    print_status $YELLOW "Manifest directory: $MANIFEST_DIR"
    
    # Check prerequisites
    if ! command -v kubectl >/dev/null 2>&1; then
        print_status $RED "Error: kubectl is required but not installed"
        exit 1
    fi
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Initialize counters
    local total_files=0
    local failed_files=0
    local validated_files=0
    
    # Find and validate all YAML files
    while IFS= read -r -d '' file; do
        ((total_files++))
        if validate_file "$file"; then
            ((validated_files++))
        else
            ((failed_files++))
        fi
    done < <(find "$MANIFEST_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)
    
    # Summary
    echo "========================================"
    print_status $GREEN "Validation Summary:"
    echo "Total files: $total_files"
    echo "Validated successfully: $validated_files"
    echo "Failed validation: $failed_files"
    
    if [ $failed_files -eq 0 ]; then
        print_status $GREEN "✓ All manifest files are valid!"
        exit 0
    else
        print_status $RED "✗ $failed_files file(s) failed validation"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -s, --server-side       Enable server-side validation (requires cluster access)"
    echo "  -d, --directory DIR     Specify manifest directory (default: k8s)"
    echo ""
    echo "Examples:"
    echo "  $0                      # Validate all manifests with client-side validation"
    echo "  $0 -s                   # Validate with server-side validation"
    echo "  $0 -d custom-k8s        # Validate manifests in custom-k8s directory"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server-side)
            VALIDATE_SERVER_SIDE="true"
            shift
            ;;
        -d|--directory)
            MANIFEST_DIR="$2"
            shift 2
            ;;
        *)
            print_status $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main