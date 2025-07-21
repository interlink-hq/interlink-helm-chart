# interLink Helm Chart

[![Chart Version](https://img.shields.io/badge/dynamic/yaml?color=blue&label=chart&query=version&url=https%3A//raw.githubusercontent.com/interTwin-eu/interlink-helm-chart/main/interlink/Chart.yaml)](https://github.com/interTwin-eu/interlink-helm-chart)
[![App Version](https://img.shields.io/badge/dynamic/yaml?color=green&label=app&query=appVersion&url=https%3A//raw.githubusercontent.com/interTwin-eu/interlink-helm-chart/main/interlink/Chart.yaml)](https://github.com/interTwin-eu/interlink-helm-chart)

The official Helm chart for deploying
[interLink](https://github.com/interTwin-eu/interLink) virtual nodes in
Kubernetes clusters. interLink enables hybrid cloud deployments by creating
virtual nodes that can execute workloads on remote computing resources while
appearing as regular nodes to the Kubernetes scheduler.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Deployment Modes](#deployment-modes)
- [Configuration](#configuration)
- [Examples](#examples)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.8+
- Appropriate RBAC permissions for virtual node operations
- For REST mode: OAuth2 provider configured
- For socket mode: SSH access to remote resources

## Installation

### From OCI Registry (Recommended)

```bash
# Add the repository
# Will be available once published:
# helm repo add interlink https://intertwin-eu.github.io/interlink-helm-chart/

# Update repositories
helm repo update

# Install with custom values
helm install --create-namespace -n interlink virtual-node \
  interlink/interlink --values my-values.yaml
```

### From OCI Registry (Alternative)

```bash
helm install --create-namespace -n interlink virtual-node \
  oci://ghcr.io/intertwin-eu/interlink-helm-chart/interlink \
  --values my-values.yaml
```

### Local Development

```bash
git clone https://github.com/interTwin-eu/interlink-helm-chart.git
cd interlink-helm-chart
helm install --create-namespace -n interlink virtual-node \
  ./interlink --values my-values.yaml
```

## Deployment Modes

### 1. Edge-node Service (REST Communication)

**Architecture**: Virtual kubelet + OAuth2 token refresher in cluster,
plugin + interLink API server + OAuth2 proxy on remote side.

**Use Case**: Secure communication over HTTPS with OAuth2 authentication.

```yaml
# values-rest.yaml
nodeName: interlink-rest-node

interlink:
  address: https://your-remote-endpoint.com
  port: 443

OAUTH:
  enabled: true
  TokenURL: "https://your-oauth-provider.com/token"
  ClientID: "your-client-id"
  ClientSecret: "your-client-secret"
  RefreshToken: "your-refresh-token"
  Audience: "your-audience"

virtualNode:
  resources:
    CPUs: 16
    memGiB: 64
    pods: 200
```

### 2. Edge-node with Socket (SSH Communication)

**Architecture**: interLink + virtual kubelet + SSH bastion in cluster,
only plugin on remote side.

**Use Case**: Secure communication via SSH tunnels using Unix sockets.

```yaml
# values-socket.yaml
nodeName: interlink-socket-node

interlink:
  enabled: true
  socket: unix:///var/run/interlink.sock

plugin:
  socket: unix:///var/run/plugin.sock

sshBastion:
  enabled: true
  clientKeys:
    authorizedKeys: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  port: 31022

virtualNode:
  resources:
    CPUs: 8
    memGiB: 32
    pods: 100
```

### 3. In-cluster Mode

**Architecture**: All components (virtual kubelet, interLink, plugin)
deployed in cluster with socket communication.

**Use Case**: Testing, development, or when remote resources support
direct API access.

```yaml
# values-incluster.yaml
nodeName: interlink-incluster-node

interlink:
  enabled: true
  socket: unix:///var/run/interlink.sock

plugin:
  enabled: true
  image: "ghcr.io/intertwin-eu/interlink/plugin-docker:latest"
  socket: unix:///var/run/plugin.sock
  config: |
    InterlinkURL: "unix:///var/run/interlink.sock"
    SidecarURL: "unix:///var/run/plugin.sock"
    VerboseLogging: true

virtualNode:
  resources:
    CPUs: 4
    memGiB: 16
    pods: 50
```

## Configuration

### Core Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeName` | Name of the virtual node | `virtual-node` |
| `virtualNode.image` | Virtual kubelet image | `ghcr.io/interlink-hq/interlink/virtual-kubelet-inttw:latest` |
| `virtualNode.resources.CPUs` | Node CPU capacity | `8` |
| `virtualNode.resources.memGiB` | Node memory capacity in GiB | `49` |
| `virtualNode.resources.pods` | Maximum pods per node | `100` |
| `interlink.enabled` | Deploy interLink API server | `false` |
| `plugin.enabled` | Deploy plugin component | `false` |

### Advanced Configuration

#### Accelerators Support

```yaml
virtualNode:
  resources:
    accelerators:
    - resourceType: nvidia.com/gpu
      model: a100
      available: 2
    - resourceType: xilinx.com/fpga
      model: u55c
      available: 1
```

#### Node Labels and Taints

```yaml
virtualNode:
  nodeLabels:
    - "node-type=virtual"
    - "accelerator=gpu"
  nodeTaints:
    - key: "virtual-node"
      value: "true"
      effect: "NoSchedule"
```

## Examples

Complete examples are available in the [`examples/`](./interlink/examples/) directory:

- [`edge_with_rest.yaml`](./interlink/examples/edge_with_rest.yaml) -
  REST communication setup
- [`edge_with_socket.yaml`](./interlink/examples/edge_with_socket.yaml) -
  Socket communication setup

## Post-Installation

### Verify Deployment

```bash
# Check virtual node status
kubectl get node <nodeName>

# Check pod status
kubectl get pods -n interlink

# View virtual node details
kubectl describe node <nodeName>

# Check logs
kubectl logs -n interlink deployment/<nodeName>-node -c vk
```

### Testing the Virtual Node

```yaml
# test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-workload
spec:
  nodeSelector:
    kubernetes.io/hostname: <nodeName>
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
```

```bash
kubectl apply -f test-pod.yaml
kubectl get pod test-workload -o wide
```

## Troubleshooting

### Common Issues

#### Virtual Node Not Ready

```bash
# Check node conditions
kubectl describe node <nodeName>

# Check virtual kubelet logs
kubectl logs -n interlink deployment/<nodeName>-node -c vk

# Verify interLink connectivity
kubectl logs -n interlink deployment/<nodeName>-node -c interlink
```

#### Pod Scheduling Issues

```bash
# Check node resources
kubectl describe node <nodeName>

# Verify taints and tolerations
kubectl get node <nodeName> -o yaml | grep -A5 taints

# Check scheduler logs
kubectl logs -n kube-system deployment/kube-scheduler
```

#### Authentication Problems (REST mode)

```bash
# Check OAuth token refresh
kubectl logs -n interlink deployment/<nodeName>-node -c refresh-token

# Verify token file
kubectl exec -n interlink deployment/<nodeName>-node -c vk -- cat /opt/interlink/token
```

#### SSH Connection Issues (Socket mode)

```bash
# Check SSH bastion logs
kubectl logs -n interlink deployment/<nodeName>-node -c ssh-bastion

# Test SSH connectivity
kubectl exec -n interlink deployment/<nodeName>-node -c ssh-bastion -- ssh -T interlink@remote-host
```

### Debug Mode

Enable verbose logging:

```yaml
virtualNode:
  debug: true
```

### Health Checks

The chart includes readiness and liveness probes. Check their status:

```bash
kubectl get pods -n interlink -o wide
kubectl describe pod <pod-name> -n interlink
```

## Development

### Chart Development

```bash
# Lint the chart
helm lint interlink/

# Template and preview
helm template virtual-node ./interlink --values examples/edge_with_socket.yaml

# Test installation
helm install --dry-run --debug virtual-node ./interlink --values my-values.yaml
```

### Chart Versioning

This chart uses [chartpress](https://github.com/jupyterhub/chartpress) for
automated versioning:

```bash
# Update version and publish
chartpress --push

# Reset to development
chartpress --reset
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

For detailed contribution guidelines, see
[CONTRIBUTING.md](./CONTRIBUTING.md).

## Resources

- [interLink Documentation](https://interlink-project.dev/docs/intro)
- [Official Cookbook](https://interlink-project.dev/docs/intro)
- [GitHub Repository](https://github.com/interTwin-eu/interlink-helm-chart)
- [Chart Repository](https://github.com/interTwin-eu/interlink-helm-chart)
  (GitHub Pages coming soon)

## License

This project is licensed under the Apache License 2.0 - see the
[LICENSE](LICENSE) file for details.
