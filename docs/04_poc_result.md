# Chaos Engineering PoC: Chaos Mesh vs Litmus

## 1. Context

Based on our PoC, we were able to evaluate the strengths and weaknesses of both Chaos Mesh and LitmusChaos solutions.

---

## 2. Results Comparison

| Aspect                    | Chaos Mesh                                            | LitmusChaos                                                           |
| ------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------- |
| Installation Ease         | Easy with Helm                                        | More complex with Helm, but straightforward using kubectl             |
| UI Integration            | Built-in dashboard with basic visual feedback         | Litmus Portal + Argo Workflows provide a powerful and feature-rich UI |
| Experiment Definition     | Simple CRDs with rich configuration options           | Modular architecture with ChaosExperiments, ChaosEngines, and Probes  |
| Scheduling                | Supports cron-like schedules via workflow integration | Supports CronWorkflows through Argo for advanced orchestration        |
| Metrics & Monitoring      | Native integration with Prometheus and Grafana        | Integrates with Litmus Portal and Prometheus                          |
| Community & Documentation | Large, active community and mature documentation      | Growing community with solid documentation                            |

---

## 3. Pros and Cons

| Feature | Chaos Mesh                                                      | LitmusChaos                                                       |
| ------- | --------------------------------------------------------------- | ----------------------------------------------------------------- |
| Pros    | Easy setup and intuitive dashboard UI                           | Kubernetes-native design with strong Argo-based orchestration     |
|         | Wide variety of experiment types                                | Good CI/CD integration capabilities                               |
|         | Clear logs with straightforward debugging                       | Native probes to check experiment health                          |
|         | No mandatory GUI interaction needed for basic tests             | Support for detailed test failure analysis, including Spring apps |
| Cons    | Dashboard UI can be limited for complex workflows               | More complex initial setup and learning curve                     |
|         | Scheduling capabilities are limited without external tools      | Heavy reliance on Argo Workflows for orchestration                |
|         | Some bugs reported in the UI                                    | Writing tests without GUI can be challenging                      |
|         | Lacks native probes; health checks need to be scripted manually | Logs and errors can sometimes be unclear                          |

## 4. SWOT Analysis: Chaos Mesh vs LitmusChaos

### Chaos Mesh

| Category          | Details                                                                                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Strengths**     | - Easy and fast Helm installation<br>- Lightweight and declarative YAMLs for GitOps<br>- Intuitive dashboard<br>- Clear logs for debugging<br>- Easy CI/CD integration via `kubectl` |
| **Weaknesses**    | - Limited UI for advanced workflows<br>- No native health probes<br>- Some GUI bugs<br>- Basic scheduling capabilities without extensions                                            |
| **Opportunities** | - Ideal for quick onboarding and small teams<br>- Fits well in GitOps (e.g., Kustomize)<br>- Custom automation and scripting flexibility                                             |
| **Threats**       | - Lacks deep orchestration tools out of the box<br>- May be outgrown by complex needs<br>- Slower innovation on advanced features                                                    |

---

### LitmusChaos

| Category          | Details                                                                                                                                                                                                     |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Strengths**     | - Kubernetes-native architecture with modular components<br>- Powerful GUI with Litmus Portal<br>- Rich orchestration via Argo Workflows<br>- Built-in probes for health checks<br>- Prometheus integration |
| **Weaknesses**    | - Complex setup and steep learning curve<br>- Strong dependency on GUI<br>- Difficult to write tests manually<br>- Verbose and less GitOps-friendly YAMLs                                                   |
| **Opportunities** | - Ideal for advanced, production-grade scenarios<br>- Integrates deeply into CI/CD pipelines<br>- Supports complex workflows and chained experiments                                                        |
| **Threats**       | - High maintenance overhead<br>- May overcomplicate simple use cases<br>- GUI reliance could hinder automation-first teams                                                                                  |

---

## 5. Conclusion

Chaos Mesh and LitmusChaos are both robust and mature tools for implementing chaos engineering in Kubernetes environments. However, they adopt fundamentally different philosophies that cater to distinct use cases and user expectations:

- **Chaos Mesh** stands out for its simplicity and ease of adoption. Its streamlined installation process and intuitive built-in dashboard make it particularly well-suited for teams looking to get started with chaos engineering quickly, without needing to invest in a complex orchestration setup. Chaos experiments are easy to define and manage using lightweight manifests, and the tool integrates seamlessly into CI pipelines (GitHub Actions, GitLab CI, Jenkins) as long as `kubectl` access is available. However, the GUI, while functional, can be unstable or limited in features, and the lack of built-in health probes means users must implement custom logic to verify application behavior during tests.

- **LitmusChaos**, on the other hand, provides a more comprehensive and Kubernetes-native approach. Its modular architecture, built around ChaosExperiments, ChaosEngines, and Probes, offers extensive flexibility and control over fault injection and observability. The integration with Argo Workflows enables powerful orchestration of complex test scenarios and chaining of experiments. The Litmus Portal delivers a rich UI experience with visualizations, experiment builders, and detailed results. However, the tool requires a steeper learning curve and a more involved setup. Additionally, writing tests without the GUI can be challenging, as the YAML structure is verbose and less intuitive than Chaos Mesh’s.

### Choosing the Right Tool

- If your team values **simplicity**, **fast onboarding**, **declarative chaos scenarios**, and **version-controllable YAMLs** (e.g., managed via Kustomize or GitOps flows), **Chaos Mesh** is likely the better fit.
- If you require **fine-grained control**, **native support for probes**, **rich UI tooling**, and **advanced orchestration**, and you're comfortable managing a more complex stack, then **LitmusChaos** may be the more appropriate choice.

Ultimately, the decision depends on your organization’s level of Kubernetes maturity, the depth of testing required, and how chaos engineering fits into your existing development and delivery workflows.

---

## 6. References

- [Chaos Mesh Documentation](https://chaos-mesh.org/docs/)
- [LitmusChaos Documentation](https://litmuschaos.github.io/litmus/)

| [← Previous page : Install environment](./03_chaos_testing.md) | [Back to README](../README.md) |
| -------------------------------------------------------------- | ------------------------------ |
