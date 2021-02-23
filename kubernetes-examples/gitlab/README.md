**Easy install gitlab on kubernetes with ingress and persistence **

source: https://github.com/sameersbn

NB: please change all these sample values to your desired ones.

# TL;DR
## Installation
```
git clone https://github.com/madmesi/gitlab-kuberentes-v16-.git
```

```
cd gitlab-kuberentes-v16-
```
1. create namespace

```
kubectl create -f ns.yaml
```
2. create gitlab deployment, service, persistentvolumeclaim and ingress resource:
```
kubectl create -f gitlab/gitlab-deployment.yaml ; kubectl create -f gitlab/gitlab-svc-nodeport.yaml ; kubectl create -f gitlab/pvc/gitlab-pvc.yaml ; kubectl create -f gitlab/gitlab-ingress.yaml
```

3. create postgresql deploymnet, service, persistentvolumeclaim:
```
kubectl create -f gitlab/postgresql-deployment.yaml ; kubectl create -f gitlab/postgresql-svc.yaml ; kubectl create -f gitlab/pvc/postgresql-svc.yaml
```

4. create redis deployment, service:
```
kubectl create -f gitlab/redis-deployment.yaml ; kubectl create -f gitlab/redis-svc.yaml
```


# Installing and configuring gitlab-runner with helm:

Configuring the values.yaml file:
choosing the runner base image, I got to choose "alpine:latest". Since this is pretty litghweight and also configurable. remember we're going to use it in the gitlab, so when It's picking a job, it should be quick and ready. You can choose between the options of ubuntu and everything else that you got. And also you got to have a bash or shell inside the running pod.

```
  image: alpine:latest

# setting security context to root, as you may need to install packages in the pod to further troubleshoot. If you're not interested in this context just leave it commented. The default values stand for user "gitlab-runner"

  securityContext:
    fsGroup: 0
    runAsUser: 0

  locked: false
# if the runner should be locked and reserved when started in the gitlab

  ## Run all containers with the privileged flag enabled
  ## This will allow the docker:stable-dind image to run if you need to run Docker
  ## commands. Please read the docs before turning this on:
  ## ref: https://docs.gitlab.com/runner/executors/kubernetes.html#using-docker-dind
  ##
  privileged: true
```
```
helm version
Server: &version.Version{SemVer:"v2.16.3", GitCommit:"1ee0254c86d4ed6887327dabed7aa7da29d7eb0d", GitTreeState:"clean"}

helm install --namespace mynamespace --name my-runner -f values.yaml gitlab/gitlab-runner --set nodeSelector."kubernetes\\.io/hostname"=My-awesome-worker
# replace the name of worker with your worker node names
```
--set persistence.storageClass=nfs
