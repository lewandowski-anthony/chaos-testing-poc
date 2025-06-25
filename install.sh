#!/bin/bash
set -euo pipefail

# --- Version  variables ---
K3S_INSTALL_URL="https://get.k3s.io"
HELM_INSTALL_SCRIPT="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
CHAOS_MESH_VERSION="2.7.2"
LITMUS_VERSION="3.16.0"
K9S_VERSION="v0.32.5"
K9S_DEB="k9s_linux_amd64.deb"

KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
export KUBECONFIG="$KUBECONFIG_PATH"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (sudo)."
  exit 1
fi

echo "🚀 Installing k3s (Lightweight Kubernetes)..."
curl -sfL "$K3S_INSTALL_URL" | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh - > /dev/null

echo "✅ k3s installed."

echo "🚀 Installing Helm..."
curl -fsSL "$HELM_INSTALL_SCRIPT" | bash > /dev/null

echo "✅ Helm installed."

echo "🛠 Setting up containerd socket symlink..."
mkdir -p /run/containerd
ln -sf /run/k3s/containerd/containerd.sock /run/containerd/containerd.sock

echo "✅ containerd socket configured."

echo "🚀 Creating namespaces for Chaos Mesh and Litmus..."
kubectl create ns chaos-mesh --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl create ns litmus --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✅ Namespaces created."

echo "📦 Installing Chaos Mesh Helm chart (version $CHAOS_MESH_VERSION)..."
helm repo add chaos-mesh https://charts.chaos-mesh.org > /dev/null
helm repo update > /dev/null
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock \
  --version "$CHAOS_MESH_VERSION" > /dev/null

echo "✅ Chaos Mesh installed."

echo "📦 Installing Litmus (version $LITMUS_VERSION)..."
helm repo add bitnami https://charts.bitnami.com/bitnami > /dev/null
helm install my-release bitnami/mongodb --values ./litmus/conf/mongo-values.yml -n litmus > /dev/null
kubectl apply -f "https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/$LITMUS_VERSION/litmus-getting-started.yaml" -n litmus > /dev/null

echo "✅ Litmus installed."

echo "⏳ Waiting for Chaos Mesh pods to be ready (up to 5 minutes)..."
kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=300s > /dev/null

echo "⏳ Waiting for Litmus pods to be ready (up to 5 minutes)..."
kubectl wait --for=condition=Ready pods --all -n litmus --timeout=300s > /dev/null

echo "🔁 Forwarding dashboards in background..."

pkill -f "kubectl port-forward" || true

kubectl port-forward svc/chaos-dashboard -n chaos-mesh 8080:2333 > /tmp/chaos-mesh.log 2>&1 &
kubectl port-forward svc/litmusportal-frontend-service -n litmus 9091:9091 > /tmp/litmus.log 2>&1 &

echo "✅ Dashboards are available:"
echo " - Chaos Mesh: http://localhost:8080"
echo " - Litmus Portal: http://localhost:9091"
echo ""
echo "ℹ️ Litmus default credentials:"
echo " - Username: admin"
echo " - Password: litmus"

echo "🚀 Creating 'test-app' namespace with a running NGINX deployment..."
kubectl create ns test-app --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✅ Namespace 'test-app' created."

echo "🚀 Deploying NGINX on 'test-app' namespace..."
kubectl apply -f ./test-env/ > /dev/null
echo "✅ NGINX deployed and exposed on http://localhost:30080"

echo "🚀 Installing K9s (version $K9S_VERSION)..."
wget -q "https://github.com/derailed/k9s/releases/download/$K9S_VERSION/$K9S_DEB"
apt install -y ./$K9S_DEB > /dev/null
rm -f $K9S_DEB
echo "✅ K9s installed."

echo "🚀 Deploying Chaos Mesh manifests..."
kubectl apply -f ./chaos-mesh/ > /dev/null

#kubectl apply -f ./litmus/  # Uncomment if needed

echo "⏳ Waiting for NGINX pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n test-app --timeout=120s > /dev/null

echo "✅ Your environment is fully ready to test Chaos Testing!"
echo "ℹ️ Remember to execute 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' command if you need to acces K9S"