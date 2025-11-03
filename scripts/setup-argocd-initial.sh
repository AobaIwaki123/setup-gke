#!/bin/bash
# ArgoCD 初期セットアップスクリプト
# Cloudflare Ingress Controller 設定前に実行します

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARGOCD_DIR="${PROJECT_ROOT}/k8s/argocd"

echo "=========================================="
echo "ArgoCD 初期セットアップ開始"
echo "=========================================="

# 1. Namespace の作成
echo ""
echo "[1/2] ArgoCD Namespace を作成しています..."
kubectl apply -f "${ARGOCD_DIR}/namespace.yaml"

# 2. ArgoCD のインストール
echo ""
echo "[2/2] ArgoCD をインストールしています..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD コンポーネントが起動するまで待機
echo ""
echo "ArgoCD コンポーネントの起動を待機しています..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || {
    echo "警告: ArgoCD Server の起動確認がタイムアウトしました。"
    echo "      状態を確認してください: kubectl get pods -n argocd"
}

echo ""
echo "=========================================="
echo "ArgoCD 初期セットアップ完了"
echo "=========================================="
echo ""
echo "次の手順: 初回ログインを行ってください"
echo ""
echo "1. NodePort に変更してポートフォワードを開始:"
echo "   kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"NodePort\"}}'"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "2. 別ターミナルで初期パスワードを取得してログイン:"
echo "   argocd admin initial-password -n argocd"
echo "   argocd login 127.0.0.1:8080"
echo ""
echo "3. Cloudflare Ingress Controller を設定してください"
echo "   （詳細は k8s/cloudflare-ingress/README.md を参照）"
echo ""
echo "4. 設定完了後、次のスクリプトを実行:"
echo "   ./scripts/setup-argocd-public.sh"
echo ""

