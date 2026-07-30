FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY TrainingApp.slnx ./
COPY src/TrainingApp.Api/TrainingApp.Api.csproj src/TrainingApp.Api/
RUN dotnet restore src/TrainingApp.Api/TrainingApp.Api.csproj
COPY src/TrainingApp.Api src/TrainingApp.Api
RUN dotnet publish src/TrainingApp.Api/TrainingApp.Api.csproj -c Release -o /app --no-restore
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends libgssapi-krb5-2 wget && rm -rf /var/lib/apt/lists/* && useradd --create-home --uid 10001 appuser
COPY --from=build --chown=appuser:appuser /app .
USER appuser
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet","TrainingApp.Api.dll"]
