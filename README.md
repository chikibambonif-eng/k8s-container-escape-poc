# KuberKiller: Kubernetes Container Escape PoC

A simple laboratory environment designed to demonstrate Container Escape vulnerabilities (gaining host-level visibility) and remediation techniques using Kubernetes `SecurityContext`.

## Security Configurations (How Privileges are Restricted)

The result of the pentest fully depends on the `securityContext` parameters specified in `safe-pod.yaml`. Here is exactly what blocks the attack:

*   **`privileged: false`** — This is the core setting. It strips away all Linux Kernel Capabilities from the container, making it impossible to interface directly with host devices (like `/sys/kernel/debug`) or manipulate the underlying host architecture.
*   **`allowPrivilegeEscalation: false`** — Prevents any child processes inside the container from gaining more privileges than their parent process (e.g., blocks `setuid` binaries from elevating to host root).
*   **`runAsNonRoot: true`** & **`runAsUser: 1000`** — Forces the container process to run as a low-privileged UID instead of the default root user. Even if an attacker finds a vulnerability in the application, they remain a harmless user inside the isolated sandbox.

---

## Lab Components
- `attack.sh` - Bash script verifying actual access to host kernel debug flags.
- `Dockerfile` - Builds an isolated Alpine environment with required networking tools.
- `safe-pod.yaml` - Secure Pod manifest enforcing hard isolation boundaries.

---

## How to Run the Environment

### 1. Build and Load the Image
Navigate to the project folder and build the Docker container:
```bash
docker build -t kuber-killer:local .
```
Load the image directly into your local Kind cluster (so Kubernetes can see it without pushing to an external registry):
```bash
kind load docker-image kuber-killer:local --name pentest-cluster
```

### 2. Scenario A: Simulate the Vulnerable Cluster (Exploitation)
Run the Pod in **Privileged** mode using client-side overrides:
```bash
sudo kubectl run pentest-pod --image=kuber-killer:local --image-pull-policy=Never --restart=Never --overrides='{"spec":{"containers":[{"name":"pentest-pod","image":"kuber-killer:local","securityContext":{"privileged":true}}]}}'
```
Check the execution logs. The script will bypass isolation and print:
```text
[!] КРИТИЧЕСКАЯ УЯЗВИМОСТЬ: Контейнер РЕАЛЬНО имеет статус Privileged!
=======================================================
  [ВВЕДЕН В ЭКСПЛУАТАЦИЮ] КЛАСТЕР СКОМПРОМЕТИРОВАН!
=======================================================
```

### 3. Scenario B: Apply Remediation (Defended)
Delete the compromised Pod:
```bash
sudo kubectl delete pod pentest-pod --force --grace-period=0
```
Deploy the secure configuration using the manifest:
```bash
sudo kubectl apply -f safe-pod.yaml
```
Verify the updated defense logs:
```bash
sudo kubectl logs pentest-pod
```
The kernel will deny access to the host subsystems, confirming proper lockdown:
```text
[+] Проверка на Privileged: Успешно изолировано (Доступа к ядру хоста нет).
=======================================================
  [ЗАЩИЩЕНО] Атака не удалась. Контейнер изолирован.
=======================================================
