# interLink Helm Chart

::: danger :::

Work in progress!

::: danger :::

## Quick-start

```bash
helm install --create-namespace -n interlink virtual-node oci://ghcr.io/intertwin-eu/interlink-helm-chart/interlink --values values.yaml
```

To deploy the following scenarios, please refer to the official [Cookbook](https://intertwin-eu.github.io/interLink/docs/cookbook)

### Edge-node service

In this mode you will deploy:
- virtual kubelet and token refresher
- plugin and interlink API server + OAuth2_proxy on the remote side

__It is recommended to start deploy the remote components first! The release will only succeed upon virtual node being in Ready status. This can occur if all the chain is in place.__

### Edge-node with socket

In this mode you will deploy:
- interlink and virtual kubelet + ssh service 
- only plugin on the remote side

__It is recommended to start deploy the remote components first! The release will only succeed upon virtual node being in Ready status. This can occur if all the chain is in place.__

### In-cluster mode

In this mode you will deploy:
- Everything deploy in cluster with socket communication
    - Virtual kubelet, interlink API server and plugin
- Remote side is the container manager API and point


## F.A.Q.

- Conditions for chart to be ready: all the components should be online, remote ones included. 
