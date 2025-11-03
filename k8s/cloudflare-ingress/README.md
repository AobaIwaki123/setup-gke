```sh
$ helm repo add strrl.dev https://helm.strrl.dev
$ helm repo update
$ helm search repo cloudflare-tunnel-ingress-controller --versions | head -n3

NAME                                            CHART VERSION   APP VERSIONDESCRIPTION                                  
strrl.dev/cloudflare-tunnel-ingress-controller  0.0.18          0.0.18     Ingress Controller based on Cloudflare Tunnel
strrl.dev/cloudflare-tunnel-ingress-controller  0.0.16          0.0.16     Ingress Controller based on Cloudflare **Tunnel**
```

```sh
$ argocd app create --file app.yml
```
