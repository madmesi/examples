** Easy install ingress-nginx on kubernetes cluster (with nodeport svc) **

source: https://github.com/nginxinc/kubernetes-ingress

NB: please change all these sample values to your desired ones.

# TL;DR
## Installation
```
git clone https://github.com/madmesi/ingress-nginx
```

```
cd ingress-nginx
```
1. Create a namespace and a service account for the Ingress controller:

```
kubectl create -f 1-ns-sa.yaml 
```
Note: To perform this step you must be a cluster admin. Follow the documentation of your Kubernetes platform to configure the admin access. For GKE, see the Role-Based Access Control doc.

2. Create a cluster role and cluster role binding for the service account:
```
kubectl create -f 2-rbac.yaml
```

3. Create the Default Secret, Customization ConfigMap, and Custom Resource Definitions ( a secret with a TLS certificate and a key for the default server in NGINX)

```
kubectl create -f 3-default-server-secret.yaml 
```
Note: The default server returns the Not Found page with the 404 status code for all requests for domains for which there are no Ingress rules defined. For testing purposes we include a self-signed certificate and key that we generated. However, I recommend that you use your own certificate and key.

4. Create a config map for customizing NGINX configuration
```
kubectl create -f 4-nginx-config.yaml
```
5. Create custom resource definitions for VirtualServer and VirtualServerRoute resources:
```
kubectl create -f 5-custom-resource-definitions.yaml
```
6. Deploy the Ingress Controller

NOTE: There are two options based on how you deploy your ingress controller:

 Deployment. Use a Deployment if you plan to dynamically change the number of Ingress controller replicas.
 DaemonSet. Use a DaemonSet for deploying the Ingress controller on every node or a subset of nodes.

# option 1:
Use a Deployment. When you run the Ingress Controller by using a Deployment, by default, Kubernetes will create one Ingress controller pod.

```
kubectl create -f 601-deployment-nginx-ingress.yaml
```

# option 2:
Use a DaemonSet: When you run the Ingress Controller by using a DaemonSet, Kubernetes will create an Ingress controller pod on every node of the cluster.

```
kubectl create -f 602-daemonset-nginx-ingress.yaml
```

Check that the Ingress Controller is Running

```
kubectl get pods --namespace=nginx-ingress
```

## Get Access to the Ingress Controller
### Create a Service for the Ingress Controller Pods:

Create a service with the type NodePort:

```
kubectl create -f 7-svc-nodeport.yaml
```

see the docs on how to deploy on aws and azure using a loadbalancer service:
source : https://github.com/nginxinc/kubernetes-ingress/tree/master/deployments/service

## install by manifest:
# mandatory for all deployments:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml

```
```

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/baremetal/service-nodeport.yaml

```
## note when getting the error 413, you have to change the configmap of the original file:
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  data:
    proxy-body-size: 50m

```
## this example increases the proxy body size to 50mi. 
