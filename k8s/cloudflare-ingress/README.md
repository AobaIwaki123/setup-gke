# Cloudflare Tunnel Ingress Controller セットアップ

Cloudflare Tunnel Ingress Controller を ArgoCD 経由で Kubernetes クラスターにインストールし、外部からアクセス可能にする手順です。

## 前提条件

- ArgoCD がインストールされていること
- Cloudflare アカウントを持っていること
- 以下の情報を準備していること：
  - Cloudflare API トークン（Zone:DNS:Edit, Account:Cloudflare Tunnel:Edit 権限が必要）
  - Cloudflare アカウント ID
  - Cloudflare Tunnel 名（事前に Cloudflare ダッシュボードで作成が必要）

## スクリプトを使用したセットアップ

### 1. app.yaml の設定

`app.yaml` ファイルを編集して、以下の値を設定します：

- `apiToken`: Cloudflare API トークン
- `accountId`: Cloudflare アカウント ID
- `tunnelName`: Cloudflare Tunnel 名（デフォルト: `gke-tunnel-ingress-controller`）

```yaml
helm:
  valuesObject:
    cloudflare:
      apiToken: API_TOKEN        # 実際のAPIトークンに置き換え
      accountId: ACCOUNT_ID      # 実際のアカウントIDに置き換え
      tunnelName: gke-tunnel-ingress-controller
```

### 2. セットアップスクリプトの実行

```sh
$ ./scripts/setup-cloudflare-ingress.sh
```

このスクリプトは以下を実行します：
- `app.yaml` の存在と設定値の確認
- ArgoCD の状態確認
- 既存アプリケーションの有無確認
- ArgoCD アプリケーションの作成
- 同期状態の確認

### 3. クリーンアップ

Cloudflare Tunnel Ingress Controller を削除する場合は、以下のスクリプトを実行します。

> **警告**: このスクリプトは ArgoCD アプリケーションと `cloudflare-tunnel-ingress-controller` Namespace を削除します。Namespace 内のすべてのリソースも一緒に削除されます。

```sh
$ ./scripts/cleanup-cloudflare-ingress.sh
```

このスクリプトは以下を実行します：
- ArgoCD アプリケーションの存在確認
- Namespace の存在確認
- 削除対象リソースの表示
- 確認プロンプト
- ArgoCD アプリケーションの削除
- Namespace の削除（Namespace 内のすべてのリソースも一緒に削除されます）

## 手動セットアップ

### 1. Helm リポジトリの追加とアップデート

```sh
$ helm repo add strrl.dev https://helm.strrl.dev
$ helm repo update
```

### 2. 利用可能なチャートバージョンの確認（オプション）

```sh
$ helm search repo cloudflare-tunnel-ingress-controller --versions | head -n3

NAME                                            CHART VERSION   APP VERSION   DESCRIPTION                                  
strrl.dev/cloudflare-tunnel-ingress-controller  0.0.18          0.0.18        Ingress Controller based on Cloudflare Tunnel
strrl.dev/cloudflare-tunnel-ingress-controller  0.0.16          0.0.16        Ingress Controller based on Cloudflare Tunnel
```

### 3. app.yaml の設定

`app.yaml` ファイルを編集して、以下の値を設定します：

- `apiToken`: Cloudflare API トークン
- `accountId`: Cloudflare アカウント ID
- `tunnelName`: Cloudflare Tunnel 名（デフォルト: `gke-tunnel-ingress-controller`）

```yaml
helm:
  valuesObject:
    cloudflare:
      apiToken: API_TOKEN        # 実際のAPIトークンに置き換え
      accountId: ACCOUNT_ID      # 実際のアカウントIDに置き換え
      tunnelName: gke-tunnel-ingress-controller
```

### 4. ArgoCD アプリケーションの作成

```sh
$ argocd app create --file app.yaml
```

### 5. アプリケーションの同期確認

ArgoCD UI または CLI でアプリケーションの状態を確認します。

```sh
$ argocd app get cloudflare-tunnel-ingress-controller
```

## その他の情報

- ArgoCD アプリケーションは自動同期が有効になっているため、変更は自動的に反映されます
- Namespace が存在しない場合は自動作成されます
- クリーンアップ時は `cleanup-cloudflare-ingress.sh` スクリプトを使用してください。このスクリプトは ArgoCD アプリケーションと Namespace の両方を削除します
