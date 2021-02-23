# Part one : Java Application on Kubernetes
How to deploy your java application into kubernetes step by step:
1) after commiting your latest changes to the code repository, you have to make sure your app works on your locahost.
2) After the assurance you have to change your default values ( which helps you connect to your databases, etc...)
make you app reads your values dynamically, from your "application.properties" file, which probably is inside "src/main/resources/"

```
sample application.porperties:
spring.data.mongodb.database=${MONGO_DB_NAME:samplename}
spring.data.mongodb.host=${MONGO_DB_HOST}
```

The reason why we are doing this is because of "service discovery". The great mechanism in Kubernetes that helps you to forget about the ungliness of writing ips instead of dns names. The service discovery in short helps you get rid of your ip addressing and with the help of spring boot you can set dynamic config for your mongo, redis and all sorts of dependencies. I'll talk about it more in next steps.

3) You can build your java application now with the help of mvnw:
`./mvnw clean install`
The output gives you the example.jar file that you need.
It's a probably a good idead to test your java app before running it (in case you have an instance of mongodb localy):
`java -jar target/example.jar`

4) To build the kubernetes deployment you are gonna need a dockerfile (you can push image localy, a local repository or a public repository like dockerhub and ...)
Now you build you dockerimage:
`docker build -t myregistry.example.com/myjavaapp:1.0 .`

NB: This deployment is namespaced, if you are not willing (or doesn't have admin access to the k8s cluster or openshift cluster) to create a namespace, ignore "rbac" file and delete "namespace" in all yaml files ( which probably is not a good idea).
5) Deploymennt walkthrough:
Inside .spec section , the "label" field holds great value, which is the selector of the application that matches its corresponding service.
In this example it is   .spec.labels. app:Myapp
Feel free you change the default values.

You also have to change the port value to your desired value.


The important part is the "env" part which I mentioned afew sections ago. The values that you provided before, are going to take place inside the "env" part.
5) Now you can write your java application manifest. make sure to change the default values:

```
        env:
          - name: MONGO_DB_HOST
            value: "mongodb"
          - name: MONGO_DB_PORT
            value: "27017"
          - name: REDIS_HOST
            value: "redis"
          - name: REDIS_URL
            value: "redis"
          - name: REDIS_PORT
            value: "6379"
```
The `value: "mongodb"` is shortened form of servicediscovery feature, a service name (which in this case the servicename is also mongodb)+ namespace name (I chose "mynamespace" for the sake of this tutorial) + svc.cluster.local , which will be = `mongodb.mynamespace.svc.cluster.local`
The same goes for redis and other dependencies.

6) Make a service for you java application. "service" object in kubernetes helps you connect application traffic to other applications and also outside the cluster. You can choose the service type of any values :`ClusterIP, nodePort, loadbalancer` and etc. You can read more about the types of services in the kubernetes official docs.


# Part two: Mongodb backup and restore; Kubernetes way

```
# findout the mongodb pod (in case of kubernetes), or find the ID or container name in docker (swarm) mode.
kubectl get po -n <YOUR_NAMESAPCE>
kubectl exec -it mongodb-795c5455c-q2jqd -n <YOUR_NAMESAPCE> -- bash
# in some builds bash isn't the default shell, in this case you can use "sh". If it is not configured use a base image like alpine for your mongo.
# type mongo to use mongo commandline interface
mongo
> show dbs
...
admin    0.000GB
config   0.000GB
local    0.000GB

# so you got the name of the dbs and can make sure the output when dumping.
# exit mongo commandline
# type the below command and use a target, in this case I'm using tmp/ (and the output is .tar)
mongodump --gzip tmp/
tar czfv admin/ mydb/ mongobackup.tar.gz
# exit pod and copy the the dump file to the host using "kubectl cp" command:
kubectl cp mongodb-795c5455c-q2jqd:tmp/mongodump.tar.gz ./mongodump.tar.gz -n <MY_NAMESAPCE>

# copy files to your desired mongo pod
kubectl cp mongodump.tar.gz -n <MY_NAMESAPCE> mongodb-6fcc845c85-jtq4m:/tmp/

# enter new mongodb pod:
kubectl exec -it  -n newario mongodb-6fcc845c85-jtq4m -- bash
# restore:
mongorestore -d mydb --gzip tmp/mydb_db/
```
It is a good practice to remeber the syntax while doing dump or restore:

