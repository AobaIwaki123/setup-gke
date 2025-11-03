```sh
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo add grafana https://grafana.github.io/helm-charts

$ helm repo update

$ helm search repo prometheus-community/prometheus --versions | head -n3
NAME                                              	CHART VERSION	APP VERSION	DESCRIPTION                                       
prometheus-community/prometheus                   	27.42.2      	v3.7.3     	Prometheus is a monitoring system and time seri...
prometheus-community/prometheus                   	27.42.1      	v3.7.3     	Prometheus is a monitoring system and time seri...
$ helm search repo grafana --versions | head -n3
NAME                                          	CHART VERSION	APP VERSION       	DESCRIPTION                                       
grafana/grafana                               	10.1.4       	12.2.1            	The leading tool for querying and visualizing t...
grafana/grafana                               	10.1.3       	12.2.1            	The leading tool for querying and visualizing t...
```

```sh
$ argocd app create --file prometheus.yaml
$ argocd app create --file grafana.yaml
```

```sh
$ kubectl apply -f ingress.yaml
```

## Helm Chart

- [Grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
- [Prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)

## Ref.

- [Prometheus - Helm](https://github.com/prometheus-community/helm-charts)
- [Grafana - Helm](https://github.com/grafana/helm-charts)