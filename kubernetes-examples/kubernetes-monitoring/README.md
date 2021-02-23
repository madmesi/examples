# kubernetes-monitoring

Kubertnetes monitoring with prometheus and alerting with alertmanager. Default backend for alertmanager is Rocketchat.

1. Configure Prometheus

The Prometheus server requires a configuration file that defines the endpoints to scrape along with how frequently the metrics should be accessed.

The first half of the configuration defines the intervals.

open prmetheus configmap and replace your desired values:

```
global:
  scrape_interval:     2m
  evaluation_interval: 10s
```

The second half defines the servers and ports that Prometheus should scrape data from.

```
scrape_configs:
      - job_name: 'kubernetes-apiservers'
      ...
      - job_name: 'kubernetes-nodes'
      ...   
```

and we can also define static configs as well:
these are the endpoints that we want to scrape:

```
        static_configs:
        - targets:
          - "alertmanager.monitoring.svc:9093"
          - "prometheus-node-exporter.monitoring.svc:9100"
```

another sample:
```
      - job_name: 'prometheus'
        static_configs:
        - targets: ['localhost:9090']
```

