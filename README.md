
# Engineering POC Report
---

## 1. Introduction

This report documents a proof of concept (POC) for introducing Chaos Engineering into a Kubernetes environment using **Litmus** and **Chaos Mesh**.

---

## 2. Environment Setup

### 2.1 Kubernetes Cluster (k3s)

We used [k3s](https://k3s.io/), a lightweight Kubernetes distribution, to quickly bootstrap a cluster in a WSL (Windows Subsystem for Linux) environment.

#### Install k3s

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -
```

This command installs `k3s` and sets the kubeconfig with readable permissions for non-root users.

#### Set KUBECONFIG (if needed later)

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

---

## 3. Chaos Engineering with Litmus

### Prerequisite
[Documentation](https://docs.litmuschaos.io/docs/getting-started/installation#installation)

### 3.1 Installation

#### Create Namespace

```bash
kubectl create ns litmus
```

#### Apply Litmus Manifest (version 3.16.0 latest)

In order to perform this, you'll have to create a mong-values.yml to perform the helm install
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/mongodb --values ./litmus/conf/mongo-values.yml -n litmus
kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.16.0/litmus-getting-started.yaml -n litmus
```
You can also directly copy the YAML inside your kustomization repository
#### Wait for all Litmus pods to be ready

```bash
kubectl wait --for=condition=Ready pods --all -n litmus --timeout=300s
```

### 3.2 Accessing the Litmus Portal

#### Port Forward (from WSL)

```bash
kubectl port-forward svc/litmusportal-frontend-service -n litmus 9091:9091
```

#### Access from your browser

- If inside WSL:  
  [http://localhost:9091](http://localhost:9091)
  
- From Windows host (WSL IP):  
  Find IP:
  ```bash
  ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1
  ```
  Then open:  
  `http://<WSL-IP>:9091`

#### Default credentials

```
Username: admin
Password: litmus
```

Create a Subscriber 
[[subscriber_connected.png]]
### 3.2 Create your scenarios
#### Set the expected resources

---

## 4. Chaos Engineering with Chaos Mesh

### 4.1 Installation

#### Create Namespace

```bash
kubectl create ns chaos-mesh
```

#### Add Helm repo and install chart

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh --namespace chaos-mesh --create-namespace
```

#### Wait for all Chaos Mesh pods to be ready

```bash
kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=300s
```

---

### 4.2 Accessing the Chaos Mesh Dashboard

#### Port Forward

```bash
kubectl port-forward svc/chaos-dashboard -n chaos-mesh 8080:2333
```

#### Access from your browser

- If inside WSL:  
  [http://localhost:8080](http://localhost:8080)
  
- From Windows host (WSL IP):  
  `http://<WSL-IP>:8080`

---

## 6. Appendix

### Full Installation Script

```bash
#!/bin/bash

set -e

  

if [ "$EUID" -ne 0 ]; then

  echo "Please run this script as root (sudo)."

  exit 1

fi

  

echo "🚀 Installing k3s (Lightweight Kubernetes)..."

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -

  

echo "🚀 Installing Helm..."

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

  

sudo mkdir -p /run/containerd

sudo ln -s /run/k3s/containerd/containerd.sock /run/containerd/containerd.sock

  

USER_NAME=$(logname)

  

# Add export KUBECONFIG to env

if ! grep -q '^KUBECONFIG=' /etc/environment; then

  echo 'KUBECONFIG="/etc/rancher/k3s/k3s.yaml"' >> /etc/environment

fi

  

echo "🚀 Creating namespaces for Chaos Mesh and Litmus..."

kubectl create ns chaos-mesh --dry-run=client -o yaml | kubectl apply -f -

kubectl create ns litmus --dry-run=client -o yaml | kubectl apply -f -

  

echo "📦 Installing Chaos Mesh via Helm with containerd runtime support and /dev/fuse mount..."

helm repo add chaos-mesh https://charts.chaos-mesh.org

helm repo update

helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh \

    --set chaosDaemon.runtime=containerd \

    --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock \

    --version 2.7.2

  
  

echo "📦 Installing Litmus (version 3.16.0) via kubectl manifest..."

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install my-release bitnami/mongodb --values ./litmus/conf/mongo-values.yml -n litmus

kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.16.0/litmus-getting-started.yaml -n litmus

  

echo "⏳ Waiting for Chaos Mesh pods to be ready (up to 5 minutes)..."

kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=300s

  

echo "⏳ Waiting for Litmus pods to be ready (up to 5 minutes)..."

kubectl wait --for=condition=Ready pods --all -n litmus --timeout=300s

  

echo "🔁 Forwarding dashboards in background..."

  

pkill -f "kubectl port-forward" || true

  

kubectl port-forward svc/chaos-dashboard -n chaos-mesh 8080:2333 > /tmp/chaos-mesh.log 2>&1 &

kubectl port-forward svc/litmusportal-frontend-service -n litmus 9091:9091 > /tmp/litmus.log 2>&1 &

  

echo "✅ Dashboards are available:"

echo " - Chaos Mesh: http://localhost:8080"

echo " - Litmus Portal: http://localhost:9091"

echo ""

echo "Litmus default credentials:"

echo " - Username: admin"

echo " - Password: litmus"

  

echo "🚀 Creating 'test-app' namespace with a running NGINX deployment..."

kubectl create ns test-app --dry-run=client -o yaml | kubectl apply -f -

echo "NGINX deployed in 'test-app' namespace and exposed on http://localhost:30080"

  

echo "🚀 Installing K9s"

wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb

apt install ./k9s_linux_amd64.deb

rm k9s_linux_amd64.deb

  

echo "🚀 Deploying env"

kubectl apply -f ./test-env/

kubectl apply -f ./chaos-mesh/

#kubectl apply -f ./litmus/

  

echo "⏳ Waiting for NGINX pods to be ready..."

kubectl wait --for=condition=Ready pods --all -n test-app --timeout=120s

  
  

echo "✅ Your env is fully ready to test Chaos Testing !"
```

