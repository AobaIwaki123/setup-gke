```sh
$ kubectl apply -f namespace.yaml
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

```sh
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

```sh
$ kubectl port-forward svc/argocd-server -n argocd 8080:443
```

```sh
$ argocd admin initial-password -n argocd
INITIAL_PASSWORD
$ argocd login 127.0.0.1:8080
username: admin
password: INITIAL_PASSWORD
```

```sh
$ kubectl apply -f argocd-cmd-params-cm.yaml
$ kubectl rollout restart deployment argocd-server -n argocd # ArgoCD Server を再起動
$ kubectl apply -f ingress.yaml
```

```sh
$ kubectl apply -f argocd-cm.yaml
$ kubectl rollout restart deployment argocd-server -n argocd
```

```sh
$ argocd login example.com --username admin --password <your-password> --grpc-web
$ argocd account generate-token
```