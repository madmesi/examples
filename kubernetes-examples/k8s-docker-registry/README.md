
1) Set up htpasswd for Basic Auth

Let’s have a user called admin with password admin123:
`docker run --entrypoint htpasswd --rm registry:2 -Bbn admin admin123 | base64`
You can replace your own desired username and password by replacing 'admin' and 'admin123'
On the output we get htpasswd in base64 format ready to be stored in a Secret:

in the secret file place the output in the HTPASSWD field:

```
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry
type: Opaque
data:
  HTPASSWD: YWRtaW46JDJ5JDA1JHJwWHlibVNIMWhEV2VFYjJJUHg5aS5ENmh0MVZjMVBob3YyUnlXSEQzOFdEM1EvYlQ3em8uCgo=
```

 
2) Configuration of Docker Registry
Here we have the most basic config of Docker Registry where we define auth method to be Basic Auth with a path to a htpasswd file. Mounting our htpasswd secret is handled in our Pod definition.
To allow deleting docker images by ui , you have to add a few fields:
Enable deleting docker images in the registry: 

```
    version: 0.1
    log:
      fields:
        service: registry
    storage:
      delete:
        enabled: true
```


and add this lines to the 'headers':

```
Access-Control-Allow-Origin: ['*']
        Access-Control-Allow-Methods: ['HEAD', 'GET', 'OPTIONS', 'DELETE']
        Access-Control-Allow-Headers: ['Authorization']
        Access-Control-Max-Age: [1728000]
        Access-Control-Allow-Credentials: [true]
        Access-Control-Expose-Headers: ['Docker-Content-Digest']
```

and the last part connect the registry ui to the backend registry:

```
            - name: DELETE_IMAGES
              value: "true"
            - name: REGISTRY_URL
              value: "http://docker-registry.default.svc.cluster.local:5000"
```

Ref:
https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/


Kubernetes secret help:
make your password or any key base64 encoded:

```
echo "mega_secret_key" | base64
bWVnYV9zZWNyZXRfa2V5Cg==
```

decode:

```
echo "bWVnYV9zZWNyZXRfa2V5Cg==" | base64 -d
mega_secret_key
```

make secret file:

```
apiVersion: v1
kind: Secret
metadata:
  name: dummy-secret
type: Opaque
data:
  API_KEY: bWVnYV9zZWNyZXRfa2V5Cg==
  API_SECRET: cmVhbGx5X3NlY3JldF92YWx1ZTEK
```

Using openssl:

```
openssl enc -base64 <<< 'Hello, World!'
SGVsbG8sIFdvcmxkIQo=

openssl enc -base64 -d <<< SGVsbG8sIFdvcmxkIQo=
Hello, World!
```


NB: If you are using nginx-ingress to access your backend services, you're going to neeed to change the configmap of nginx-ingress:
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-config
  namespace: nginx-ingress
data:
  server-tokens: "false"
  real-ip-header: "proxy_protocol"
  set-real-ip-from: "0.0.0.0/0"
  proxy-connect-timeout: "10s"
  proxy-read-timeout: "10s"
```

Sample ingress resource for docker-registry:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: registry-ing
  namespace: default
  labels:
    name: docker-registry
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.org/proxy-connect-timeout: "30s"
    nginx.org/proxy-read-timeout: "20s"
    nginx.org/client-max-body-size: "0"
spec:
  rules:
  - host: registry.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: docker-registry
          servicePort: 5000
```
If you face sth like this:
Failed to pull image "example.eu-west-1.amazonaws.com/app-t:latest": rpc error: code = Unknown desc = Error response from daemon: Get https://example.eu-west-1.amazonaws.com/v2/app-t/manifests/latest: no basic auth credentials

You have to use credentials while pulling an image.
If you want to use private registry while pulling an image in kubernetes you have to make secret and user imagepullsecret option:

```
docker login registry.example.com
cat ~/.docker/config.json

## The output contains a section similar to this:

{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "c3R...zE2"
        }
    }
}
```

Create a Secret based on existing Docker credentials 

```
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<root/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```

If you are using a specific namespace remember to add "regcred" into that namespace:

```
kubectl create secret generic regcred     --from-file=.dockerconfigjson=/root/.docker/config.json     --type=kubernetes.io/dockerconfigjson -n mynamespace
```
see if you password matches:
```
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

source: 
https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

