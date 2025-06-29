# Chaos Testing with Chaos Mesh and Litmus

This document summarizes how to write chaos tests for Kubernetes applications using **Chaos Mesh** and **Litmus**. Below, you'll find examples and explanations for Chaos Mesh YAML schedules. For Litmus, only the main section titles are provided for now.

---
- [Chaos Testing with Chaos Mesh and Litmus](#chaos-testing-with-chaos-mesh-and-litmus)
  - [Chaos Mesh: Writing Chaos Tests Using YAML](#chaos-mesh-writing-chaos-tests-using-yaml)
    - [Portal installation](#portal-installation)
    - [1. Network Loss Chaos Test](#1-network-loss-chaos-test)
    - [2. Pod Kill Chaos Test](#2-pod-kill-chaos-test)
    - [3. CPU Stress Chaos Test](#3-cpu-stress-chaos-test)
    - [4. Memory Stress Chaos Test](#4-memory-stress-chaos-test)
    - [Let's try a real chaos test](#lets-try-a-real-chaos-test)
  - [](#)
    - [Workflows](#workflows)
      - [Explanation of the Workflow Structure](#explanation-of-the-workflow-structure)
      - [Benefits of Using Workflows in Chaos Mesh](#benefits-of-using-workflows-in-chaos-mesh)
  - [Litmus: Writing Chaos Tests](#litmus-writing-chaos-tests)
    - [Portal Installation](#portal-installation-1)
    - [1. Using the GUI](#1-using-the-gui)
    - [2. Using Manifest](#2-using-manifest)
      - [Defining Chaos Engine CRDs](#defining-chaos-engine-crds)
      - [Example: Kill an Nginx pod](#example-kill-an-nginx-pod)
      - [Running and Monitoring Chaos Experiments](#running-and-monitoring-chaos-experiments)
      - [Work with workflows :](#work-with-workflows-)
    - [3. Integrating with CI/CD Pipelines](#3-integrating-with-cicd-pipelines)
      - [Example: GitLab CI](#example-gitlab-ci)

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

LitmusChaos is a Kubernetes-native chaos engineering platform designed to help you verify the resilience of your microservices by injecting controlled failures into your Kubernetes environment.

---

### Portal Installation

After running the installation script, you can access the Litmus Portal using the default admin credentials:  
- **Username:** admin  
- **Password:** litmus

Make sure to change these credentials to secure your portal.

Next, you need to create an environment (e.g., QUAL, PREPROD, PRODUCTION):  
![ENV](/docs/images/litmus/create_env.png)

Before creating your first chaos experiment, define a *probe* — a test that checks whether the targeted service remains healthy. Probes can be HTTP requests, Kubernetes health checks, Prometheus queries, or even custom commands:  
![Probe](/docs/images/litmus/create_probe.png)

You also need a *subscriber* to grant access to the namespaces targeted by your experiments. When first created, the subscriber will appear as “pending” in the portal:  
![Pending](/docs/images/litmus/pending_subscriber.png)

A common issue is that the default LitmusChaos configuration uses a localhost IP, causing the subscriber pod to enter a **CrashLoopBackOff** state. To fix this, modify the subscriber manifest to point to the cluster DNS address of the portal frontend service instead of localhost, for example:  
http://litmusportal-frontend-service.litmus.svc.cluster.local:9091/api/query

![CHANGE_FRONT_URI](/docs/images/litmus/change_front_url.png)

Once updated, your subscriber will show a CONNECTED status:  
![Connected](/docs/images/litmus/subscriber_connected.png)

Now you’re ready to create chaos experiments.

---

### 1. Using the GUI

You can create a new experiment via the portal:  
![NEW](/docs/images/litmus/new_experiment.png)

After filling the form, choose to start from a blank canvas, a template, or upload a YAML file.  
(**Note:** Be cautious with YAML uploads as syntax error messages are not always clear.)  
![TEMPLATE_BLANK](/docs/images/litmus/experiment_from_template_or_blank.png)

You can then build your workflow with a variety of available faults:  
![FAULTS_1](/docs/images/litmus/available_litmus_faults_1.png)  
![FAULTS_2](/docs/images/litmus/available_litmus_faults_2.png)  
![FAULTS_3](/docs/images/litmus/available_litmus_faults_3.png)  
![FAULTS_4](/docs/images/litmus/available_litmus_faults_4.png)

The LitmusChaos flowchart UI makes it easy to design complex workflows visually:  
![CREATE_EXPERIMENT](/docs/images/litmus/create_experiment.png)

Once started, the visual results will show which faults passed successfully without any probe failures:  
![RESULT](/docs/images/litmus/chaos_test_result.png)

You can also monitor your pods directly in the target namespace to see any errors:  
![OOM](/docs/images/litmus/litmus_oom_performed.png)  
![ERROR](/docs/images/litmus/litmus_error_in_progress.png)

---
### 2. Using Manifest

#### Defining Chaos Engine CRDs

A Litmus test is composed of two main CRDs:
- **ChaosExperiment**: Defines the type of chaos (e.g., `pod-delete`).
- **ChaosEngine**: Links the experiment to the target app.

#### Example: Kill an Nginx pod

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: nginx-pod-delete
  namespace: litmus
spec:
  appinfo:
    appns: test-app
    label: app=nginx
    kind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "20"
            - name: FORCE
              value: "true"
```

⚠️ Make sure to adapt `label` and `kind` to match your target app.

---

#### Running and Monitoring Chaos Experiments

Apply your experiment:

```bash
kubectl apply -f pod-delete-chaosengine.yaml
```

Check the status:

```bash
kubectl describe chaosengine nginx-pod-delete -n litmus
kubectl get chaosexperiment -n litmus
kubectl get chaosresult -n litmus
```

You can also use the Litmus portal at `http://localhost:9091` to monitor experiments visually.

---

#### Work with workflows : 

In order to create workflows, and due to the complexity of the Litmus Workflows, **you have to use the GUI to create these workflows**
You can also use workflow in order to perform test simultaneously or serialy : 
```yaml
kind: Workflow
apiVersion: argoproj.io/v1alpha1
metadata:
  name: test
  namespace: litmus
  creationTimestamp: null
  labels:
    infra_id: 5ee3b252-7bb3-4633-90cb-e9b83d404b18
    revision_id: 8cb4971b-e244-41cc-bc88-8cd3b5639aae
    workflow_id: 4b07cf9f-d599-44e0-83f1-580fb604b38e
    workflows.argoproj.io/controller-instanceid: 5ee3b252-7bb3-4633-90cb-e9b83d404b18
spec:
  templates:
    - name: test
      inputs: {}
      outputs: {}
      metadata: {}
      steps:
        - - name: install-chaos-faults
            template: install-chaos-faults
            arguments: {}
        - - name: pod-network-loss-jcn
            template: pod-network-loss-jcn
            arguments: {}
        - - name: pod-cpu-hog-ixb
            template: pod-cpu-hog-ixb
            arguments: {}
          - name: pod-memory-hog-a7u
            template: pod-memory-hog-a7u
            arguments: {}
        - - name: container-kill-6b3
            template: container-kill-6b3
            arguments: {}
        - - name: cleanup-chaos-resources
            template: cleanup-chaos-resources
            arguments: {}
    - name: install-chaos-faults
      inputs:
        artifacts:
          - name: pod-network-loss-jcn
            path: /tmp/pod-network-loss-jcn.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                description:
                  message: |
                    Injects network packet loss on pods belonging to an app deployment
                kind: ChaosExperiment

                metadata:
                  name: pod-network-loss
                  labels:
                    name: pod-network-loss
                    app.kubernetes.io/part-of: litmus
                    app.kubernetes.io/component: chaosexperiment
                    app.kubernetes.io/version: 3.16.0
                spec:
                  definition:
                    scope: Namespaced
                    permissions:
                      - apiGroups:
                          - ""
                        resources:
                          - pods
                        verbs:
                          - create
                          - delete
                          - get
                          - list
                          - patch
                          - update
                          - deletecollection
                      - apiGroups:
                          - ""
                        resources:
                          - events
                        verbs:
                          - create
                          - get
                          - list
                          - patch
                          - update
                      - apiGroups:
                          - ""
                        resources:
                          - configmaps
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - ""
                        resources:
                          - pods/log
                        verbs:
                          - get
                          - list
                          - watch
                      - apiGroups:
                          - ""
                        resources:
                          - pods/exec
                        verbs:
                          - get
                          - list
                          - create
                      - apiGroups:
                          - apps
                        resources:
                          - deployments
                          - statefulsets
                          - replicasets
                          - daemonsets
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - apps.openshift.io
                        resources:
                          - deploymentconfigs
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - ""
                        resources:
                          - replicationcontrollers
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - argoproj.io
                        resources:
                          - rollouts
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - batch
                        resources:
                          - jobs
                        verbs:
                          - create
                          - list
                          - get
                          - delete
                          - deletecollection
                      - apiGroups:
                          - litmuschaos.io
                        resources:
                          - chaosengines
                          - chaosexperiments
                          - chaosresults
                        verbs:
                          - create
                          - list
                          - get
                          - patch
                          - update
                          - delete
                    image: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                    imagePullPolicy: Always
                    args:
                      - -c
                      - ./experiments -name pod-network-loss
                    command:
                      - /bin/bash
                    env:
                      - name: TARGET_CONTAINER
                        value: ""
                      - name: LIB_IMAGE
                        value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                      - name: NETWORK_INTERFACE
                        value: eth0
                      - name: TC_IMAGE
                        value: gaiadocker/iproute2
                      - name: NETWORK_PACKET_LOSS_PERCENTAGE
                        value: "100"
                      - name: TOTAL_CHAOS_DURATION
                        value: "60"
                      - name: RAMP_TIME
                        value: ""
                      - name: PODS_AFFECTED_PERC
                        value: ""
                      - name: DEFAULT_HEALTH_CHECK
                        value: "false"
                      - name: TARGET_PODS
                        value: ""
                      - name: NODE_LABEL
                        value: ""
                      - name: CONTAINER_RUNTIME
                        value: containerd
                      - name: DESTINATION_IPS
                        value: ""
                      - name: DESTINATION_HOSTS
                        value: ""
                      - name: SOCKET_PATH
                        value: /run/containerd/containerd.sock
                      - name: SEQUENCE
                        value: parallel
                    labels:
                      name: pod-network-loss
                      app.kubernetes.io/part-of: litmus
                      app.kubernetes.io/component: experiment-job
                      app.kubernetes.io/runtime-api-usage: "true"
                      app.kubernetes.io/version: 3.16.0
          - name: pod-cpu-hog-ixb
            path: /tmp/pod-cpu-hog-ixb.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                description:
                  message: |
                    Injects CPU consumption on pods belonging to an app deployment
                kind: ChaosExperiment

                metadata:
                  name: pod-cpu-hog
                  labels:
                    name: pod-cpu-hog
                    app.kubernetes.io/part-of: litmus
                    app.kubernetes.io/component: chaosexperiment
                    app.kubernetes.io/version: 3.16.0
                spec:
                  definition:
                    scope: Namespaced
                    permissions:
                      - apiGroups:
                          - ""
                        resources:
                          - pods
                        verbs:
                          - create
                          - delete
                          - get
                          - list
                          - patch
                          - update
                          - deletecollection
                      - apiGroups:
                          - ""
                        resources:
                          - events
                        verbs:
                          - create
                          - get
                          - list
                          - patch
                          - update
                      - apiGroups:
                          - ""
                        resources:
                          - configmaps
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - ""
                        resources:
                          - pods/log
                        verbs:
                          - get
                          - list
                          - watch
                      - apiGroups:
                          - ""
                        resources:
                          - pods/exec
                        verbs:
                          - get
                          - list
                          - create
                      - apiGroups:
                          - apps
                        resources:
                          - deployments
                          - statefulsets
                          - replicasets
                          - daemonsets
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - apps.openshift.io
                        resources:
                          - deploymentconfigs
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - ""
                        resources:
                          - replicationcontrollers
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - argoproj.io
                        resources:
                          - rollouts
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - batch
                        resources:
                          - jobs
                        verbs:
                          - create
                          - list
                          - get
                          - delete
                          - deletecollection
                      - apiGroups:
                          - litmuschaos.io
                        resources:
                          - chaosengines
                          - chaosexperiments
                          - chaosresults
                        verbs:
                          - create
                          - list
                          - get
                          - patch
                          - update
                          - delete
                    image: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                    imagePullPolicy: Always
                    args:
                      - -c
                      - ./experiments -name pod-cpu-hog
                    command:
                      - /bin/bash
                    env:
                      - name: TOTAL_CHAOS_DURATION
                        value: "60"
                      - name: CPU_CORES
                        value: "1"
                      - name: CPU_LOAD
                        value: "100"
                      - name: PODS_AFFECTED_PERC
                        value: ""
                      - name: RAMP_TIME
                        value: ""
                      - name: LIB_IMAGE
                        value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                      - name: STRESS_IMAGE
                        value: alexeiled/stress-ng:latest-ubuntu
                      - name: CONTAINER_RUNTIME
                        value: containerd
                      - name: SOCKET_PATH
                        value: /run/containerd/containerd.sock
                      - name: TARGET_CONTAINER
                        value: ""
                      - name: TARGET_PODS
                        value: ""
                      - name: DEFAULT_HEALTH_CHECK
                        value: "false"
                      - name: NODE_LABEL
                        value: ""
                      - name: SEQUENCE
                        value: parallel
                    labels:
                      name: pod-cpu-hog
                      app.kubernetes.io/part-of: litmus
                      app.kubernetes.io/component: experiment-job
                      app.kubernetes.io/runtime-api-usage: "true"
                      app.kubernetes.io/version: 3.16.0
          - name: pod-memory-hog-a7u
            path: /tmp/pod-memory-hog-a7u.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                description:
                  message: |
                    Injects memory consumption on pods belonging to an app deployment
                kind: ChaosExperiment

                metadata:
                  name: pod-memory-hog
                  labels:
                    name: pod-memory-hog
                    app.kubernetes.io/part-of: litmus
                    app.kubernetes.io/component: chaosexperiment
                    app.kubernetes.io/version: 3.16.0
                spec:
                  definition:
                    scope: Namespaced
                    permissions:
                      - apiGroups:
                          - ""
                        resources:
                          - pods
                        verbs:
                          - create
                          - delete
                          - get
                          - list
                          - patch
                          - update
                          - deletecollection
                      - apiGroups:
                          - ""
                        resources:
                          - events
                        verbs:
                          - create
                          - get
                          - list
                          - patch
                          - update
                      - apiGroups:
                          - ""
                        resources:
                          - configmaps
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - ""
                        resources:
                          - pods/log
                        verbs:
                          - get
                          - list
                          - watch
                      - apiGroups:
                          - ""
                        resources:
                          - pods/exec
                        verbs:
                          - get
                          - list
                          - create
                      - apiGroups:
                          - apps
                        resources:
                          - deployments
                          - statefulsets
                          - replicasets
                          - daemonsets
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - apps.openshift.io
                        resources:
                          - deploymentconfigs
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - ""
                        resources:
                          - replicationcontrollers
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - argoproj.io
                        resources:
                          - rollouts
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - batch
                        resources:
                          - jobs
                        verbs:
                          - create
                          - list
                          - get
                          - delete
                          - deletecollection
                      - apiGroups:
                          - litmuschaos.io
                        resources:
                          - chaosengines
                          - chaosexperiments
                          - chaosresults
                        verbs:
                          - create
                          - list
                          - get
                          - patch
                          - update
                          - delete
                    image: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                    imagePullPolicy: Always
                    args:
                      - -c
                      - ./experiments -name pod-memory-hog
                    command:
                      - /bin/bash
                    env:
                      - name: TOTAL_CHAOS_DURATION
                        value: "60"
                      - name: MEMORY_CONSUMPTION
                        value: "500"
                      - name: NUMBER_OF_WORKERS
                        value: "1"
                      - name: PODS_AFFECTED_PERC
                        value: ""
                      - name: RAMP_TIME
                        value: ""
                      - name: LIB_IMAGE
                        value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                      - name: STRESS_IMAGE
                        value: alexeiled/stress-ng:latest-ubuntu
                      - name: CONTAINER_RUNTIME
                        value: containerd
                      - name: SOCKET_PATH
                        value: /run/containerd/containerd.sock
                      - name: SEQUENCE
                        value: parallel
                      - name: DEFAULT_HEALTH_CHECK
                        value: "false"
                      - name: TARGET_CONTAINER
                        value: ""
                      - name: TARGET_PODS
                        value: ""
                      - name: NODE_LABEL
                        value: ""
                    labels:
                      name: pod-memory-hog
                      app.kubernetes.io/part-of: litmus
                      app.kubernetes.io/component: experiment-job
                      app.kubernetes.io/runtime-api-usage: "true"
                      app.kubernetes.io/version: 3.16.0
          - name: container-kill-6b3
            path: /tmp/container-kill-6b3.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                description:
                  message: |
                    Kills a container belonging to an application pod 
                kind: ChaosExperiment

                metadata:
                  name: container-kill
                  labels:
                    name: container-kill
                    app.kubernetes.io/part-of: litmus
                    app.kubernetes.io/component: chaosexperiment
                    app.kubernetes.io/version: 3.16.0
                spec:
                  definition:
                    scope: Namespaced
                    permissions:
                      - apiGroups:
                          - ""
                        resources:
                          - pods
                        verbs:
                          - create
                          - delete
                          - get
                          - list
                          - patch
                          - update
                          - deletecollection
                      - apiGroups:
                          - ""
                        resources:
                          - events
                        verbs:
                          - create
                          - get
                          - list
                          - patch
                          - update
                      - apiGroups:
                          - ""
                        resources:
                          - configmaps
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - ""
                        resources:
                          - pods/log
                        verbs:
                          - get
                          - list
                          - watch
                      - apiGroups:
                          - ""
                        resources:
                          - pods/exec
                        verbs:
                          - get
                          - list
                          - create
                      - apiGroups:
                          - apps
                        resources:
                          - deployments
                          - statefulsets
                          - replicasets
                          - daemonsets
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - apps.openshift.io
                        resources:
                          - deploymentconfigs
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - ""
                        resources:
                          - replicationcontrollers
                        verbs:
                          - get
                          - list
                      - apiGroups:
                          - argoproj.io
                        resources:
                          - rollouts
                        verbs:
                          - list
                          - get
                      - apiGroups:
                          - batch
                        resources:
                          - jobs
                        verbs:
                          - create
                          - list
                          - get
                          - delete
                          - deletecollection
                      - apiGroups:
                          - litmuschaos.io
                        resources:
                          - chaosengines
                          - chaosexperiments
                          - chaosresults
                        verbs:
                          - create
                          - list
                          - get
                          - patch
                          - update
                          - delete
                    image: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                    imagePullPolicy: Always
                    args:
                      - -c
                      - ./experiments -name container-kill
                    command:
                      - /bin/bash
                    env:
                      - name: TARGET_CONTAINER
                        value: ""
                      - name: RAMP_TIME
                        value: ""
                      - name: TARGET_PODS
                        value: ""
                      - name: CHAOS_INTERVAL
                        value: "10"
                      - name: SIGNAL
                        value: SIGKILL
                      - name: SOCKET_PATH
                        value: /run/containerd/containerd.sock
                      - name: CONTAINER_RUNTIME
                        value: containerd
                      - name: TOTAL_CHAOS_DURATION
                        value: "20"
                      - name: PODS_AFFECTED_PERC
                        value: ""
                      - name: NODE_LABEL
                        value: ""
                      - name: DEFAULT_HEALTH_CHECK
                        value: "false"
                      - name: LIB_IMAGE
                        value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                      - name: SEQUENCE
                        value: parallel
                    labels:
                      name: container-kill
                      app.kubernetes.io/part-of: litmus
                      app.kubernetes.io/component: experiment-job
                      app.kubernetes.io/runtime-api-usage: "true"
                      app.kubernetes.io/version: 3.16.0
      outputs: {}
      metadata: {}
      container:
        name: ""
        image: litmuschaos/k8s:2.11.0
        command:
          - sh
          - -c
        args:
          - kubectl apply -f /tmp/ -n {{workflow.parameters.adminModeNamespace}}
            && sleep 30
        resources: {}
    - name: cleanup-chaos-resources
      inputs: {}
      outputs: {}
      metadata: {}
      container:
        name: ""
        image: litmuschaos/k8s:2.11.0
        command:
          - sh
          - -c
        args:
          - kubectl delete chaosengine -l workflow_run_id={{workflow.uid}} -n
            {{workflow.parameters.adminModeNamespace}}
        resources: {}
    - name: pod-network-loss-jcn
      inputs:
        artifacts:
          - name: pod-network-loss-jcn
            path: /tmp/chaosengine-pod-network-loss-jcn.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                kind: ChaosEngine

                metadata:
                  namespace: "{{workflow.parameters.adminModeNamespace}}"
                  labels:
                    workflow_run_id: "{{ workflow.uid }}"
                    workflow_name: test
                  annotations:
                    probeRef: '[{"name":"test-nginx","mode":"Continuous"}]'
                  generateName: pod-network-loss-jcn
                spec:
                  engineState: active
                  appinfo:
                    appns: test-app
                    applabel: app=nginx
                    appkind: deployment
                  chaosServiceAccount: litmus-admin
                  experiments:
                    - name: pod-network-loss
                      spec:
                        components:
                          env:
                            - name: TARGET_CONTAINER
                              value: nginx
                            - name: LIB_IMAGE
                              value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                            - name: NETWORK_INTERFACE
                              value: eth0
                            - name: TC_IMAGE
                              value: gaiadocker/iproute2
                            - name: NETWORK_PACKET_LOSS_PERCENTAGE
                              value: "100"
                            - name: TOTAL_CHAOS_DURATION
                              value: "60"
                            - name: RAMP_TIME
                              value: ""
                            - name: PODS_AFFECTED_PERC
                              value: ""
                            - name: DEFAULT_HEALTH_CHECK
                              value: "false"
                            - name: TARGET_PODS
                              value: ""
                            - name: NODE_LABEL
                              value: ""
                            - name: CONTAINER_RUNTIME
                              value: containerd
                            - name: DESTINATION_IPS
                              value: ""
                            - name: DESTINATION_HOSTS
                              value: ""
                            - name: SOCKET_PATH
                              value: /run/containerd/containerd.sock
                            - name: SEQUENCE
                              value: parallel
      outputs: {}
      metadata:
        labels:
          weight: "10"
      container:
        name: ""
        image: docker.io/litmuschaos/litmus-checker:2.11.0
        args:
          - -file=/tmp/chaosengine-pod-network-loss-jcn.yaml
          - -saveName=/tmp/engine-name
        resources: {}
    - name: pod-cpu-hog-ixb
      inputs:
        artifacts:
          - name: pod-cpu-hog-ixb
            path: /tmp/chaosengine-pod-cpu-hog-ixb.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                kind: ChaosEngine

                metadata:
                  namespace: "{{workflow.parameters.adminModeNamespace}}"
                  labels:
                    workflow_run_id: "{{ workflow.uid }}"
                    workflow_name: test
                  annotations:
                    probeRef: '[{"name":"test-nginx","mode":"Continuous"}]'
                  generateName: pod-cpu-hog-ixb
                spec:
                  engineState: active
                  appinfo:
                    appns: test-app
                    applabel: app=nginx
                    appkind: deployment
                  chaosServiceAccount: litmus-admin
                  experiments:
                    - name: pod-cpu-hog
                      spec:
                        components:
                          env:
                            - name: TOTAL_CHAOS_DURATION
                              value: "60"
                            - name: CPU_CORES
                              value: "1"
                            - name: CPU_LOAD
                              value: "100"
                            - name: PODS_AFFECTED_PERC
                              value: ""
                            - name: RAMP_TIME
                              value: ""
                            - name: LIB_IMAGE
                              value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                            - name: STRESS_IMAGE
                              value: alexeiled/stress-ng:latest-ubuntu
                            - name: CONTAINER_RUNTIME
                              value: containerd
                            - name: SOCKET_PATH
                              value: /run/containerd/containerd.sock
                            - name: TARGET_CONTAINER
                              value: ""
                            - name: TARGET_PODS
                              value: ""
                            - name: DEFAULT_HEALTH_CHECK
                              value: "false"
                            - name: NODE_LABEL
                              value: ""
                            - name: SEQUENCE
                              value: parallel
      outputs: {}
      metadata:
        labels:
          weight: "10"
      container:
        name: ""
        image: docker.io/litmuschaos/litmus-checker:2.11.0
        args:
          - -file=/tmp/chaosengine-pod-cpu-hog-ixb.yaml
          - -saveName=/tmp/engine-name
        resources: {}
    - name: pod-memory-hog-a7u
      inputs:
        artifacts:
          - name: pod-memory-hog-a7u
            path: /tmp/chaosengine-pod-memory-hog-a7u.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                kind: ChaosEngine

                metadata:
                  namespace: "{{workflow.parameters.adminModeNamespace}}"
                  labels:
                    workflow_run_id: "{{ workflow.uid }}"
                    workflow_name: test
                  annotations:
                    probeRef: '[{"name":"test-nginx","mode":"Continuous"}]'
                  generateName: pod-memory-hog-a7u
                spec:
                  engineState: active
                  appinfo:
                    appns: test-app
                    applabel: app=nginx
                    appkind: deployment
                  chaosServiceAccount: litmus-admin
                  experiments:
                    - name: pod-memory-hog
                      spec:
                        components:
                          env:
                            - name: TOTAL_CHAOS_DURATION
                              value: "60"
                            - name: MEMORY_CONSUMPTION
                              value: "500"
                            - name: NUMBER_OF_WORKERS
                              value: "1"
                            - name: PODS_AFFECTED_PERC
                              value: ""
                            - name: RAMP_TIME
                              value: ""
                            - name: LIB_IMAGE
                              value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                            - name: STRESS_IMAGE
                              value: alexeiled/stress-ng:latest-ubuntu
                            - name: CONTAINER_RUNTIME
                              value: containerd
                            - name: SOCKET_PATH
                              value: /run/containerd/containerd.sock
                            - name: SEQUENCE
                              value: parallel
                            - name: DEFAULT_HEALTH_CHECK
                              value: "false"
                            - name: TARGET_CONTAINER
                              value: ""
                            - name: TARGET_PODS
                              value: ""
                            - name: NODE_LABEL
                              value: ""
      outputs: {}
      metadata:
        labels:
          weight: "10"
      container:
        name: ""
        image: docker.io/litmuschaos/litmus-checker:2.11.0
        args:
          - -file=/tmp/chaosengine-pod-memory-hog-a7u.yaml
          - -saveName=/tmp/engine-name
        resources: {}
    - name: container-kill-6b3
      inputs:
        artifacts:
          - name: container-kill-6b3
            path: /tmp/chaosengine-container-kill-6b3.yaml
            raw:
              data: >
                apiVersion: litmuschaos.io/v1alpha1

                kind: ChaosEngine

                metadata:
                  namespace: "{{workflow.parameters.adminModeNamespace}}"
                  labels:
                    workflow_run_id: "{{ workflow.uid }}"
                    workflow_name: test
                  annotations:
                    probeRef: '[{"name":"test-nginx","mode":"Continuous"}]'
                  generateName: container-kill-6b3
                spec:
                  engineState: active
                  appinfo:
                    appns: test-app
                    applabel: app=nginx
                    appkind: deployment
                  chaosServiceAccount: litmus-admin
                  experiments:
                    - name: container-kill
                      spec:
                        components:
                          env:
                            - name: TARGET_CONTAINER
                              value: nginx
                            - name: RAMP_TIME
                              value: ""
                            - name: TARGET_PODS
                              value: ""
                            - name: CHAOS_INTERVAL
                              value: "10"
                            - name: SIGNAL
                              value: SIGKILL
                            - name: SOCKET_PATH
                              value: /run/containerd/containerd.sock
                            - name: CONTAINER_RUNTIME
                              value: containerd
                            - name: TOTAL_CHAOS_DURATION
                              value: "20"
                            - name: PODS_AFFECTED_PERC
                              value: ""
                            - name: NODE_LABEL
                              value: ""
                            - name: DEFAULT_HEALTH_CHECK
                              value: "false"
                            - name: LIB_IMAGE
                              value: litmuschaos.docker.scarf.sh/litmuschaos/go-runner:3.16.0
                            - name: SEQUENCE
                              value: parallel
      outputs: {}
      metadata:
        labels:
          weight: "10"
      container:
        name: ""
        image: docker.io/litmuschaos/litmus-checker:2.11.0
        args:
          - -file=/tmp/chaosengine-container-kill-6b3.yaml
          - -saveName=/tmp/engine-name
        resources: {}
  entrypoint: test
  arguments:
    parameters:
      - name: adminModeNamespace
        value: litmus
  serviceAccountName: argo-chaos
  podGC:
    strategy: OnWorkflowCompletion
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
status:
  startedAt: null
  finishedAt: null
```

### 3. Integrating with CI/CD Pipelines

You can integrate Litmus with GitLab CI, GitHub Actions, Jenkins, etc., using `kubectl apply` steps.

#### Example: GitLab CI

```yaml
chaos_test:
  script:
    - kubectl apply -f ./chaos/experiments/nginx-pod-delete.yaml
    - kubectl wait --for=condition=Completed chaosengine/nginx-pod-delete -n litmus --timeout=180s
```

This helps validate your application's resilience **before** it reaches production.

---


| [← Previous page : Install environment](./02_install_environment.md) | [Back to README](../README.md) | [Next page : POC Result →](./04_poc_result.md) |
| -------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------- |
