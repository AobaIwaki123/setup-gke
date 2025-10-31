#!/bin/bash

# Kubernetes Deployment Script
# Orchestrates the deployment of GKE cluster with ArgoCD, Cloudflare Ingress, and monitoring
# Based on requirements 6.4, 6.5 from the requirements document

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MANIFEST_DIR="k8s"
ENVIRONMENT="production"
DRY_RUN="false"
SKIP_VALIDATION="false"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to wait for deployment readiness
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    print_status $YELLOW "Waiting for deployment $deployment in namespace $namespace to be ready..."
    
    if kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace; then
        print_status $GREEN "✓ Deployment $deployment is ready"
        return 0
    else
        print_status $RED "✗ Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local label_selector=$2
    local timeout=${3:-300}
    
    print_status $YELLOW "Waiting for pods with selector '$label_selector' in namespace $namespace..."
    
    if kubectl wait --for=condition=ready --timeout=${timeout}s pod -l $label_selector -n $namespace; then
        print_status $GREEN "✓ Pods are ready"
        return 0
    else
        print_status $RED "✗ Pods failed to become ready within ${timeout}s"
        return 1
    fi
}

# Function to apply manifests with error handling
apply_manifest() {
    local file=$1
    local dry_run_flag=""
    
    if [ "$DRY_RUN" = "true" ]; then
        dry_run_flag="--dry-run=client"
    fi
    
    print_status $BLUE "Applying: $file"
    
    if kubectl apply $dry_run_flag -f "$file"; then
        print_status $GREEN "✓ Applied: $file"
        return 0
    else
        print_status $RED "✗ Failed to apply: $file"
        return 1
    fi
}

# Function to deploy cluster configuration
deploy_cluster() {
    print_status $GREEN "=== Deploying Cluster Configuration ==="
    
    # Note: Cluster creation is typically done via Terraform or gcloud CLI
    # These manifests are for reference and documentation
    print_status $YELLOW "Note: Cluster configuration files are for reference."
    print_status $YELLOW "Actual cluster creation should be done via Terraform or gcloud CLI."
    
    # Apply storage classes
    apply_manifest "$MANIFEST_DIR/cluster/storage-classes.yaml"
}

# Function to deploy namespaces
deploy_namespaces() {
    print_status $GREEN "=== Creating Namespaces ==="
    
    apply_manifest "$MANIFEST_DIR/argocd/namespace.yaml"
    apply_manifest "$MANIFEST_DIR/cloudflare-ingress/namespace.yaml"
    apply_manifest "$MANIFEST_DIR/monitoring/namespace.yaml"
}

# Function to deploy RBAC configurations
deploy_rbac() {
    print_status $GREEN "=== Deploying RBAC Configurations ==="
    
    apply_manifest "$MANIFEST_DIR/argocd/rbac.yaml"
    apply_manifest "$MANIFEST_DIR/cloudflare-ingress/rbac.yaml"
    apply_manifest "$MANIFEST_DIR/monitoring/rbac.yaml"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_status $GREEN "=== Deploying ArgoCD ==="
    
    # Check if ArgoCD installation manifest exists
    if [ ! -f "$MANIFEST_DIR/argocd/install.yaml" ]; then
        print_status $YELLOW "ArgoCD installation manifest not found. Downloading..."
        curl -sSL -o "$MANIFEST_DIR/argocd/install.yaml" \
            https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    fi
    
    apply_manifest "$MANIFEST_DIR/argocd/install.yaml"
    
    # Wait for ArgoCD to be ready
    if [ "$DRY_RUN" = "false" ]; then
        wait_for_deployment "argocd" "argocd-server" 600
        wait_for_deployment "argocd" "argocd-application-controller" 600
    fi
}

