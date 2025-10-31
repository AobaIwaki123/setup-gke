# Kubernetes Manifests Directory Structure

This directory contains all Kubernetes manifests and configuration files for the GKE cluster setup with ArgoCD, Cloudflare Ingress Controller, and monitoring tools.

## Directory Structure

```
k8s/
├── cluster/                    # GKE cluster configuration
│   ├── cluster.yaml           # Main cluster configuration
│   ├── node-pools.yaml        # Node pool configurations
│   └── storage-classes.yaml   # Storage class definitions
├── argocd/                    # ArgoCD deployment manifests
│   ├── namespace.yaml         # ArgoCD namespace
│   ├── install.yaml           # ArgoCD installation
│   ├── rbac.yaml             # RBAC configurations
│   └── applications/          # ArgoCD application definitions
├── cloudflare-ingress/        # Cloudflare Ingress Controller
│   ├── namespace.yaml         # Controller namespace
│   ├── deployment.yaml        # Controller deployment
│   ├── rbac.yaml             # RBAC configurations
│   └── secrets.yaml          # API credentials (template)
├── monitoring/                # Monitoring stack
│   ├── namespace.yaml         # Monitoring namespace
│   ├── prometheus/            # Prometheus configuration
│   ├── grafana/              # Grafana configuration
│   └── alertmanager/         # AlertManager configuration
├── ingress/                   # Ingress resources
│   └── argocd-ingress.yaml   # ArgoCD ingress configuration
└── config/                    # Configuration management
    ├── environments/          # Environment-specific values
    │   ├── dev/
    │   ├── staging/
    │   └── production/
    └── templates/             # Configuration templates
```

## Usage

1. **Environment Configuration**: Update values in `config/environments/` for your specific environment
2. **Secrets**: Copy `secrets.yaml.template` files and update with actual credentials
3. **Deployment**: Apply manifests in the following order:
   - Cluster configuration
   - Namespaces
   - RBAC configurations
   - Core services (ArgoCD, Ingress Controller)
   - Monitoring stack
   - Ingress resources

## Validation

All manifest files should be validated using:
```bash
kubectl apply --dry-run=client -f <manifest-file>
```

For cluster-wide validation:
```bash
kubectl apply --dry-run=server -f k8s/ --recursive
```