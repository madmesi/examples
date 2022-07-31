# Writing the Dockerfile
After creating and developing your project, you can now build and publish your work using the Dockerfile.
Following are the general steps to build this application
- Copy over the source code to the development environment which has SDK installed.
- Install nuget so you can use the nuget packages while fetching nuget data
- Build the application at /app path eg. `dotnet build "API.csproj" -c Release -o /app/publish`
- Repeat the previous step and replace publish with publish `dotnet publish "API.csproj" -c Release -o /app/publish`

## Consider using appsetting.example.json file
When in develop environment you can use this config inside you Dockefile, this scenario is most helpful when you have multiple appsetting config files and this prevents confusion. 
- specify the environment in Dockerfile
`ENV ASPNETCORE_ENVIRONMENT develop`
`<!--- the above line uses appsettings.develop.json file --->`
