# Writing the Dockerfile
After creating and developing your project, you can now build and publish your work using the Dockerfile.
Following are the general steps to build this application
- Copy over the source code to the development environment which has SDK installed.
- Install nuget so you can use the nuget packages while fetching nuget data
- Restore all dotnet layers with `dotnet restore --no-cache --configfile=~/.nuget/NuGet/NuGet.Config "src/PATH1/APIPATH/API.csproj"`
- Build the application at /app path eg. `dotnet build "API.csproj" -c Release -o /app/publish`
- Repeat the previous step and replace publish with publish `dotnet publish "API.csproj" -c Release -o /app/publish`

## Consider using appsetting.example.json file
When in develop environment you can use this config inside you Dockefile, this scenario is most helpful when you have multiple appsetting config files and this prevents confusion. 
- specify the environment in Dockerfile

`ENV ASPNETCORE_ENVIRONMENT develop`

`<!--- the above line uses appsettings.develop.json file --->`

# docker-compose
docker-compose is the manifest for your Dockerfile hence it stores the manifestation. Before going into details about building the Dockerfile with docker-compose, 
pay attention to this block:

`networks:
  default:
    external:
      name: develop`

Network is of type external and its name is develop. So the external docker network should exist before creating the docker-compose. If you haven't created one before, with this command you can create it.

`docker network create develop`


Second point:

`services:
  myapp-develop:
    build:
      context: .
      dockerfile: Dockerfile`
      
The above block builds up your Dockerfile. In the previous step you created the Dockerfile, pay attention that the Dockerfile doesn't exist in any registry, so that's why you create it from scratch, from your code base. 
This `context: . ` means that Dockerfile exists here (wherever the docker-compose exists in a filesystem, the Dockerfile exists there too)


Other points:
existing commands to a docker-compose file which might come in handy:

- `docker-compose ps `
Shows the running containers (if they are up)
You can also specify which docker-compose file you mean:

`docker-compose -f docker-compose-develop.yml ps `


- `docker-compose config`

when you run docker-compose config, it reads the docker-compose.yml in the current directory and checks for any syntactical errors. If found, shows the error with the line number to help you debug.


- another command is 

`docker-compose pause 


- `docker-compose up -d` 
launches the containers for all applications defined inside the service section. It does that in the detached mode provided using option `-d`, which is similar to the docker run option. Try running `docker-compose up` without this option to see what happens.