# Function to deploy Cloudflare Ingress Controller
deploy_cloudflare_ingress() {
    print_status $GREEN "=== Deploying Cloudflare Ingress Controller ==="
    
    # Check if secrets exist
    if [ ! -f "$MANIFEST_DIR/cloudflare-ingress/secrets.yaml" ]; then
        print_status $YELLOW "⚠ Cloudflare secrets not found. Please create secrets.yaml from template."
        print_status $YELLOW "Copy secrets.yaml.template to secrets.yaml and update with actual credentials."
        return 1
    fi
    
    apply_manifest "$MANIFEST_DIR/cloudflare-ingress/secrets.yaml"
    apply_manifest "$MANIFEST_DIR/cloudflare-ingress/deployment.yaml"
    
    # Wait for controller to be ready
    if [ "$DRY_RUN" = "false" ]; then
        wait_for_deployment "cloudflare-ingress" "cloudflare-ingress-controller" 300
    fi
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_status $GREEN "=== Deploying Monitoring Stack ==="
    
    # Deploy Prometheus
    apply_manifest "$MANIFEST_DIR/monitoring/prometheus/config.yaml"
    apply_manifest "$MANIFEST_DIR/monitoring/prometheus/deployment.yaml"
    
    # Deploy Grafana
    apply_manifest "$MANIFEST_DIR/monitoring/grafana/deployment.yaml"
    
    # Deploy AlertManager
    apply_manifest "$MANIFEST_DIR/monitoring/alertmanager/deployment.yaml"
    
    # Wait for monitoring components to be ready
    if [ "$DRY_RUN" = "false" ]; then
        wait_for_deployment "monitoring" "prometheus" 300
        wait_for_deployment "monitoring" "grafana" 300
        wait_for_deployment "monitoring" "alertmanager" 300
    fi
}

# Function to deploy ingress resources
deploy_ingress() {
    print_status $GREEN "=== Deploying Ingress Resources ==="
    
    apply_manifest "$MANIFEST_DIR/ingress/argocd-ingress.yaml"
}

# Function to validate deployment
validate_deployment() {
    print_status $GREEN "=== Validating Deployment ==="
    
    # Check ArgoCD
    print_status $YELLOW "Checking ArgoCD status..."
    kubectl get pods -n argocd
    
    # Check Cloudflare Ingress Controller
    print_status $YELLOW "Checking Cloudflare Ingress Controller status..."
    kubectl get pods -n cloudflare-ingress
    
    # Check Monitoring
    print_status $YELLOW "Checking Monitoring stack status..."
    kubectl get pods -n monitoring
    
    # Check Ingress
    print_status $YELLOW "Checking Ingress resources..."
    kubectl get ingress -A
}

# Function to show post-deployment instructions
show_post_deployment() {
    print_status $GREEN "=== Post-Deployment Instructions ==="
    
    echo ""
    print_status $BLUE "1. ArgoCD Access:"
    echo "   - Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo "   - Access via: https://argocd.example.com (update with your domain)"
    
    echo ""
    print_status $BLUE "2. Grafana Access:"
    echo "   - Default credentials: admin/admin (change on first login)"
    echo "   - Port forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
    
    echo ""
    print_status $BLUE "3. Prometheus Access:"
    echo "   - Port forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    
    echo ""
    print_status $BLUE "4. Next Steps:"
    echo "   - Configure Cloudflare DNS records"
    echo "   - Set up SSL certificates"
    echo "   - Configure monitoring alerts"
    echo "   - Deploy your applications via ArgoCD"
}

# Main deployment function
main() {
    print_status $GREEN "Starting Kubernetes deployment..."
    print_status $YELLOW "Environment: $ENVIRONMENT"
    print_status $YELLOW "Dry run: $DRY_RUN"
    
    # Validate manifests first (unless skipped)
    if [ "$SKIP_VALIDATION" = "false" ]; then
        print_status $YELLOW "Validating manifests..."
        if ! ./scripts/validate-manifests.sh; then
            print_status $RED "Manifest validation failed. Use --skip-validation to bypass."
            exit 1
        fi
    fi
    
    # Check kubectl connectivity
    if [ "$DRY_RUN" = "false" ]; then
        if ! kubectl cluster-info >/dev/null 2>&1; then
            print_status $RED "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
            exit 1
        fi
    fi
    
    # Deploy in order
    deploy_cluster
    deploy_namespaces
    deploy_rbac
    deploy_argocd
    deploy_cloudflare_ingress
    deploy_monitoring
    deploy_ingress
    
    # Validate deployment
    if [ "$DRY_RUN" = "false" ]; then
        validate_deployment
        show_post_deployment
    fi
    
    print_status $GREEN "✓ Deployment completed successfully!"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -e, --environment ENV   Specify environment (dev|staging|production) [default: production]"
    echo "  -d, --dry-run           Perform dry run without applying changes"
    echo "  -s, --skip-validation   Skip manifest validation"
    echo ""
    echo "Examples:"
    echo "  $0                      # Deploy to production"
    echo "  $0 -e dev               # Deploy to development environment"
    echo "  $0 -d                   # Dry run deployment"
    echo "  $0 -s                   # Skip validation and deploy"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -s|--skip-validation)
            SKIP_VALIDATION="true"
            shift
            ;;
        *)
            print_status $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_status $RED "Invalid environment: $ENVIRONMENT"
    print_status $YELLOW "Valid environments: dev, staging, production"
    exit 1
fi

# Run main function
main