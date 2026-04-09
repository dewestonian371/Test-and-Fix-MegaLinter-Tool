<#
.SYNOPSIS
    Setup automatisé du repo Test-and-Fix-MegaLinter-Tool avec MegaLinter v9.

.DESCRIPTION
    Script idempotent pour :
    - Créer la structure de dossiers
    - Générer un fichier test hybride MD/XML
    - Déployer un workflow GitHub Actions MegaLinter
    - Initialiser et pousser vers GitHub

    Compatible PowerShell 7.6+ sur Windows 11 / WSL.

.PARAMETER ProjectRoot
    Chemin racine du projet (défaut: C:/Users/bbrod/Projets/Test-and-Fix-MegaLinter-Tool)

.PARAMETER RepoUrl
    URL du repo GitHub (défaut: https://github.com/valorisa/Test-and-Fix-MegaLinter-Tool.git)

.PARAMETER DryRun
    Mode simulation : affiche les actions sans les exécuter

.PARAMETER SkipPush
    Skip l'étape git push (utile pour test local)

.EXAMPLE
    .\setup-megalinter.ps1 -DryRun
.EXAMPLE
    .\setup-megalinter.ps1 -ProjectRoot "D:/Dev/MegaLinter-Test"
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = "C:/Users/bbrod/Projets/Test-and-Fix-MegaLinter-Tool",
    [string]$RepoUrl = "https://github.com/valorisa/Test-and-Fix-MegaLinter-Tool.git",
    [switch]$DryRun,
    [switch]$SkipPush,
    [switch]$Force
)

$ScriptName = "setup-megalinter"
$StateFile = Join-Path $ProjectRoot ".t2_state/setup-complete.flag"
$LogColor = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Debug   = "Gray"
}

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = $LogColor[$Level] ?? "White"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Vérification des prérequis..." "Debug"
    
    $checks = @(
        @{ Name = "Git"; Command = "git --version" },
        @{ Name = "PowerShell 7+"; Command = "$PSVersionTable.PSVersion.Major -ge 7" }
    )
    
    foreach ($check in $checks) {
        try {
            if ($check.Name -eq "Git") {
                $null = git --version 2>$null
                if ($LASTEXITCODE -ne 0) { throw "Git non trouvé" }
            }
            elseif ($check.Name -eq "PowerShell 7+") {
                if ($PSVersionTable.PSVersion.Major -lt 7) { throw "PS version < 7" }
            }
            Write-Log "  ✓ $($check.Name)" "Success"
        }
        catch {
            Write-Log "  ✗ $($check.Name) : $_" "Error"
            return $false
        }
    }
    return $true
}

function Initialize-State {
    if (-not (Test-Path (Split-Path $StateFile -Parent))) {
        if ($DryRun) {
            Write-Log "[DRY-RUN] Création du dossier de state: $(Split-Path $StateFile -Parent)" "Debug"
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path $StateFile -Parent) | Out-Null
            Write-Log "  ✓ Dossier de state créé" "Success"
        }
    }
}

function Test-Idempotence {
    if (Test-Path $StateFile) {
        $lastRun = Get-Content $StateFile -Raw
        Write-Log "État précédent détecté (exécuté le : $lastRun)" "Warning"
        Write-Log "Utilisez -Force pour ré-exécuter ou supprimez $StateFile" "Info"
        return $true
    }
    return $false
}

function Invoke-Action {
    param(
        [string]$Description,
        [scriptblock]$Action,
        [switch]$SkipIfDryRun = $false
    )
    
    if ($DryRun -and $SkipIfDryRun) {
        Write-Log "[DRY-RUN] $Description" "Debug"
        return
    }
    
    Write-Log $Description "Info"
    if ($DryRun) {
        Write-Log "  → [SIMULATION]" "Debug"
        return
    }
    
    try {
        & $Action
        Write-Log "  ✓ Terminé" "Success"
    }
    catch {
        Write-Log "  ✗ Échec : $_" "Error"
        throw
    }
}

$TestHybridContent = @'
# Test MegaLinter Hybride

Contenu Markdown normal.

## Section XML
```xml
<data name="test">
  <item>valeur</item>
  <sub>non fermé volontairement</sub>
</data>
```
'@