```
mongodump --db ${DB_NAME} --gzip -o ${BACKUP_FILE_GZ}
mongorestore --gzip --db "${DB_NAME_RESTORE}" ${BACKUP_FILE_GZ}/${DB_NAME}
```

# Part three: Kubernetes Hacks
Deleting a stuck namespace.
Option 1: Identify and manually remove resources which can't be automatically deleted
Check for namespace resources which aren't being automatically removed:

After attempting to delete the namespace, some resources may not have been deleted. If you can identify and manually remove all remaining resources the namespace will finish Terminating.

```
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get -n namespace name
kubectl get apiservice | grep False
```

This script finds all stuck namespaces and delete them.

```
cat > delete_stuck_ns.sh << "EOF"
#!/usr/bin/env bash

function delete_namespace () {
    echo "Deleting namespace $1"
    kubectl get namespace $1 -o json > tmp.json
    sed -i 's/"kubernetes"//g' tmp.json
    kubectl replace --raw "/api/v1/namespaces/$1/finalize" -f ./tmp.json
    rm ./tmp.json
}

TERMINATING_NS=$(kubectl get ns | awk '$2=="Terminating" {print $1}')

for ns in $TERMINATING_NS
do
    delete_namespace $ns
done
EOF
```
```
chmod +x delete_stuck_ns.sh
./delete_stuck_ns.sh
# check
kubectl get ns
```

Make a Kubernetes node unschedulable (for maintenance):
```
kubectl get nodes
kubectl cordon <node_name>
# make the node schedulable again:
kubectl uncordon <node_name>

# draining a node due to updating kernel or whatever reason:
kubectl drain <node_name>
# sometimes you have to consider adding the "--ignore-deamonsets" switch.
```

Troublshooting calico:
```
kubectl get po -n kube-system -owide
# when you see the BGP error in the logs of calico:
# Readiness probe failed: Threshold time for bird readiness check:  30s
# calico/node is not ready: BIRD is not ready: BGP not established with 192.168.56.1012019-04-18 16:59:49.812 [INFO][300] readiness.go 88: Number of node(s) with BGP peering #established = 0
# source : https://github.com/projectcalico/calico/issues/2561
# summary: this is related to the network interface profile, when for instance removing flannel, or recreating calico, the interface remains and you have to remove it mannualy. 
# and allow the calico to do it itself.

# detect the interface:
ifconfig
## install calicoctl
curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.16.1/calicoctl
chmod +x calicoctl
mv calicoctl /usr/bin/
kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=interface=ens192
calicoctl get profiles -owide
calicoctl node status

# source: https://stackoverflow.com/questions/54465963/calico-node-is-not-ready-bird-is-not-ready-bgp-not-established
```


```
# Partially update a node
kubectl patch node k8s-node-1 -p '{"spec":{"unschedulable":true}}'

# Update a container's image; spec.containers[*].name is required because it's a merge key
kubectl patch pod valid-pod -p '{"spec":{"containers":[{"name":"kubernetes-serve-hostname","image":"new image"}]}}'

# Disable a deployment livenessProbe using a json patch with positional arrays
kubectl patch deployment valid-deployment  --type json   -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe"}]'

# Add a new element to a positional array
kubectl patch sa default --type='json' -p='[{"op": "add", "path": "/secrets/1", "value": {"name": "whatever" } }]'

# editing resources:
KUBE_EDITOR="vim" kubectl edit svc/docker-registry   
```

Resource types 
List all supported resource types along with their shortnames, API group, whether they are namespaced, and Kind:

```
kubectl api-resources
```

