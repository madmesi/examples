# wordpress-compose
Easy launch one instance of wordpress + mysql on your host using docker-compose without upload limitation:
``` docker-compose up -d ```

# Uninstall:
``` docker-compose down ```
or use the ps command :

``` 
docker ps 
dock stop <container_id>
docker rm <container_id>
```

If you want to change the image tag or use an older one, you can remove the downloaded images from your local docker repository:

```
docker images 
docker rmi <image_name>
```
NB: make sure there are no running cotainers when you want to remove the image, otherwise you may encounter errors.