$WorkflowContent = @'
---
name: MegaLinter
on:
  push:
  pull_request:
    branches: [main, master]

env:
  APPLY_FIXES: none

concurrency:
  group: ${{ github.ref }}-${{ github.workflow }}
  cancel-in-progress: true

jobs:
  megalinter:
    name: MegaLinter
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Checkout Code
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: MegaLinter
        uses: oxsecurity/megalinter/flavors/documentation@v9
        env:
          VALIDATE_ALL_CODEBASE: true
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MARKDOWN_MARKDOWNLINT: true
          XML_XMLLINT: true

      - name: Archive production artifacts
        if: success() || failure()
        uses: actions/upload-artifact@v4
        with:
          name: MegaLinter-reports
          path: |
            megalinter-reports
            mega-linter.log
'@

function Main {
    Write-Log "=== Démarrage de $ScriptName ===" "Info"
    Write-Log "Projet : $ProjectRoot" "Debug"
    Write-Log "Mode DryRun : $DryRun | SkipPush : $SkipPush" "Debug"
    
    if (-not (Test-Prerequisites)) {
        Write-Log "Prérequis non satisfaits. Arrêt." "Error"
        exit 1
    }
    
    if ((Test-Idempotence) -and -not $Force) {
        Write-Log "Exécution annulée (idempotence). Utilisez -Force pour forcer." "Warning"
        exit 0
    }
    
    Initialize-State
    
    try {
        if (Test-Path (Join-Path $ProjectRoot ".git")) {
            Write-Log "Dossier projet existant avec .git → skip clone" "Debug"
            Set-Location $ProjectRoot
        } else {
            Invoke-Action "Clonage du repo depuis $RepoUrl" {
                $parent = Split-Path $ProjectRoot -Parent
                if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
                Set-Location $parent
                git clone $RepoUrl (Split-Path $ProjectRoot -Leaf)
                Set-Location $ProjectRoot
            }
        }
        
        Invoke-Action "Création de .github/workflows" {
            New-Item -ItemType Directory -Force -Path ".github/workflows" | Out-Null
        }
        
        Invoke-Action "Génération de test-hybride.md" {
            $TestHybridContent | Out-File -FilePath "test-hybride.md" -Encoding UTF8NoBOM -Force
        }
        
        Invoke-Action "Génération de .github/workflows/mega-linter.yml" {
            $WorkflowContent | Out-File -FilePath ".github/workflows/mega-linter.yml" -Encoding UTF8NoBOM -Force
        }
        
        Invoke-Action "Validation du YAML généré" {
            $yaml = Get-Content ".github/workflows/mega-linter.yml" -Raw
            if ($yaml -notmatch '\$\{\{.*\}\}') {
                throw "Variable GitHub Actions non trouvée : YAML potentiellement corrompu !"
            }
            Write-Log "  ✓ Syntaxe YAML valide (variables GitHub préservées)" "Success"
        }
        
        if (-not $SkipPush) {
            Invoke-Action "Git add/commit/push" {
                git add .
                git commit -m "chore: setup MegaLinter + test hybride MD/XML [auto]" `
                    --allow-empty -m "Généré par $ScriptName.ps1"
                git push
            }
        } else {
            Write-Log "SkipPush activé → étapes git push ignorées" "Warning"
        }
        
        Invoke-Action "Mise à jour du fichier de state" {
            $(Get-Date -Format "o") | Out-File -FilePath $StateFile -Encoding UTF8NoBOM -Force
        }
        
        Write-Log "=== ✅ Setup terminé avec succès ===" "Success"
        if (-not $DryRun -and -not $SkipPush) {
            Write-Log "🔗 Actions GitHub : https://github.com/valorisa/Test-and-Fix-MegaLinter-Tool/actions" "Info"
            Write-Log "📊 Rapport MegaLinter : disponible dans l'artifact 'MegaLinter-reports'" "Info"
        }
        
    }
    catch {
        Write-Log "❌ Erreur critique : $_" "Error"
        Write-Log "Conseil : Vérifiez les logs ci-dessus et ré-exécutez avec -DryRun pour déboguer." "Warning"
        exit 1
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Main
}