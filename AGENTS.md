# AGENTS.md
Guidelines for agents working on the interLink Helm chart repository.

## Build/Lint/Test Commands

### Linting
- **Helm Lint**: Validate chart structure and dependencies.
  ```bash
  helm lint interlink/
  ```

### Building
- **Package Chart**: Create a chart archive for distribution.
  ```bash
  helm package interlink/
  ```

### Testing
*Note: Helm charts are validated through templating and installation. The project uses example configurations for testing different deployment modes.*

- **Template Validation**: Verify generated manifests.
  ```bash
  helm template virtual-node ./interlink --values values.yaml
  ```

- **Run Specific Test Configuration**:
  ```bash
  helm template virtual-node ./interlink --values examples/edge_with_rest.yaml
  ```

- **Local Installation Test**:
  ```bash
  helm install --create-namespace -n interlink virtual-node ./interlink --values examples/edge_with_socket.yaml
  ```

- **Upgrade Test**:
  ```bash
  helm upgrade virtual-node ./interlink --values examples/edge_with_rest.yaml
  ```

### Chart Signing
- **Keyless Verification**: Validate OCI signatures
  ```bash
  cosign verify --insecure-ignore-tlog --insecure-ignore-sct oci://ghcr.io/interlink-hq/interlink-helm-chart/interlink
  ```
- Automated during `chartpress --push` (triggered by version tags)

## Code Style Guidelines

### Template Conventions
- **Indentation**: 2 spaces (no tabs) for YAML/templates
- **Whitespace Control**: Use `{{- ... -}}` for proper indentation
  ```yaml
  {{- if .Values.virtualNode.enabled }}
  apiVersion: apps/v1
  {{- end }}
  ```

- **Conditional Blocks**: Wrap components using `.Values`:
  ```yaml
  {{- if .Values.component.enabled }}
  # resource definition
  {{- end }}
  ```

### Values Structure
- **Hierarchy**: Organize by deployment modes:
  ```yaml
  virtualNode:
    enabled: true
    resources: {...}
  interlink:
    socket: {...}  # socket mode
    oauth: {...}   # REST mode
  ```

### Configuration Files
- **InterLinkConfig.yaml**: Consistent structure across components

### Error Handling
- **Required Values**:
  ```yaml
  {{ required "virtualNode.name is required" .Values.virtualNode.name }}
  ```

### Deployment Modes
- **Socket vs REST**: Determined by `.socket` presence:
  ```yaml
  {{ if .Values.interlink.socket }}
  # socket configuration
  {{ else }}
  # REST configuration
  {{ end }}
  ```

### RBAC Management
- **Per-Node Accounts**:
  ```yaml
  serviceAccount:
    name: {{ .Release.Name }}-virtual-node
  ```

## Development Workflow
1. Test all deployment modes using example configurations
2. Always run `helm lint` and template validation before commits
3. Maintain version consistency using chartpress
4. Verify changes with `helm template` before installation

## Prohibited Patterns
- Avoid hardcoded namespaces (use `.Release.Namespace`)
- Never commit values with secrets
- Skip unnecessary resource requests/limits in examples