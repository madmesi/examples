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
