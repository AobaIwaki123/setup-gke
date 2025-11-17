#!/bin/bash
# ArgoCD クリーンアップスクリプト
# ArgoCD Namespace とすべてのリソースを削除します

set -euo pipefail

echo "=========================================="
echo "ArgoCD クリーンアップ"
echo "=========================================="
echo ""
echo "警告: このスクリプトは argocd Namespace を削除します。"
echo "      Namespace 内のすべてのリソース（Deployment、Service、Ingress など）も"
echo "      一緒に削除されます。"
echo ""

# argocd Namespace の存在確認
if ! kubectl get namespace argocd &>/dev/null; then
    echo "argocd Namespace は存在しません。"
    echo "クリーンアップする必要はありません。"
    exit 0
fi

echo "削除対象のリソースを確認:"
kubectl get all -n argocd 2>/dev/null || echo "リソースが見つかりませんでした。"
echo ""

read -p "argocd Namespace を削除してもよろしいですか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "中断しました。"
    exit 0
fi

echo ""
echo "argocd Namespace を削除しています..."
kubectl delete namespace argocd --wait=true --timeout=300s || {
    echo "警告: Namespace の削除中にエラーが発生しました。"
    echo "      状態を確認してください: kubectl get namespace argocd"
    exit 1
}

echo ""
echo "=========================================="
echo "ArgoCD クリーンアップ完了"
echo "=========================================="
echo ""
echo "argocd Namespace とすべてのリソースが削除されました。"
echo ""

