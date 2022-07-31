FROM mcr.microsoft.com/dotnet/aspnet:6.0-bullseye-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim AS build
WORKDIR /src
RUN apt update && apt install nuget -y
COPY . .
ADD ./NuGet.Config  ~/.nuget/NuGet/NuGet.Config
RUN dotnet restore --no-cache --configfile=~/.nuget/NuGet/NuGet.Config "src/PATH1/APIPATH/API.csproj"
WORKDIR "/src/PATH1/APIPATH/API.csproj"
RUN dotnet build "API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "API.dll"]
