# Chaos Testing with Chaos Mesh and Litmus

This document summarizes how to write chaos tests for Kubernetes applications using **Chaos Mesh** and **Litmus**. Below, you'll find examples and explanations for Chaos Mesh YAML schedules. For Litmus, only the main section titles are provided for now.

---

## Chaos Mesh: Writing Chaos Tests Using YAML

Chaos Mesh uses Kubernetes Custom Resources (CRDs) to define chaos experiments. Here are some example schedules demonstrating common chaos scenarios on an NGINX app running in the `test-app` namespace.

### Portal installation
Once we executed the install script, we got access to Chaos Mesh Portal : 

![Portal](/docs/images/chaos_mesh/chaos_mesh_token.png)

As you can see above, a token creation is necessary in order to connect to the portal. It is well explained in the procedure when you *Click here to generate*

![Token](/docs/images/chaos_mesh/token_procedure.png)

Once you have created your token you can put it in the previous form and submit.

Once you have access to the dashboard, you can then create tests. 

In order to make tests repeatable, all the tests are written as **Schedule**, but you can create One-Time  Chaos experiments following this [link](https://chaos-mesh.org/docs/run-a-chaos-experiment/)

### 1. Network Loss Chaos Test

Simulates 80% network packet loss on all pods labeled `app=nginx` in `test-app` for 20 seconds.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: nginx-network-loss
  namespace: chaos-mesh
spec:
  #Since no enable: false exists, to stop CRON you have to put it on impossible date
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
  #Since no enable: false exists, to stop CRON you have to put it on impossible date
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
  #Since no enable: false exists, to stop CRON you have to put it on impossible date
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
  #Since no enable: false exists, to stop CRON you have to put it on impossible date
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

### Let's try a real chaos test
In order to check if everything is okay, we'll try to make a chaos test that will push the CPU pods to 100% of limit usage.
In order to do that, we use this manifest 
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: nginx-cpu-stress
  namespace: chaos-mesh
spec:
  schedule: "@every 5m" 
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
Then we can see that the test has successfully launched
![Test](/docs/images/chaos_mesh/chaos_cpu_stress.png)

Then you can check the result dashboard : 
![Test](/docs/images/chaos_mesh/dashboard_result.png)
---
### Workflows
If you want your chaos tests to execute in a specific order (serially) or simultaneously (in parallel), you can define a workflow in Chaos Mesh. A workflow allows you to orchestrate multiple chaos experiments with precise control over their execution order and concurrency.

Below is an example of a workflow YAML manifest that demonstrates how to run two chaos experiments — pod failure and network delay — in a sequential manner for pods labeled app=nginx in the test-app namespace:
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: full-nginx-chaos-workflow
  namespace: chaos-mesh
spec:
  entry: main-sequence
  templates:
    - name: main-sequence
      templateType: Serial
      deadline: 60s
      children:
        - nginx-chaos-sequence

    - name: nginx-pod-failure
      templateType: PodChaos
      deadline: 10s
      podChaos:
        selector:
          namespaces:
            - test-app
          labelSelectors:
            app: nginx
        mode: all
        action: pod-failure

    - name: nginx-network-delay
      templateType: NetworkChaos
      deadline: 10s
      networkChaos:
        selector:
          namespaces:
            - test-app
          labelSelectors:
            app: nginx
        mode: all
        action: delay
        delay:
          latency: 1000ms
          jitter: 100ms
          correlation: "25"
        direction: to

    - name: nginx-chaos-sequence
      templateType: Serial
      deadline: 10s
      children:
        - nginx-pod-failure
        - nginx-network-delay
```

#### Explanation of the Workflow Structure
- Workflow and templates: The workflow is composed of multiple templates. Each template defines either a chaos experiment or a sequence of chaos experiments.

- Entry template (main-sequence): This is the root node that starts the workflow execution. It is set as a Serial template, meaning the children will run one after the other, respecting the order.

- nginx-chaos-sequence: Another serial template grouping the two chaos experiments, ensuring nginx-pod-failure completes before nginx-network-delay starts.

- Chaos templates (nginx-pod-failure, nginx-network-delay): These define specific chaos actions.
  - PodChaos with pod-failure kills all targeted nginx pods.

  - NetworkChaos with delay injects network latency with specified latency, jitter, and correlation to traffic going to the pods.

- Deadlines: Each template has a deadline specifying how long that step or sequence can run before timing out. This helps avoid workflows hanging indefinitely.

- Mode all: Applies the chaos to all pods matching the selector in the target namespace.

#### Benefits of Using Workflows in Chaos Mesh
- Orchestration: You can chain chaos experiments in serial or run them in parallel (if you change templateType to Parallel), giving fine-grained control over the order and concurrency.

- Modularity: Complex tests can be composed of smaller reusable chaos templates.

- Timeouts: Deadlines help in preventing stuck chaos runs.

- Targeting: Select pods based on labels and namespaces to scope chaos precisely.

This workflow is a good starting point for simulating multiple failures in a controlled manner and analyzing your system’s resilience step-by-step. You can extend it by adding more templates (e.g., CPU stress, memory stress), adjusting timing, or switching between serial and parallel execution as needed.

The result of the test is a CrashLoopBakc on our pods : 
![KO](/docs/images/chaos_mesh/pod_ko_workflow.png)

But the workflow just shows that the two steps are done without more logs/information :
![LOGS](/docs/images/chaos_mesh/workflow_status.png)

You also have access to a workflow form/flowchart editors, but in the latest version we use (**2.7.2**) the flowchart and the form to create workflows **does not work and is full of bug (impossible to really delete a step, cannot submit at the end, no error message)**

---

## Litmus: Writing Chaos Tests

*(Sections to be detailed later)*

### 1. Preparing Litmus Chaos Experiments

### 2. Defining Chaos Engine CRDs

### 3. Running and Monitoring Chaos Experiments

### 4. Integrating with CI/CD Pipelines

---

Feel free to adapt these YAML manifests to your own use case by changing the namespace, labels, actions, or durations. Chaos Mesh offers rich experimentation capabilities for Kubernetes-native chaos testing.

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./02_install_environement.md">← Previous page : Install environement</a>
  <a href="./README.md" style="margin: 0 10px;">Back to README</a>
  <a href="">Next page : Chaos Testing →</a>
</div>