# ArgoCD セットアップ

ArgoCD を Kubernetes クラスターにインストールし、Cloudflare Tunnel Ingress Controller 経由で外部からアクセス可能にする手順です。

## スクリプトを使用したセットアップ

Cloudflare Ingress Controller 設定前後で実行できる2つのスクリプトを用意しています。

### 1. 初期セットアップ（Cloudflare Ingress Controller 設定前）

```sh
$ ./scripts/setup-argocd-initial.sh
```

このスクリプトは以下を実行します：
- ArgoCD Namespace の作成
- ArgoCD のインストール

実行後、初回ログインを行い、Cloudflare Ingress Controller を設定してください。

### 2. 公開設定（Cloudflare Ingress Controller 設定後）

> **注意**: このスクリプトを実行する前に、[Cloudflare Ingress Controller の設定](../cloudflare-ingress/README.md)が必要です。

```sh
$ ./scripts/setup-argocd-public.sh
```

このスクリプトは以下を実行します：
- ArgoCD Server を Ingress 経由でアクセス可能にする設定
- Ingress の適用
- API トークン生成の有効化

実行後、API トークンを生成してください。

### 3. クリーンアップ

ArgoCD を削除する場合は、以下のスクリプトを実行します。

> **警告**: このスクリプトは argocd Namespace とすべてのリソースを削除します。

```sh
$ ./scripts/cleanup-argocd.sh
```

このスクリプトは以下を実行します：
- argocd Namespace の存在確認
- 削除対象リソースの表示
- 確認プロンプト
- argocd Namespace の削除（Namespace 内のすべてのリソースも一緒に削除されます）

## 手動セットアップ

### インストール

ArgoCD をインストールします。

```sh
$ kubectl apply -f namespace.yaml
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 初回ログイン

ArgoCD にログインして初期パスワードを取得します。

```sh
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
$ kubectl port-forward svc/argocd-server -n argocd 8080:443
```

別ターミナルで

```sh
$ argocd admin initial-password -n argocd
INITIAL_PASSWORD
$ argocd login 127.0.0.1:8080
username: admin
password: INITIAL_PASSWORD
```

### ArgoCDを公開

Ingress 経由で外部からアクセス可能にするため、`server.insecure` を有効化し、Ingress を適用します。

> **注意**: この手順を実行する前に、[Cloudflare Ingress Controller の設定](../cloudflare-ingress/README.md)が必要です。

```sh
$ kubectl apply -f argocd-cmd-params-cm.yaml
$ kubectl rollout restart deployment argocd-server -n argocd
$ kubectl apply -f ingress.yaml
```

### GitHub Actionなど外部サービスからAPI経由でArgoCDを操作するための設定

API トークン生成を有効化するための設定を適用します。

```sh
$ kubectl apply -f argocd-cm.yaml
$ kubectl rollout restart deployment argocd-server -n argocd
```

### ArgoCD API トークンの生成

Ingress 経由でログインし、API トークンを生成します。

```sh
$ argocd login argocd-gke.aooba.net --username admin --password <your-password> --grpc-web
$ argocd account generate-token
```