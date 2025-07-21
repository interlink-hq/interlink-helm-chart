# WSTunnel Template Guide

This guide explains how to customize the wstunnel template for different
networking scenarios.

## Overview

The interLink Helm chart includes wstunnel support for creating network
tunnels. By default, it uses an Ingress-based template, but you can provide
custom templates for different deployment scenarios.

## Configuration

Enable wstunnel in your `values.yaml`:

```yaml
virtualNode:
  network:
    enableTunnel: true
    tunnelImage: "ghcr.io/erebe/wstunnel:latest"
    wildcardDNS: "example.com"
    wstunnelTemplatePath: "/etc/templates/wstunnel.yaml"
    customTemplate: ""  # Leave empty to use default template
```

## Template Variables

The template supports these variables that will be populated by the interLink software:

- `{{.Name}}` - Deployment/service name
- `{{.Namespace}}` - Kubernetes namespace
- `{{.RandomPassword}}` - Generated security token
- `{{.WildcardDNS}}` - DNS domain for ingress
- `{{.ExposedPorts}}` - Array of port configurations with fields:
  - `{{.Port}}` - Port number
  - `{{.Name}}` - Port name
  - `{{.Protocol}}` - Protocol (TCP/UDP)
  - `{{.TargetPort}}` - Target port number

## Default Template

The default template (Traefik-based) includes:

- Deployment with wstunnel container
- ClusterIP Service
- Ingress with Traefik configuration
- Middleware for WebSocket support

## Built-in Template Options

The chart includes two pre-built templates in the `interlink/` directory:

- `wstunnel-template_traefik.yaml` - Default Traefik ingress with middleware
- `wstunnel-template_nginx.yaml` - NGINX ingress with WebSocket support

To use a specific template, reference it in the ConfigMap template section.

## Custom Template Examples

### NGINX Ingress Template

For clusters using NGINX ingress controller:

```yaml
virtualNode:
  network:
    enableTunnel: true
    customTemplate: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
      spec:
        replicas: 1
        selector:
          matchLabels:
            app.kubernetes.io/component: {{.Name}}
        template:
          metadata:
            labels:
              app.kubernetes.io/component: {{.Name}}
          spec:
            containers:
            - args:
              - ./wstunnel server --log-lvl DEBUG --dns-resolver-prefer-ipv4
                --restrict-http-upgrade-path-prefix {{.RandomPassword}}
                ws://0.0.0.0:8080
              command:
              - bash
              - -c
              image: ghcr.io/dciangot/dciangot/wg:v0.2
              imagePullPolicy: IfNotPresent
              name: wireguard
              ports:
              - containerPort: 8080
                name: webhook
                protocol: TCP
              - containerPort: 51820
                name: vpn
                protocol: UDP
              {{- range .ExposedPorts}}
              - containerPort: {{.Port}}
                name: {{.Name}}
                protocol: {{.Protocol}}
              {{- end}}
              resources:
                requests:
                  cpu: 100m
                  memory: 90Mi
            nodeSelector:
              kubernetes.io/os: linux
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
      spec:
        type: ClusterIP
        selector:
          app.kubernetes.io/component: {{.Name}}
        ports:
          - port: 8080
            targetPort: 8080
            name: ws
          {{- range .ExposedPorts}}
          - port: {{.Port}}
            targetPort: {{.TargetPort}}
            name: {{.Name}}
            {{- if .Protocol}}
            protocol: {{.Protocol}}
            {{- end}}
          {{- end}}
      ---
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
        annotations:
          nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
          nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
          nginx.ingress.kubernetes.io/server-snippets: |
            location / {
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_http_version 1.1;
              proxy_set_header X-Forwarded-For $remote_addr;
              proxy_set_header Host $host;
              proxy_cache_bypass $http_upgrade;
            }
          kubernetes.io/ingress.class: "nginx"
      spec:
        rules:
        - host: ws-{{.Name}}.{{.WildcardDNS}}
          http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: {{.Name}}
                  port:
                    number: 8080
```

### Traefik Ingress Template (Default)

The default template with Traefik ingress controller and WebSocket middleware:

```yaml
virtualNode:
  network:
    enableTunnel: true
    wildcardDNS: "example.com"
    # Uses built-in wstunnel-template.yaml (Traefik-based)
    customTemplate: ""
```

The default template includes Traefik middleware for WebSocket support and
optional IngressRoute configuration.

### NodePort Service (No Ingress)

For environments without ingress controllers, use NodePort:

```yaml
virtualNode:
  network:
    enableTunnel: true
    customTemplate: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
      spec:
        replicas: 1
        selector:
          matchLabels:
            app.kubernetes.io/component: {{.Name}}
        template:
          metadata:
            labels:
              app.kubernetes.io/component: {{.Name}}
          spec:
            containers:
            - args:
              - wstunnel server --log-lvl DEBUG --dns-resolver-prefer-ipv4
                --restrict-http-upgrade-path-prefix {{.RandomPassword}}
                ws://0.0.0.0:8080
              command:
              - bash
              - -c
              image: ghcr.io/erebe/wstunnel:latest
              imagePullPolicy: IfNotPresent
              name: wstunnel
              ports:
              - containerPort: 8080
                name: websocket
                protocol: TCP
              {{- range .ExposedPorts}}
              - containerPort: {{.Port}}
                name: {{.Name}}
                protocol: {{.Protocol}}
              {{- end}}
              resources:
                requests:
                  cpu: 100m
                  memory: 90Mi
            nodeSelector:
              kubernetes.io/os: linux
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
      spec:
        type: NodePort
        selector:
          app.kubernetes.io/component: {{.Name}}
        ports:
          - port: 8080
            targetPort: 8080
            name: ws
            nodePort: 30080
          {{- range .ExposedPorts}}
          - port: {{.Port}}
            targetPort: {{.TargetPort}}
            name: {{.Name}}
            {{- if .Protocol}}
            protocol: {{.Protocol}}
            {{- end}}
          {{- end}}
```

### LoadBalancer Service

For cloud environments with load balancer support:

```yaml
virtualNode:
  network:
    enableTunnel: true
    customTemplate: |
      # ... (same Deployment as above)
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      spec:
        type: LoadBalancer
        selector:
          app.kubernetes.io/component: {{.Name}}
        ports:
          - port: 8080
            targetPort: 8080
            name: ws
          {{- range .ExposedPorts}}
          - port: {{.Port}}
            targetPort: {{.TargetPort}}
            name: {{.Name}}
            {{- if .Protocol}}
            protocol: {{.Protocol}}
            {{- end}}
          {{- end}}
```

### NGINX Ingress

For environments using NGINX ingress controller:

```yaml
virtualNode:
  network:
    enableTunnel: true
    customTemplate: |
      # ... (same Deployment and ClusterIP Service)
      ---
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: {{.Name}}
        namespace: {{.Namespace}}
        annotations:
          kubernetes.io/ingress.class: "nginx"
          nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
          nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
          nginx.ingress.kubernetes.io/websocket-services: "{{.Name}}"
      spec:
        rules:
        - host: ws-{{.Name}}.{{.WildcardDNS}}
          http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: {{.Name}}
                  port:
                    number: 8080
```

## Usage

1. Choose the appropriate template for your environment
2. Update your `values.yaml` with the custom template
3. Deploy with: `helm install virtual-node ./interlink --values values.yaml`
4. The wstunnel template will be mounted at the configured path in the
   virtual kubelet container

## Troubleshooting

- Ensure the template syntax is valid YAML
- Check that all required template variables are used correctly
- Verify port configurations match your network requirements
- Review logs for template parsing errors
