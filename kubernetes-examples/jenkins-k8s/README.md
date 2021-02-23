This deployment is a complete demo of jenkis, thanks to https://github.com/fleetman-ci-cd-demo/jenkins, I'am able to change values and start an instance of jenkins on any kuberentes cluster, with a bit of change you can have a running jenkins. I added the namespace to the yaml files, I also added the "persistenvolumeclaim" template which you will need in case of persistence. 

just clone the repo :

```
git clone https://github.com/madmesi/jenkins-k8s.git
cd jenkis-k8s
```
Build the Dockerfile:

```
docker build -t myjenkins:latest .
# if you have a docker registry:
# docker build -t myregistry.is.awesome/myjenkins:latest
```
change the values of the image name in the manifest and the deploy both manifest (which includes most of the files) and then the pvc:

```
kubectl create -f manifest.yaml
kubectl create -f pvc.yaml
```
check the pods:
```
kubectl get po -n jenkins
```
