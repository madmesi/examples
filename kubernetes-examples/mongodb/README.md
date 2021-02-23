How to do a remote mongodb dump and add it to cron:
edit the file as you wish and then

```
chmod +x mongobackup.sh
```

```
crontab -e
00 00 * * * /root/backup-db/sample-dump.sh >> /data/mongo_backup.log 2>&1
00 00 */3 * * find /data/ -mtime +10 -type f -delete
```


if you don't have the command line of mongo and you prefer to use mongo docker image:
do this in the sh file:
```
docker exec $CONTAINER_BU sh -c 'mongodump --host <Monogo_remote_host>:<Mongo_remote_port> --archive' > db.dump
```

How to dump and restore a mongo container:

```
#Run
docker run -p 27017:27017 -it -v mongodata:/data/db --name mongodb -d mongo:4.0.4

#Dump
docker exec <mongodb container> sh -c 'mongodump --archive' > db.dump

#Restore
docker exec -i <mongodb container> sh -c 'mongorestore --archive' < db.dump
```
We are going to use a mongodb container to backup our other instances of mongodb:
How to install the mongodb runner?
```
mkdir mongodata
docker pull mongo:latest
docker images | grep mongo
...
## this way I bind the mongodb container port (27017) to the 27017 of the host:
docker run -it -v mongodata:/data/db -p 27017:27017 --name mongodb -d mongo
## check container
docker ps | grep mongo
## check port
netstat -ntlp | grep 27017
docker logs mongodb
```

Stopping and Restarting MongoDB Database
```
docker stop mongodb
docker ps
docker start mongodb
```

Find more about the container:

```
docker ps | grep mongo
docker container top <UID>
```

ENABLE ACCESS CONTROL
```
# How to set password on mongodb server:
# Create the user administrator.
use admin
db.createUser(
  {
    user: "myUserAdmin",
    pwd: passwordPrompt(), // or cleartext password
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
  }
)

## Re-start the MongoDB instance with access control.
db.adminCommand( { shutdown: 1 } )

vim /etc/mongod.conf
security:
    authorization: enabled

## Connect and authenticate as the user administrator.
mongo --port 27017  --authenticationDatabase "admin" -u "myUserAdmin" -p

## Create additional users as needed for your deployment.
use test
db.createUser(
  {
    user: "myTester",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "readWrite", db: "test" },
             { role: "read", db: "reporting" } ]
  }
)

## Connect to the instance and authenticate as myTester.
mongo --port 27017 -u "myTester" --authenticationDatabase "test" -p
```
