# 🚀 Chaos Engineering Environment Setup with K3s, Chaos Mesh, and Litmus

## 📜 Table of Contents
- [🚀 Chaos Engineering Environment Setup with K3s, Chaos Mesh, and Litmus](#-chaos-engineering-environment-setup-with-k3s-chaos-mesh-and-litmus)
  - [📜 Table of Contents](#-table-of-contents)
  - [📸 Before starting](#-before-starting)
    - [Available Tools](#available-tools)
  - [Why did we test only Chaos Mesh and Litmus?](#why-did-we-test-only-chaos-mesh-and-litmus)
  - [System Information Used for the POC](#system-information-used-for-the-poc)

---

## 📸 Before starting

Chaos Engineering is an emerging discipline aiming to improve system resilience by intentionally injecting faults and failures into production or staging environments. This POC explores two popular open-source Kubernetes-native chaos engineering tools—Chaos Mesh and LitmusChaos—deployed on a lightweight Kubernetes distribution, K3s.

To better understand the ecosystem and available options, here is a detailed overview of various tools currently available for chaos testing, their licensing, pricing, and core strengths.

### Available Tools

| Tool Name                     | Open Source | Pricing Model               | Key Features                                                                 | Notes                                      |
| ----------------------------- | ----------- | --------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------ |
| **Chaos Mesh**                | Yes         | Free (Open Source)          | Designed natively for Kubernetes, offers a rich set of fault injections (network, pod, time, IO, etc.), integrates tightly with container runtimes such as containerd. Easy to install and use, with an active community backing it. | Ideal for cloud-native environments, lightweight, and supports granular chaos experiments. |
| **LitmusChaos**               | Yes         | Free (Open Source)          | Kubernetes-native chaos engineering framework with seamless integration in CI/CD pipelines, GitOps workflows, and multi-cloud support. Rich dashboard and experiment repository. | Focus on automation and developer-friendly workflows, good for GitOps-driven chaos. |
| **Gremlin**                   | No          | Starts at ~$99/month        | Commercial SaaS product offering enterprise-grade chaos testing across multi-cloud and hybrid environments. Provides a polished UI, detailed reporting, and comprehensive support options. | Best suited for enterprises needing support and multi-environment testing but at a cost. |
| **Chaos Monkey**              | Yes         | Free (Open Source)          | Originally developed by Netflix, simulates random instance and VM failures, mainly focused on AWS environments. | Simple tool but limited to specific cloud providers and types of failures. |
| **PowerfulSeal**              | Yes         | Free (Open Source)          | Kubernetes-focused chaos testing with policy-driven controls and scheduling. It allows dynamic discovery of pods and nodes to target chaos. | Great for Kubernetes but less user-friendly compared to Chaos Mesh or LitmusChaos. |
| **AWS Fault Injection Simulator** | No    | Pay-as-you-go (AWS pricing) | Fully managed fault injection service integrated into AWS ecosystem, enabling safe and controlled experiments for AWS services. | Highly scalable and managed but potentially expensive and AWS-specific. |

---

## Why did we test only Chaos Mesh and Litmus?

When embarking on this POC, we carefully considered a range of chaos engineering tools based on several key factors:

- **Open Source & Kubernetes Native:** Both Chaos Mesh and LitmusChaos are open source projects explicitly designed for Kubernetes. This is essential as our environment is based on **K3s**, a lightweight Kubernetes distribution, ensuring seamless integration and minimal overhead.

- **Strong Community & Continuous Development:** Both projects boast active communities and frequent releases. This translates into timely bug fixes, feature enhancements, and a wealth of community-driven documentation and support. This aspect is critical during POC stages to reduce troubleshooting times.

- **Rich Feature Sets with Simplicity:** They offer comprehensive chaos experiments — including network delays, pod failures, resource hogs, time skew, and more — but remain straightforward to install and operate, especially important in a proof-of-concept phase where setup complexity should be minimized.

- **Cost Effectiveness:** As open-source tools, they impose no licensing costs. This is ideal for experimental and educational projects where budget constraints are typical.

- **Strong Integration Capabilities:** LitmusChaos excels in automation-friendly workflows, fitting naturally into CI/CD pipelines and GitOps methodologies, while Chaos Mesh is well-optimized for containerd runtimes used by K3s, offering low-level chaos injection support.

While other tools such as Gremlin or AWS Fault Injection Simulator offer robust enterprise-grade features and managed services, they are either costly or cloud-provider-specific, making them less suitable for lightweight, self-hosted POCs or experimental setups.

---

## System Information Used for the POC

Below is a comprehensive list of the key software and environment versions used throughout this POC to ensure reproducibility and clarify the setup context:

| System               | Version            | Reason / Notes                                                                                   |
| -------------------- | ------------------ | ----------------------------------------------------------------------------------------------- |
| **Windows 11 Famille**| 24H2               | Chosen for ease of use on x86_64 architecture and compatibility with WSL                         |
| **WSL Ubuntu**        | 2                  | Provides an isolated Linux environment to run K3s and Kubernetes tools natively within Windows   |
| **K3s**               | v1.32.5+k3s1       | Lightweight Kubernetes distribution selected due to its minimal resource footprint and simplicity |
| **kubectl**           | v1.32.5+k3s1       | Kubernetes CLI tool matching K3s cluster version for management                                  |
| **helm**              | v3.18.3+g6838ebc   | Kubernetes package manager used for installing Helm charts such as Chaos Mesh                    |
| **Chaos Mesh**         | 2.7.2              | One of the two core chaos testing frameworks deployed for its Kubernetes-native chaos features   |
| **Litmus**             | 3.16.0             | The other primary chaos testing framework chosen for CI/CD and GitOps capabilities               |
| **MongoDB**            | 8.0.10             | Required backend database service for Litmus Portal                                              |

---

This environment setup and tool selection enable an effective and practical chaos engineering workflow on lightweight Kubernetes, allowing us to explore fault injection experiments that simulate real-world failures and observe system resilience.

<div style="display: flex; justify-content: space-between; align-items: center;">
  <a href="./README.md" style="margin: 0 10px;">Back to README</a>
  <a href="./02_install_environement.md">Next page : Install Environement →</a>
</div>