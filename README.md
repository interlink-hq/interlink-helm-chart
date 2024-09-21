# interLink Helm Chart

::: danger :::

Work in progress!

::: danger :::

## Quick-start

```bash
helm install --create-namespace -n interlink virtual-node oci://ghcr.io/intertwin-eu/interlink-helm-chart/interlink --values values.yaml
```

### Edge-node service

In this mode you will deploy:

__It is recommended to start deploy the remote components first! The release will only succeed upon virtual node being in Ready status. This can occur if all the chain is in place.__


### In-cluster mode

In this mode you will deploy:

__It is recommended to start deploy the remote components first! The release will only succeed upon virtual node being in Ready status. This can occur if all the chain is in place.__

## F.A.Q.

- Conditions for chart to be ready: 