RESTRICT USER ACCESS TO ONE NAMESPACE
Especially if you are giving access remotely and want to reduce risks on cluster-wide operation:
1. create a namespace and it's rbac related objects. It's included in this repository.
2. Get the user token:
```
# find the secret in the namespace you created earlier:
kubectl get secret -n <namespace_name>
<secret-name>
# As Kubernetes secrets are base64 encoded, I’ll also need to decode them.
kubectl get secret <secret-name> -n <namespace_name> -o "jsonpath={.data.token}" | base64 -d
```
3. Get the Certificate:
```
kubectl get secret <secret_name> -n <namespace_name> -o "jsonpath={.data['ca\.crt']}"
```

4. Define the context: linking a user to a cluster
```
# Create Kube config:
vim config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: PLACE CERTIFICATE HERE
    # You'll need the API endpoint of your Cluster here:
    server: https://<IP_CLUSTER>:6443
  name: kubernetes

# Define the context: linking a user to a cluster
contexts:
- context:
    cluster: kubernetes
    namespace: <ns_name>
    user: <serviceaccount>
  name: newario
current-context: <ns_name>
kind: Config
preferences: {}
# Define the user
users:
- name: <serviceaccount>
  user:
    as-user-extra: {}
    client-key-data: PLACE CERTIFICATE HERE
    token: PLACE USER TOKEN HERE

```

# Updating a running Kubernnetes Deployment docker image zero downtime:

```
kubectl get deploy -n <YOUR_NAMESPACE>
kubectl set image deployment <DEPLOY_NAME> -n <YOUR_NAMESPACE> <image_name>=<YOUR_DOCKER_IMAGE>
# if it fails you can always roll back to a previous build:
kubectl rollout history deployment/<DEPLOY_NAME> -n <YOUR_NAMESPACE>
1
2
3
kubectl rollout undo deployment/<DEPLOY_NAME> -n <YOUR_NAMESPACE>
```

# Assiging limit requests to pods:
## CPU limit:
To specify a CPU request for a container, include the resources:requests field in the Container resource manifest. To specify a CPU limit, include resources:limits.

with this instructions, you create a Pod that has one container. The container has a request of 0.5 CPU and a limit of 1 CPU. Here is the configuration file for the Pod:

```
spec:
  containers:
  - name: sample container
    image: <imageame:imagetag>
    resources:
      limits:
        cpu: "1"
      requests:
        cpu: "0.5"
```

Specify a CPU request that is too big for your Nodes

CPU requests and limits are associated with Containers, but it is useful to think of a Pod as having a CPU request and limit. The CPU request for a Pod is the sum of the CPU requests for all the Containers in the Pod. Likewise, the CPU limit for a Pod is the sum of the CPU limits for all the Containers in the Pod.

Pod scheduling is based on requests. A Pod is scheduled to run on a Node only if the Node has enough CPU resources available to satisfy the Pod CPU request.

with this instructions, you create a Pod that has a CPU request so big that it exceeds the capacity of any Node in your cluster. Here is the configuration file for a Pod that has one Container. The Container requests 100 CPU, which is likely to exceed the capacity of any Node in your cluster.

```
spec:
  containers:
  - name: sample container
    image: <imageame:imagetag>
    resources:
      limits:
        cpu: "100"
      requests:
        cpu: "100"
```
## If you do not specify a CPU limit
If you do not specify a CPU limit for a Container, then one of these situations applies:

The Container has no upper bound on the CPU resources it can use. The Container could use all of the CPU resources available on the Node where it is running.

The Container is running in a namespace that has a default CPU limit, and the Container is automatically assigned the default limit. Cluster administrators can use a LimitRange to specify a default value for the CPU limit.
    

## RAM limit:
Specify a memory request and a memory limit

To specify a memory request for a Container, include the resources:requests field in the Container's resource manifest. To specify a memory limit, include resources:limits.
with this instructions, you create a Pod that has one Container. The Container has a memory request of 100 MiB and a memory limit of 200 MiB. Here's the configuration file for the Pod:

```
spec:
  containers:
  - name: sample container
    image: <imageame:imagetag>
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
```
Container in the Pod has a memory request of 100 MiB and a memory limit of 200 MiB.

