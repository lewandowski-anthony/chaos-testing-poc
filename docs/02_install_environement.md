# 🚀 Chaos Engineering Environment Setup with K3s, Chaos Mesh, and Litmus

## 📜 Table of content
- [🚀 Chaos Engineering Environment Setup with K3s, Chaos Mesh, and Litmus](#-chaos-engineering-environment-setup-with-k3s-chaos-mesh-and-litmus)
  - [📜 Table of content](#-table-of-content)
  - [✅ Prerequisites](#-prerequisites)
  - [🛠️ Installation](#️-installation)
  - [📋 What the Script Does (Step-by-Step)](#-what-the-script-does-step-by-step)
    - [1. 🧱 Install K3s (Lightweight Kubernetes)](#1--install-k3s-lightweight-kubernetes)
    - [2. 📦 Install Helm](#2--install-helm)
    - [3. 🧪 Create Kubernetes Namespaces](#3--create-kubernetes-namespaces)
    - [4. ⚙️ Deploy Chaos Mesh via Helm](#4-️-deploy-chaos-mesh-via-helm)
    - [5. 🧬 Deploy Litmus via Manifest](#5--deploy-litmus-via-manifest)
    - [6. ⏳ Wait for All Pods to Be Ready](#6--wait-for-all-pods-to-be-ready)
    - [7. 🌐 Port-Forward Dashboards](#7--port-forward-dashboards)
    - [8. 🌐 Create a Sample Test App (NGINX)](#8--create-a-sample-test-app-nginx)
    - [9. 🖥️ Install K9s (CLI Kubernetes Dashboard)](#9-️-install-k9s-cli-kubernetes-dashboard)
  - [✅ Final Message](#-final-message)

## ✅ Prerequisites

Before running the installation, ensure the following requirements are met to guarantee a smooth setup:

- You must have a **Linux environment** or **WSL2** (Windows Subsystem for Linux 2) with **root (sudo) access**. This is necessary because installing Kubernetes components and modifying system files require elevated permissions.
- A stable **internet connection** is required, as the script downloads Kubernetes components, Helm, and related manifests.
- No Docker installation is needed — this setup relies on **containerd**, the lightweight container runtime integrated into K3s.

---

## 🛠️ Installation

Run the installation script with root privileges:

```bash
sudo ./install.sh
```

This script automates the entire installation process: from installing K3s, Helm, deploying Chaos Mesh and Litmus, creating namespaces, deploying test apps, and setting up port forwarding for dashboards.

---

## 📋 What the Script Does (Step-by-Step)

This section breaks down each major step performed by the installation script, explaining the purpose and commands used.

---

### 1. 🧱 Install K3s (Lightweight Kubernetes)

K3s is a minimal Kubernetes distribution optimized for resource-constrained environments. This step installs K3s with the containerd runtime and makes sure the Kubernetes configuration file (`kubeconfig`) is set with the right permissions for user access.

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -
```

The environment variable pointing to the kubeconfig file is set:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Additionally, to make this configuration persistent across sessions and users, the script adds the variable system-wide:

```bash
echo "KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment
```

Because Chaos Mesh needs direct access to the container runtime socket, the script creates the expected directory and links containerd’s socket accordingly:

```bash
sudo mkdir -p /run/containerd
sudo ln -s /run/k3s/containerd/containerd.sock /run/containerd/containerd.sock
```

---

### 2. 📦 Install Helm

Helm is the de facto package manager for Kubernetes, simplifying deployment and management of complex applications by using “charts” (pre-configured Kubernetes resources).

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

### 3. 🧪 Create Kubernetes Namespaces

To keep deployments organized and isolated, dedicated Kubernetes namespaces are created for Chaos Mesh and LitmusChaos:

```bash
kubectl create ns chaos-mesh --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns litmus --dry-run=client -o yaml | kubectl apply -f -
```

---

### 4. ⚙️ Deploy Chaos Mesh via Helm

Chaos Mesh is installed using Helm, adding its official chart repository and specifying configuration to ensure compatibility with the containerd runtime used by K3s.

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock \
  --version 2.7.2
```

---

### 5. 🧬 Deploy Litmus via Manifest

Litmus requires MongoDB as its backend, so the script first installs MongoDB using Helm from Bitnami’s chart repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/mongodb --values ./litmus/conf/mongo-values.yml -n litmus
```

After that, the Litmus core components are deployed directly via Kubernetes manifests:

```bash
kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.16.0/litmus-getting-started.yaml -n litmus
```

---

### 6. ⏳ Wait for All Pods to Be Ready

The script waits until all pods in both namespaces (`chaos-mesh` and `litmus`) are in the `Ready` state before proceeding. This ensures the cluster components are fully operational.

```bash
kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=300s
kubectl wait --for=condition=Ready pods --all -n litmus --timeout=300s
```

---

### 7. 🌐 Port-Forward Dashboards

To access the web dashboards of Chaos Mesh and Litmus locally, the script forwards the service ports to the local machine. This is done in the background so that users can interact with the dashboards via their browser.

```bash
kubectl port-forward svc/chaos-dashboard -n chaos-mesh 8080:2333 &
kubectl port-forward svc/litmusportal-frontend-service -n litmus 9091:9091 &
```

Access the dashboards here:

- Chaos Mesh UI: [http://localhost:8080](http://localhost:8080)
- Litmus Portal: [http://localhost:9091](http://localhost:9091)

Default Litmus credentials are:

- Username: `admin`
- Password: `litmus`

---

### 8. 🌐 Create a Sample Test App (NGINX)

To provide a real workload for chaos experiments, an example NGINX deployment is created inside the `test-app` namespace.

```bash
kubectl create ns test-app --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f ./test-env/
```

NGINX will be accessible locally at:

- [http://localhost:30080](http://localhost:30080)

---

### 9. 🖥️ Install K9s (CLI Kubernetes Dashboard)

K9s is a helpful terminal UI tool for navigating Kubernetes clusters, making it easier to inspect resources and logs without needing to switch to GUI dashboards.

```bash
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb
sudo apt install ./k9s_linux_amd64.deb
rm k9s_linux_amd64.deb
```

---

## ✅ Final Message

With everything installed, configured, and running, you now have a powerful chaos engineering environment based on lightweight Kubernetes (K3s), featuring two mature open-source chaos frameworks: **Chaos Mesh** and **Litmus**.

Feel free to start experimenting with chaos scenarios to build resilience and better understand failure modes in your applications.

Happy chaos testing! 💥

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./01_goal_of_the_poc.md">← Previous page : Goal of the POC</a>
  <a href="./README.md" style="margin: 0 10px;">Back to README</a>
  <a href="./03_chaos_testing.md">Next page : Chaos Testing →</a>
</div>
