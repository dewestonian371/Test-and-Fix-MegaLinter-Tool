#Requires -Modules Pester

BeforeAll {
    $ScriptPath   = "$PSScriptRoot/setup-megalinter.ps1"
    $TestBase     = Join-Path ([System.IO.Path]::GetTempPath()) "MegaLinter-Pester-$(Get-Random)"
    $ProjectRoot  = Join-Path $TestBase "project"
    $RepoUrl      = "https://github.com/test/fake-repo.git"
}

AfterAll {
    if (Test-Path $TestBase) { Remove-Item $TestBase -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "setup-megalinter.ps1 - Validation & Génération" {
    BeforeAll {
        New-Item -ItemType Directory -Force -Path $ProjectRoot | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot ".git") | Out-Null
    }

    It "Should exist and parse without syntax errors" {
        $ScriptPath | Should -Exist
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "Should generate expected files when run normally" {
        & $ScriptPath -ProjectRoot $ProjectRoot -RepoUrl $RepoUrl -SkipPush -Force | Out-Null

        Join-Path $ProjectRoot "test-hybride.md"          | Should -Exist
        Join-Path $ProjectRoot ".github/workflows/mega-linter.yml" | Should -Exist
    }

    It "Should preserve GitHub Actions expressions (no variable expansion)" {
        $yamlPath = Join-Path $ProjectRoot ".github/workflows/mega-linter.yml"
        $content  = Get-Content $yamlPath -Raw

        $content | Should -Match '\$\{\{ secrets\.GITHUB_TOKEN \}\}'
        $content | Should -Match 'oxsecurity/megalinter/flavors/documentation@v9'
        $content | Should -Not -Match '^\$\{'
    }

    It "Should use UTF8NoBOM encoding for generated files" {
        $files = @(
            (Join-Path $ProjectRoot ".github/workflows/mega-linter.yml"),
            (Join-Path $ProjectRoot "test-hybride.md")
        )

        foreach ($f in $files) {
            $bytes = [System.IO.File]::ReadAllBytes($f)
            $hasBom = ($bytes.Count -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
            $hasBom | Should -BeFalse -Because "$f ne doit pas contenir de BOM"
        }
    }

    It "Should support -DryRun without creating any files" {
        $dryDir = Join-Path $TestBase "dryrun"
        New-Item -ItemType Directory -Force -Path $dryDir | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $dryDir ".git") | Out-Null

        & $ScriptPath -ProjectRoot $dryDir -RepoUrl $RepoUrl -DryRun | Out-Null

        Test-Path (Join-Path $dryDir ".github") | Should -BeFalse
        Test-Path (Join-Path $dryDir "test-hybride.md") | Should -BeFalse
    }

    It "Should create idempotency state file" {
        $stateFile = Join-Path $ProjectRoot ".t2_state/setup-complete.flag"
        $stateFile | Should -Exist
        Get-Content $stateFile | Should -Not -BeNullOrEmpty
    }
}