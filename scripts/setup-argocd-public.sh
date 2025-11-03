#!/bin/bash
# ArgoCD 公開設定スクリプト
# Cloudflare Ingress Controller 設定後に実行します

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARGOCD_DIR="${PROJECT_ROOT}/k8s/argocd"

echo "=========================================="
echo "ArgoCD 公開設定開始"
echo "=========================================="

# 事前チェック: Cloudflare Ingress Controller がインストールされているか確認
echo ""
echo "Cloudflare Ingress Controller の状態を確認しています..."
if ! kubectl get ingressclass cloudflare-tunnel &>/dev/null; then
    echo "警告: cloudflare-tunnel IngressClass が見つかりません。"
    echo "      Cloudflare Ingress Controller が正しく設定されているか確認してください。"
    echo "      （詳細は k8s/cloudflare-ingress/README.md を参照）"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "中断しました。"
        exit 1
    fi
fi

# 1. ArgoCD を外部公開可能にする設定
echo ""
echo "[1/3] ArgoCD Server を Ingress 経由でアクセス可能にする設定を適用しています..."
kubectl apply -f "${ARGOCD_DIR}/argocd-cmd-params-cm.yaml"
kubectl rollout restart deployment argocd-server -n argocd

echo "ArgoCD Server の再起動を待機しています..."
kubectl rollout status deployment argocd-server -n argocd --timeout=180s

# 2. Ingress の適用
echo ""
echo "[2/3] Ingress を適用しています..."
kubectl apply -f "${ARGOCD_DIR}/ingress.yaml"

# 3. API トークン生成の有効化
echo ""
echo "[3/3] API トークン生成を有効化しています..."
kubectl apply -f "${ARGOCD_DIR}/argocd-cm.yaml"
kubectl rollout restart deployment argocd-server -n argocd

echo "ArgoCD Server の再起動を待機しています..."
kubectl rollout status deployment argocd-server -n argocd --timeout=180s

echo ""
echo "=========================================="
echo "ArgoCD 公開設定完了"
echo "=========================================="
echo ""
echo "次の手順: API トークンを生成してください"
echo ""
echo "Ingress 経由でログインして API トークンを生成:"
echo "  argocd login argocd-gke.aooba.net --username admin --password <your-password> --grpc-web"
echo "  argocd account generate-token"
echo ""
echo "API トークンは GitHub Actions などの外部サービスから ArgoCD を操作する際に使用します。"
echo ""

