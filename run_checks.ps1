<#
    MyTemplate quality pipeline - Windows / PowerShell mirror of the Makefile.

    Runs the same checks as `make ci` and writes the same artifacts into ./reports
    so the pipeline is repeatable on Windows (where `make` is often unavailable).

    Usage:
        pwsh ./run_checks.ps1            # run the full pipeline (lint, security, test, ui-test)
        pwsh ./run_checks.ps1 -Task lint # run a single stage: lint|security|test|ui-test|report

    Exit code is non-zero if any gating check fails, so CI can rely on it.
#>
param(
    [ValidateSet('ci', 'lint', 'security', 'test', 'ui-test', 'report')]
    [string]$Task = 'ci'
)

$ErrorActionPreference = 'Stop'

# Prefer the project's virtualenv Python if present, else fall back to `python`.
$python = if (Test-Path './venv/Scripts/python.exe') { './venv/Scripts/python.exe' } else { 'python' }
$reports = 'reports'
$env:APPNAME_ENV = 'test'

# The prod-config test needs a live Redis; deselect it (see Makefile for details).
$deselect = @('--deselect', 'tests/test_config.py::TestConfig::test_prod_config')

$script:failed = $false

function New-ReportsDir {
    if (-not (Test-Path $reports)) { New-Item -ItemType Directory -Path $reports | Out-Null }
}

function Invoke-Lint {
    New-ReportsDir
    Write-Host '>> Ruff static analysis' -ForegroundColor Cyan
    & $python -m ruff check . --output-format=json --output-file="$reports/ruff.json"
    & $python -m ruff check .
    if ($LASTEXITCODE -ne 0) { $script:failed = $true }
}

function Invoke-Security {
    New-ReportsDir
    Write-Host '>> Bandit security scan' -ForegroundColor Cyan
    & $python -m bandit -r appname -c pyproject.toml -f json -o "$reports/bandit.json"
    & $python -m bandit -r appname -c pyproject.toml
    if ($LASTEXITCODE -ne 0) { $script:failed = $true }
}

function Invoke-BackendTests {
    New-ReportsDir
    Write-Host '>> Backend tests (pytest) + coverage' -ForegroundColor Cyan
    & $python -m pytest tests/ @deselect `
        --junitxml="$reports/junit-backend.xml" `
        --cov=appname `
        --cov-report=term-missing `
        --cov-report="xml:$reports/coverage.xml" `
        --cov-report="html:$reports/coverage_html"
    if ($LASTEXITCODE -ne 0) { $script:failed = $true }
}

function Invoke-UITests {
    New-ReportsDir
    Write-Host '>> UI tests (Playwright)' -ForegroundColor Cyan
    & $python -m pytest tests_ui/ -o testpaths=tests_ui `
        --junitxml="$reports/junit-ui.xml"
    if ($LASTEXITCODE -ne 0) { $script:failed = $true }
}

function Show-Report {
    Write-Host ''
    Write-Host "Artifacts in ./${reports}:" -ForegroundColor Green
    Write-Host "  Backend unit test report : ${reports}/junit-backend.xml"
    Write-Host "  UI test report           : ${reports}/junit-ui.xml"
    Write-Host "  Coverage (XML)           : ${reports}/coverage.xml"
    Write-Host "  Coverage (HTML)          : ${reports}/coverage_html/index.html"
    Write-Host "  Ruff lint report (JSON)  : ${reports}/ruff.json"
    Write-Host "  Bandit security (JSON)   : ${reports}/bandit.json"
    Write-Host ''
}

switch ($Task) {
    'lint'     { Invoke-Lint }
    'security' { Invoke-Security }
    'test'     { Invoke-BackendTests }
    'ui-test'  { Invoke-UITests }
    'report'   { Show-Report }
    'ci' {
        Invoke-Lint
        Invoke-Security
        Invoke-BackendTests
        Invoke-UITests
        Show-Report
    }
}

if ($script:failed) {
    Write-Host 'Pipeline finished with failures.' -ForegroundColor Red
    exit 1
}
Write-Host 'Pipeline finished successfully.' -ForegroundColor Green
