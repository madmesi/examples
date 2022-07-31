# Writing the Dockerfile
After creating and developing your project, you can now build and publish your work using the Dockerfile.
Following are the general steps to build this application
- Copy over the source code to the development environment which has SDK installed.
- Install nuget so you can use the nuget packages while fetching nuget data
- Build the application at /app path eg. `dotnet build "API.csproj" -c Release -o /app/publish`
- Repeat the previous step and replace publish with publish `dotnet publish "API.csproj" -c Release -o /app/publish`
