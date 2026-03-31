# interLink Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badges/repository/interlink)](https://artifacthub.io/packages/search?repo=interlink)

The interLink Helm chart deploys virtual nodes that connect Kubernetes clusters to remote compute resources (HPC, cloud, edge).

## Installation

```bash
helm repo add interlink-hq oci://ghcr.io/interlink-hq/interlink-helm-chart
helm install virtual-node interlink-hq/interlink --version 0.6.1-pre1
```

## Configuration

### Deployment Modes

- **Socket mode** (default):
  ```yaml
  interlink:
    socket: {}
  ```

- **REST mode**:
  ```yaml
  interlink:
    oauth:
      clientId: YOUR_CLIENT_ID
      clientSecret: YOUR_SECRET
  ```

Full configuration options available in [values.yaml](values.yaml).

## Documentation

- [Project homepage](https://intertwin-eu.github.io/interLink/)
- [GitHub repository](https://github.com/interTwin-eu/interlink-helm-chart)

> This chart is maintained by the interLink community.