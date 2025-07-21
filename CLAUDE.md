# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the interLink Helm chart repository for deploying virtual nodes in Kubernetes clusters. interLink enables hybrid cloud deployments by creating virtual nodes that can execute workloads on remote computing resources while appearing as regular nodes to the Kubernetes scheduler.

## Development Commands

### Chart Development
```bash
# Install the chart locally for testing
helm install --create-namespace -n interlink virtual-node ./interlink --values values.yaml

# Lint the Helm chart
helm lint interlink/

# Template the chart to verify output
helm template virtual-node ./interlink --values values.yaml

# Upgrade existing deployment
helm upgrade virtual-node ./interlink --values values.yaml
```

### Chart Publishing (using chartpress)
```bash
# Update chart version and publish
chartpress --push

# Reset chart to development state
chartpress --reset
```

## Architecture

The chart supports three main deployment modes:

1. **Edge-node service**: Virtual kubelet + interlink API server with OAuth2 proxy on remote side
2. **Edge-node with socket**: Virtual kubelet + SSH bastion with Unix socket communication
3. **In-cluster mode**: All components deployed in cluster with socket communication

### Core Components

- **Virtual Kubelet**: The main Kubernetes node agent that registers as a virtual node
- **interLink API Server**: Translates Kubernetes API calls to plugin-specific commands
- **Plugin**: Handles actual workload execution on remote resources (Slurm, Docker, etc.)
- **OAuth2 Token Refresher**: Manages authentication for REST-based communication
- **SSH Bastion**: Provides secure tunneling for socket-based communication

### Configuration Files

All components use the same `InterLinkConfig.yaml` structure but with different settings:
- Virtual kubelet config defines node resources, HTTP settings, and interlink endpoint
- interLink server config defines plugin endpoints and data export settings
- Plugin config is deployment-specific (varies by plugin type)

## Values File Structure

Key configuration sections in `values.yaml`:
- `virtualNode`: Node resources, image, HTTP/proxy settings, labels/taints
- `interlink`: API server settings, socket vs REST communication mode
- `plugin`: Plugin-specific configuration and communication settings
- `OAUTH`: Authentication settings for REST mode
- `sshBastion`: SSH tunnel configuration for socket mode

## Development Guidelines

### Template Patterns
- Use conditional blocks (`{{- if .Values.component.enabled }}`) to enable/disable components
- Socket vs REST communication is determined by presence of `.socket` values
- ConfigMaps are generated from template values and mounted into containers
- Service accounts and RBAC are managed per virtual node name

### Example Configurations
- `examples/edge_with_rest.yaml`: REST-based communication with OAuth2
- `examples/edge_with_socket.yaml`: Socket-based communication with SSH bastion

### Chart Versioning
- Chart version is managed by chartpress and set to "TO_BE_CHANGED" in development
- Base version for development releases is "0.0.1-0.dev"
- Chart will be published to GitHub Pages at
  `https://intertwin-eu.github.io/interlink-helm-chart/` (coming soon)
