# keycloak
If yoy are looking for a clean way to dump the embedded .h2 database, it does't exist. But there's that you can do:

```
kubectl get po -n <NAMESPACE>
kubectl exec -it <POD_NAME> -n <NAMESPACE> -- bash
cd /opt/jboss
```

search for the h2 driver jar file:
```
egrep -ir "h2-*.jar"
```

In this way, you request a shell using ht tools shell:
```
java -cp /opt/jboss/keycloak/modules/system/layers/base/com/h2database/h2/main/h2-1.4.197.jar org.h2.tools.Shell
```

then enter the sql commandline. 

```
Welcome to H2 Shell
Exit with Ctrl+C
[Enter]   jdbc:h2:mem:2
URL       jdbc:h2:./path/to/database
[Enter]   org.h2.Driver
Driver
[Enter]   sa
User      your_username
Password  (hidden)
Type the same password again to confirm database creation.
Password  (hidden)
Connected
sql> BACKUP TO 'backup.zip' ;
sql> exit
```

source:
http://www.h2database.com/html/tutorial.html



Adding timezone to the keycloak container, is possible with mounting the path to the server it's running on: 

```
        volumeMounts:
        - name: keycloak-volume
          mountPath: /opt/jboss/keycloak/standalone/data
        - name: tz-tehran
          mountPath: /etc/localtime
      volumes:
      - name: keycloak-volume
        persistentVolumeClaim:
          claimName: keycloak-claim
      - name: tz-tehran
        hostPath:
          path: /usr/share/zoneinfo/Asia/Tehran
      serviceAccountName: keycloak-operator
```

the first volume 'keycloak-volume' holding the data of the path '/opt/jboss/keycloak/standalone/data' (which exists in the pod obviously) is going to be persisted in this way. why? because where the pod goes down, the node or anything else goes down and when it comes back, your data (including REALMS) are persisted.
