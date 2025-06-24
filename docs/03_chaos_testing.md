# Chaos Testing with Chaos Mesh and Litmus

This document summarizes how to write chaos tests for Kubernetes applications using **Chaos Mesh** and **Litmus**. Below, you'll find examples and explanations for Chaos Mesh YAML schedules. For Litmus, only the main section titles are provided for now.

---

## Chaos Mesh: Writing Chaos Tests Using YAML

Chaos Mesh uses Kubernetes Custom Resources (CRDs) to define chaos experiments. Here are some example schedules demonstrating common chaos scenarios on an NGINX app running in the `test-app` namespace.

### Portal installation
Once we executed the install script, we got access to Chaos Mesh Portal : 
<p align="center">
  <img src="/docs/images/chaos_mesh/chaos_mesh_token.png" alt="chaos-mesh" />
</p>


### 1. Network Loss Chaos Test

Simulates 80% network packet loss on all pods labeled `app=nginx` in `test-app` for 20 seconds.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: nginx-network-loss
  namespace: chaos-mesh
spec:
  schedule: "0 0 31 2 *"
  concurrencyPolicy: "Forbid"
  type: NetworkChaos
  networkChaos:
    selector:
      namespaces: [test-app]
      labelSelectors:
        app: nginx
    action: loss
    mode: all
    loss:
      loss: "80"
      correlation: "0"
    duration: "20s"
```

### 2. Pod Kill Chaos Test

Kills one random pod labeled `app=nginx` in `test-app` for 10 seconds.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: pod-kill-nginx-schedule
  namespace: chaos-mesh
spec:
  schedule: "0 0 31 2 *"
  concurrencyPolicy: "Forbid"
  type: PodChaos
  podChaos:
    selector:
      namespaces: [test-app]
      labelSelectors:
        app: nginx
    action: pod-kill
    mode: one
    duration: "10s"
```

### 3. CPU Stress Chaos Test

Applies CPU stress to all `app=nginx` pods in `test-app` with 20 worker threads for 60 seconds.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: nginx-cpu-stress
  namespace: chaos-mesh
spec:
  schedule: "0 0 31 2 *"
  concurrencyPolicy: "Forbid"
  type: StressChaos
  stressChaos:
    selector:
      namespaces: [test-app]
      labelSelectors:
        app: nginx
    mode: all
    stressors:
      cpu:
        workers: 20
    duration: "60s"
```

### 4. Memory Stress Chaos Test

Applies memory stress on one `app=nginx` pod in `test-app`, allocating about 200MB for 20 seconds.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: nginx-memory-stress
  namespace: chaos-mesh
spec:
  schedule: "0 0 31 2 *"
  concurrencyPolicy: "Forbid"
  type: StressChaos
  stressChaos:
    selector:
      namespaces: [test-app]
      labelSelectors:
        app: nginx
    mode: one
    stressors:
      memory:
        workers: 1
        size: "209715200"
    duration: "20s"
```

---

## Litmus: Writing Chaos Tests

*(Sections to be detailed later)*

### 1. Preparing Litmus Chaos Experiments

### 2. Defining Chaos Engine CRDs

### 3. Running and Monitoring Chaos Experiments

### 4. Integrating with CI/CD Pipelines

---

Feel free to adapt these YAML manifests to your own use case by changing the namespace, labels, actions, or durations. Chaos Mesh offers rich experimentation capabilities for Kubernetes-native chaos testing.
