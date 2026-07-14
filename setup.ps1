param(
  [switch]$DryRun,
  [switch]$Reset,
  [switch]$Incremental,
  [switch]$Uninstall,
  [switch]$Doctor,
  [switch]$Help
)

# setup.ps1 — thin launcher.
#
# This script's ONLY job is to make sure a working Node.js is present, then
# hand off to the real installer (harness/scripts/setup.mjs). Every other
# concern (OpenCode install, MCP install, project config, skills, plugins,
# backup/retention, validate, uninstall, doctor) lives in exactly one place
# — the Node.js core — instead of being duplicated here and in setup.sh.

$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HarnessDir = Join-Path $RootDir 'harness'
$VersionsPath = Join-Path $RootDir 'versions.json'

function Ensure-NodePathContainsCommonLocations {
  $candidates = @(
    'C:\Program Files\nodejs',
    (Join-Path $env:LOCALAPPDATA 'Programs\nodejs'),
    (Join-Path $env:APPDATA 'npm')
  )
  foreach ($dir in $candidates) {
    if ((Test-Path (Join-Path $dir 'node.exe')) -and ($env:PATH -notlike "*$dir*")) {
      $env:PATH = "$dir;$env:PATH"
    }
  }
}

function Ensure-Node {
  $versions = Get-Content $VersionsPath -Raw | ConvertFrom-Json
  $requiredMajor = [int]$versions.node.major

  Ensure-NodePathContainsCommonLocations
  $node = Get-Command node -ErrorAction SilentlyContinue
  if ($node) {
    $raw = node -p "process.versions.node"
    $major = [int]($raw.Split('.')[0])
    if ($major -ge $requiredMajor) {
      return
    }
  }

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id $versions.node.wingetId --accept-source-agreements --accept-package-agreements
  } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install $versions.node.chocoPackage -y
  } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop install $versions.node.scoopPackage
  } elseif (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm install $requiredMajor
    nvm use $requiredMajor
  } else {
    throw "Node.js $requiredMajor+ is required for this setup. Install Node.js $requiredMajor+ and re-run setup."
  }

  Start-Sleep -Seconds 2
  Ensure-NodePathContainsCommonLocations

  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    throw "Node.js install completed, but node is still unavailable. Restart PowerShell and re-run setup."
  }

  $raw = node -p "process.versions.node"
  $major = [int]($raw.Split('.')[0])
  if ($major -lt $requiredMajor) {
    throw "Node.js $requiredMajor+ is required for this setup. Current version: $raw"
  }
}

Ensure-Node

$scriptArgs = @()
if ($DryRun) { $scriptArgs += '--dry-run' }
if ($Reset) { $scriptArgs += '--reset' }
if ($Incremental) { $scriptArgs += '--incremental' }
if ($Uninstall) { $scriptArgs += '--uninstall' }
if ($Doctor) { $scriptArgs += '--doctor' }
if ($Help) { $scriptArgs += '--help' }

& node (Join-Path $HarnessDir 'scripts\setup.mjs') @scriptArgs
exit $LASTEXITCODE
