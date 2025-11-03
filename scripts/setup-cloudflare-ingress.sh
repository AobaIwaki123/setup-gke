#!/bin/bash
# Cloudflare Tunnel Ingress Controller セットアップスクリプト
# ArgoCD 経由で Cloudflare Tunnel Ingress Controller をインストールします

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLOUDFLARE_DIR="${PROJECT_ROOT}/k8s/cloudflare-ingress"
APP_YAML="${CLOUDFLARE_DIR}/app.yaml"

echo "=========================================="
echo "Cloudflare Tunnel Ingress Controller セットアップ開始"
echo "=========================================="

# 事前チェック: app.yaml の存在確認
if [[ ! -f "${APP_YAML}" ]]; then
    echo "エラー: ${APP_YAML} が見つかりません。"
    exit 1
fi

# 事前チェック: app.yaml に未設定の値が残っていないか確認
echo ""
echo "app.yaml の設定を確認しています..."
if grep -q "API_TOKEN\|ACCOUNT_ID" "${APP_YAML}"; then
    echo "警告: app.yaml に未設定の値（API_TOKEN または ACCOUNT_ID）が残っています。"
    echo "      app.yaml を編集して、実際の値を設定してください。"
    echo "      （詳細は k8s/cloudflare-ingress/README.md を参照）"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "中断しました。"
        exit 0
    fi
fi

# 事前チェック: ArgoCD が利用可能か確認
echo ""
echo "ArgoCD の状態を確認しています..."
if ! kubectl get namespace argocd &>/dev/null; then
    echo "エラー: argocd Namespace が見つかりません。"
    echo "      先に ArgoCD をインストールしてください。"
    echo "      （詳細は k8s/argocd/README.md を参照）"
    exit 1
fi

if ! kubectl get deployment argocd-server -n argocd &>/dev/null; then
    echo "エラー: ArgoCD Server が見つかりません。"
    echo "      ArgoCD が正しくインストールされているか確認してください。"
    exit 1
fi

# 事前チェック: アプリケーションが既に存在するか確認
echo ""
echo "既存のアプリケーションを確認しています..."
if kubectl get application cloudflare-tunnel-ingress-controller -n argocd &>/dev/null; then
    echo "警告: cloudflare-tunnel-ingress-controller アプリケーションは既に存在します。"
    echo "      既存のアプリケーションを削除してから再作成しますか？"
    read -p "削除して再作成しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "既存のアプリケーションを削除しています..."
        argocd app delete cloudflare-tunnel-ingress-controller --yes || {
            echo "警告: アプリケーションの削除中にエラーが発生しました。"
            echo "      手動で削除してください: argocd app delete cloudflare-tunnel-ingress-controller"
            read -p "続行しますか？ (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "中断しました。"
                exit 0
            fi
        }
        # 削除完了まで少し待機
        sleep 3
    else
        echo "中断しました。既存のアプリケーションをそのまま使用します。"
        exit 0
    fi
fi

# 1. ArgoCD アプリケーションの作成
echo ""
echo "[1/1] ArgoCD アプリケーションを作成しています..."
argocd app create --file "${APP_YAML}" || {
    echo "エラー: アプリケーションの作成に失敗しました。"
    exit 1
}

# 2. アプリケーションの同期状態を確認
echo ""
echo "アプリケーションの同期状態を確認しています..."
echo "（初回同期には数分かかる場合があります）"
sleep 2

# アプリケーションの状態を表示
argocd app get cloudflare-tunnel-ingress-controller || {
    echo "警告: アプリケーションの状態取得に失敗しました。"
    echo "      手動で確認してください: argocd app get cloudflare-tunnel-ingress-controller"
}

echo ""
echo "=========================================="
echo "Cloudflare Tunnel Ingress Controller セットアップ完了"
echo "=========================================="
echo ""
echo "次の手順:"
echo ""
echo "1. アプリケーションの状態を確認:"
echo "   argocd app get cloudflare-tunnel-ingress-controller"
echo ""
echo "2. ArgoCD UI でアプリケーションの状態を確認:"
echo "   https://argocd-gke.aooba.net (または設定したIngressのURL)"
echo ""
echo "3. アプリケーションが Healthy になるまで待機してください。"
echo ""