## Exceed a Container's memory limit
A Container can exceed its memory request if the Node has memory available. But a Container is not allowed to use more than its memory limit. If a Container allocates more memory than its limit, the Container becomes a candidate for termination. If the Container continues to consume memory beyond its limit, the Container is terminated. If a terminated Container can be restarted, the kubelet restarts it, as with any other type of runtime failure.


## Specify a memory request that is too big for your Nodes

Memory requests and limits are associated with Containers, but it is useful to think of a Pod as having a memory request and limit. The memory request for the Pod is the sum of the memory requests for all the Containers in the Pod. Likewise, the memory limit for the Pod is the sum of the limits of all the Containers in the Pod.

Pod scheduling is based on requests. A Pod is scheduled to run on a Node only if the Node has enough available memory to satisfy the Pod's memory request.
with this instructions, you create a Pod that has a memory request so big that it exceeds the capacity of any Node in your cluster. Here is the configuration file for a Pod that has one Container with a request for 1000 GiB of memory, which likely exceeds the capacity of any Node in your cluster.

```
spec:
  containers:
  - name: sample container
    image: <imageame:imagetag>
    resources:
      limits:
        memory: "1000Gi"
      requests:
        memory: "1000Gi"
```

## If you do not specify a memory limit

If you do not specify a memory limit for a Container, one of the following situations applies:

    The Container has no upper bound on the amount of memory it uses. The Container could use all of the memory available on the Node where it is running which in turn could invoke the OOM Killer. Further, in case of an OOM Kill, a container with no resource limits will have a greater chance of being killed.

    The Container is running in a namespace that has a default memory limit, and the Container is automatically assigned the default limit. Cluster administrators can use a LimitRange to specify a default value for the memory limit.

## Motivation for memory requests and limits

By configuring memory requests and limits for the Containers that run in your cluster, you can make efficient use of the memory resources available on your cluster's Nodes. By keeping a Pod's memory request low, you give the Pod a good chance of being scheduled. By having a memory limit that is greater than the memory request, you accomplish two things:

    The Pod can have bursts of activity where it makes use of memory that happens to be available.
    The amount of memory a Pod can use during a burst is limited to some reasonable amount.


# Create a LimitRange (assinged to a namesapce):
Here's the configuration file for a LimitRange object. The configuration specifies a default memory request and a default memory limit.

```
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: 512Mi
    defaultRequest:
      memory: 256Mi
    type: Container
 ```
 
 Now if a Container is created in the "example" namespace, and the Container does not specify its own values for memory request and memory limit, the Container is given a default memory request of 256 MiB and a default memory limit of 512 MiB.
Here's the configuration file for a Pod that has one Container. The Container does not specify a memory request and limit.

```
apiVersion: v1
kind: Pod
metadata:
  name: default-mem-demo
spec:
  containers:
  - name: default-mem-demo-ctr
    image: nginx
```
See the output:

```
kubectl get pod default-mem-demo --output=yaml --namespace=example
```
The output shows that the Pod's Container has a memory request of 256 MiB and a memory limit of 512 MiB. These are the default values specified by the LimitRange.

```
containers:
- image: nginx
  imagePullPolicy: Always
  name: default-mem-demo-ctr
  resources:
    limits:
      memory: 512Mi
    requests:
      memory: 256Mi
```
see? we didn't set limits and requests for our pod. Since we defined the "memory limit" and the "memory requests" for our namespace, the pod is picking values from the limitrange that we created before.

# Summary:
If you wannt to create a pod with resource limits and resource requests you can you a sample like this:
Both for CPU and RAM:
```
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "200Mi"
        cpu: "1"
      requests:
        memory: "100Mi"
        cpu: "0.5"
 ```

sources: https://success.docker.com/article/kubernetes-namespace-stuck-in-terminating 

https://www.kalc.io/blog/how-to-delete-a-namespace-stuck-at-terminating-state

https://nasermirzaei89.net/2019/01/27/delete-namespace-stuck-at-terminating-state/

https://stackoverflow.com/questions/52369247/namespace-stuck-as-terminating-how-do-i-remove-it

https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/

https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/

https://jeremievallee.com/2018/05/28/kubernetes-rbac-namespace-user.html
