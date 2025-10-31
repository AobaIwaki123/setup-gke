# Validation Notes

## Expected Validation Issues

The following validation issues are expected and normal for this project structure:

### 1. Missing CRDs (Custom Resource Definitions)
- **ArgoCD Application**: Requires ArgoCD CRDs to be installed first
- **Cert-Manager Certificate/ClusterIssuer**: Requires cert-manager CRDs
- **GKE Cluster/NodePool**: These are GCP-specific resources, not standard Kubernetes resources
- **Kustomization**: This is a Kustomize configuration file, not a Kubernetes resource

### 2. Placeholder Values
The following files contain placeholder values that need to be updated for actual deployment:
- `k8s/cluster/cluster.yaml`: PROJECT_ID placeholder
- `k8s/ingress/argocd-ingress.yaml`: example.com domain placeholders
- `k8s/argocd/install.yaml`: example.com domain placeholder
- Environment configuration files: Various example.com placeholders

### 3. Configuration Files
- Environment values files (`k8s/config/environments/*/values.yaml`) are configuration files, not Kubernetes manifests
- These files are used for templating and don't need to be valid Kubernetes resources

## Successfully Validated Resources

The following standard Kubernetes resources passed validation:
- ✅ Storage Classes
- ✅ Namespaces (ArgoCD, Cloudflare Ingress, Monitoring)
- ✅ RBAC configurations (Service Accounts, Roles, RoleBindings)
- ✅ Deployments (Cloudflare Ingress Controller, Prometheus, Grafana, AlertManager)
- ✅ Services and PersistentVolumeClaims
- ✅ ConfigMaps

## Pre-Deployment Requirements

Before deploying these manifests:

1. **Install Required CRDs**:
   - ArgoCD: `kubectl apply -k https://github.com/argoproj/argo-cd/manifests/cluster-install`
   - Cert-Manager: `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml`

2. **Update Placeholder Values**:
   - Replace all `example.com` with your actual domain
   - Replace `PROJECT_ID` with your GCP project ID
   - Update zone IDs and other environment-specific values

3. **Create Secrets**:
   - Copy `secrets.yaml.template` files to `secrets.yaml`
   - Update with actual credentials (API tokens, passwords, etc.)

4. **GKE Cluster Creation**:
   - Use Terraform, gcloud CLI, or GCP Console to create the actual GKE cluster
   - The cluster configuration files are for reference and documentation

## Deployment Order

1. Create GKE cluster (via Terraform/gcloud)
2. Install CRDs (ArgoCD, cert-manager)
3. Apply namespaces
4. Apply RBAC configurations
5. Apply core services (ArgoCD, Ingress Controller)
6. Apply monitoring stack
7. Apply ingress resources