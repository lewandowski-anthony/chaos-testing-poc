# Chaos Engineering POC Repository

Welcome to this Proof of Concept (POC) repository dedicated to **Chaos Engineering** in Kubernetes environments.  
This repo aims to provide a practical, hands-on setup using lightweight Kubernetes (k3s), along with two popular open-source chaos engineering tools: **Chaos Mesh** and **Litmus**.

---

## 🎯 Purpose of this Repository

Chaos Engineering is a discipline focused on improving system resilience by intentionally injecting faults and failures.  
The goal here is to demonstrate how to deploy, configure, and run chaos experiments in a lightweight Kubernetes cluster, enabling developers and operators to better understand failure modes and improve system robustness.

This POC covers:

- Installing a Kubernetes cluster using **k3s** (a lightweight Kubernetes distribution ideal for local and edge environments)  
- Deploying **Chaos Mesh** and **Litmus** chaos engineering platforms, each with complementary strengths  
- Creating example test applications (like NGINX) to run chaos experiments against  
- Providing scripts and documentation for easy setup, testing, and teardown

---

## 📚 Documentation Overview

All detailed guides and explanations are organized inside the `/docs` directory. Below is a summary of the main documentation files with brief descriptions:

| Document                                                      | Description                                                                                   |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| [01_goal_of_the_poc.md](./docs/01_goal_of_the_poc.md)         | Introduction to Chaos Engineering, project goals, and overview of the tools used              |
| [02_install_environment.md](./docs/02_install_environment.md) | Step-by-step instructions to install k3s, Helm, Chaos Mesh, Litmus, and auxiliary tools       |
| [03_chaos_testing.md](./docs/03_chaos_testing.md)             | How to write and run chaos experiments using Chaos Mesh and Litmus, plus interpreting results |
| [04_poc_result.md](./docs/04_poc_result.md)                   | Result of the POC and define tool preferences                                                 |

---

## 🚀 Getting Started

To get started quickly, run the provided installation script which will:

- Set up k3s Kubernetes cluster with containerd runtime  
- Install Helm package manager  
- Create necessary Kubernetes namespaces  
- Deploy Chaos Mesh and Litmus for chaos experiments  
- Deploy example applications for testing  

Run this command with root privileges (e.g. using `sudo`):

```bash
sudo ./install.sh
