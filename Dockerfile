FROM mcr.microsoft.com/powershell:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY setup-megalinter.ps1 .

ENTRYPOINT ["pwsh", "-NoProfile", "-File", "setup-megalinter.ps1"]
CMD ["-ProjectRoot", "/workspace", "-RepoUrl", "https://github.com/valorisa/Test-and-Fix-MegaLinter-Tool.git"]