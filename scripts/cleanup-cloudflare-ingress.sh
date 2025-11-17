#!/bin/bash
# Cloudflare Tunnel Ingress Controller クリーンアップスクリプト
# ArgoCD アプリケーションと cloudflare-tunnel-ingress-controller Namespace を削除します

set -euo pipefail

NAMESPACE="cloudflare-tunnel-ingress-controller"
APP_NAME="cloudflare-tunnel-ingress-controller"

echo "=========================================="
echo "Cloudflare Tunnel Ingress Controller クリーンアップ"
echo "=========================================="
echo ""
echo "警告: このスクリプトは以下を削除します："
echo "      - ArgoCD アプリケーション: ${APP_NAME}"
echo "      - Namespace: ${NAMESPACE}（Namespace 内のすべてのリソースも一緒に削除されます）"
echo ""

# ArgoCD アプリケーションの存在確認
APP_EXISTS=false
if kubectl get application "${APP_NAME}" -n argocd &>/dev/null; then
    APP_EXISTS=true
fi

# Namespace の存在確認
NS_EXISTS=false
if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    NS_EXISTS=true
fi

if [[ "${APP_EXISTS}" == "false" ]] && [[ "${NS_EXISTS}" == "false" ]]; then
    echo "ArgoCD アプリケーションと Namespace は存在しません。"
    echo "クリーンアップする必要はありません。"
    exit 0
fi

# 削除対象のリソースを表示
if [[ "${APP_EXISTS}" == "true" ]]; then
    echo "削除対象の ArgoCD アプリケーション:"
    kubectl get application "${APP_NAME}" -n argocd 2>/dev/null || echo "アプリケーション情報の取得に失敗しました。"
    echo ""
fi

if [[ "${NS_EXISTS}" == "true" ]]; then
    echo "削除対象の Namespace 内リソース:"
    kubectl get all -n "${NAMESPACE}" 2>/dev/null || echo "リソースが見つかりませんでした。"
    echo ""
fi

read -p "削除を実行してもよろしいですか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "中断しました。"
    exit 0
fi

# ArgoCD アプリケーションの削除
if [[ "${APP_EXISTS}" == "true" ]]; then
    echo ""
    echo "ArgoCD アプリケーションを削除しています..."
    argocd app delete "${APP_NAME}" --yes || {
        echo "警告: ArgoCD アプリケーションの削除中にエラーが発生しました。"
        echo "      手動で削除してください: argocd app delete ${APP_NAME} --yes"
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "中断しました。"
            exit 0
        fi
    }
    # アプリケーション削除の反映を待機
    sleep 2
fi

# Namespace の削除
if [[ "${NS_EXISTS}" == "true" ]]; then
    echo ""
    echo "${NAMESPACE} Namespace を削除しています..."
    kubectl delete namespace "${NAMESPACE}" --wait=true --timeout=300s || {
        echo "警告: Namespace の削除中にエラーが発生しました。"
        echo "      状態を確認してください: kubectl get namespace ${NAMESPACE}"
        exit 1
    }
fi

echo ""
echo "=========================================="
echo "Cloudflare Tunnel Ingress Controller クリーンアップ完了"
echo "=========================================="
echo ""
echo "ArgoCD アプリケーションと Namespace が削除されました。"
echo ""

