param(
  [switch]$DryRun,
  [switch]$Reset,
  [switch]$Incremental,
  [switch]$Uninstall,
  [switch]$Doctor,
  [switch]$Help
)

if ($Help) {
  Write-Host @"
Usage: .\setup.ps1 [options]

Options:
  -DryRun       Print actions without executing them.
  -Incremental  Update in place, keep global OpenCode state (default).
  -Reset        Wipe global OpenCode config/data/cache before rebuild.
  -Uninstall    Restore the newest backup and exit.
  -Doctor       Run diagnostics and exit.
  -Help         Show this message.
"@
  exit 0
}

if ($Reset -and $Incremental) {
  Write-Error 'Choose -Reset OR -Incremental, not both.'
  exit 1
}

$Mode = if ($Reset) { 'reset' } else { 'incremental' }

$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HarnessDir = Join-Path $RootDir 'harness'
$StackManifestPath = Join-Path $RootDir 'stack\manifest.json'
$VersionsPath = Join-Path $RootDir 'versions.json'

# ── helper: wrap destructive actions for dry-run ──────────────────────────────
function Invoke-Action {
  param([string]$Description, [scriptblock]$Action)
  if ($DryRun) {
    Write-Host "[dry-run] $Description"
  } else {
    & $Action
  }
}

# ── helper: prompt before writing to User PATH ────────────────────────────────
function Ensure-PathContains {
  param([string]$Dir)

  if ([string]::IsNullOrWhiteSpace($Dir) -or -not (Test-Path $Dir)) {
    return
  }

  $pathEntries = ($env:PATH -split ';') | Where-Object { $_ -ne '' }
  if ($pathEntries -notcontains $Dir) {
    $env:PATH = if ([string]::IsNullOrWhiteSpace($env:PATH)) { $Dir } else { "$Dir;$env:PATH" }
  }

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $userEntries = @()
  if (-not [string]::IsNullOrWhiteSpace($userPath)) {
    $userEntries = ($userPath -split ';') | Where-Object { $_ -ne '' }
  }

  if ($userEntries -notcontains $Dir) {
    if (-not $DryRun) {
      $answer = Read-Host "Add '$Dir' to your permanent User PATH? [y/N]"
      if ($answer -match '^[Yy]$') {
        $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $Dir } else { "$userPath;$Dir" }
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
      }
    } else {
      Write-Host "[dry-run] would prompt to add '$Dir' to User PATH"
    }
  }
}

function Read-JsonObject {
  param([string]$Path)
  return Get-Content $Path -Raw | ConvertFrom-Json
}

function Replace-TemplateTokens {
  param(
    [Parameter(Mandatory = $true)] $Value,
    [Parameter(Mandatory = $true)][hashtable]$Tokens
  )

  if ($null -eq $Value) {
    return $null
  }

  if ($Value -is [string]) {
    $result = $Value
    foreach ($key in $Tokens.Keys) {
      $result = $result.Replace($key, $Tokens[$key])
    }
    return $result
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $items = @()
    foreach ($item in $Value) {
      $items += @(Replace-TemplateTokens -Value $item -Tokens $Tokens)
    }
    return ,$items
  }

  if ($Value.PSObject -and $Value.PSObject.Properties.Count -gt 0) {
    foreach ($property in $Value.PSObject.Properties) {
      $property.Value = Replace-TemplateTokens -Value $property.Value -Tokens $Tokens
    }
  }

  return $Value
}

function Ensure-NodePathContainsCommonLocations {
  $candidates = @(
    'C:\Program Files\nodejs',
    (Join-Path $env:LOCALAPPDATA 'Programs\nodejs'),
    (Join-Path $HOME 'AppData\Local\Programs\nodejs'),
    (Join-Path $env:APPDATA 'npm')
  )

  foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir 'node.exe')) {
      Ensure-PathContains $dir
    }
  }
}

function Ensure-NpmGlobalBinInPath {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    return
  }

  try {
    $prefix = (npm prefix -g).Trim()
    if (-not [string]::IsNullOrWhiteSpace($prefix)) {
      Ensure-PathContains $prefix
    }
  } catch {
  }
}

function Ensure-OpenCodePathContainsCommonLocations {
  $candidates = @(
    'C:\ProgramData\chocolatey\bin',
    (Join-Path $env:APPDATA 'npm')
  )

  foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir 'opencode.exe')) {
      Ensure-PathContains $dir
    }
  }
}

function Resolve-OpenCodeCommand {
  Ensure-OpenCodePathContainsCommonLocations

  $cmd = Get-Command opencode -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $candidates = @(
    'C:\ProgramData\chocolatey\bin\opencode.exe',
    (Join-Path $env:APPDATA 'npm\opencode.cmd'),
    (Join-Path $env:APPDATA 'npm\opencode')
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      Ensure-PathContains (Split-Path -Parent $candidate)
      $cmd = Get-Command opencode -ErrorAction SilentlyContinue
      if ($cmd) {
        return $cmd.Source
      }
      return $candidate
    }
  }

  return $null
}

function Get-OpenCodeDiagnostic {
  $path = Resolve-OpenCodeCommand
  if (-not $path) {
    return 'opencode command not found'
  }

  $attempts = @('--help', '--version')
  $details = @("resolved command: $path")

  foreach ($arg in $attempts) {
    try {
      $output = & $path $arg 2>&1 | Out-String
      $exitCode = $LASTEXITCODE
      if ($exitCode -eq 0) {
        return $null
      }
      $trimmed = $output.Trim()
      if ([string]::IsNullOrWhiteSpace($trimmed)) {
        $trimmed = '<no output>'
      }
      $details += "${arg} exit code: $exitCode"
      $details += $trimmed
    } catch {
      $details += "${arg} threw: $($_.Exception.Message)"
    }
  }

  return ($details -join "`n")
}

function Test-OpenCodeRunnable {
  return [string]::IsNullOrWhiteSpace((Get-OpenCodeDiagnostic))
}

function Resolve-OpenCodeDesktopPath {
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'OpenCode\OpenCode.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\OpenCode\OpenCode.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\opencode\OpenCode.exe'),
    (Join-Path $env:ProgramFiles 'OpenCode\OpenCode.exe'),
    (Join-Path $env:ProgramFiles 'opencode\OpenCode.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'OpenCode\OpenCode.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'opencode\OpenCode.exe')
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  $searchRoots = @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ -and (Test-Path $_) }
  foreach ($root in $searchRoots) {
    $match = Get-ChildItem -Path $root -Filter 'OpenCode.exe' -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match 'OpenCode|opencode' } |
      Select-Object -First 1
    if ($match) {
      return $match.FullName
    }
  }

  return $null
}

function Install-OpenCodeDesktop {
  $existing = Resolve-OpenCodeDesktopPath
  if ($existing) {
    Write-Host "OpenCode desktop already installed ($existing)"
    return
  }

  $versions = Read-JsonObject $VersionsPath
  $arch = if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
  $asset = $versions.opencode.desktop.windows.$arch
  $version = $versions.opencode.desktop.version
  $url = "https://github.com/anomalyco/opencode/releases/download/v$version/$asset"
  $installerPath = Join-Path $env:TEMP $asset

  Invoke-Action "Download and install OpenCode desktop ($asset)" {
    Write-Host "Installing OpenCode desktop ($asset)"
    Invoke-WebRequest -Uri $url -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList '/S' -Wait
    Remove-Item -Force $installerPath -ErrorAction SilentlyContinue

    $installed = Resolve-OpenCodeDesktopPath
    if (-not $installed) {
      throw 'OpenCode desktop install completed, but the desktop app was not found in the expected Windows install locations.'
    }

    Write-Host "OpenCode desktop installed ($installed)"
  }
}

function Assert-NodeVersion {
  Ensure-NodePathContainsCommonLocations
  $versions = Read-JsonObject $VersionsPath
  $requiredMajor = [int]$versions.node.major

  $node = Get-Command node -ErrorAction SilentlyContinue
  if ($node) {
    $raw = node -p "process.versions.node"
    $major = [int]($raw.Split('.')[0])
    if ($major -ge $requiredMajor) {
      Write-Host "node version ok ($raw)"
      return
    }
  }

  if ($DryRun) {
    Write-Host "[dry-run] node $requiredMajor+ not satisfied; would install via winget/choco/scoop/nvm"
    return
  }

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id $versions.node.wingetId --accept-source-agreements --accept-package-agreements
    Start-Sleep -Seconds 2
    Ensure-NodePathContainsCommonLocations
  } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install $versions.node.chocoPackage -y
    Start-Sleep -Seconds 2
    Ensure-NodePathContainsCommonLocations
  } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop install $versions.node.scoopPackage
    Start-Sleep -Seconds 2
    Ensure-NodePathContainsCommonLocations
  } elseif (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm install $requiredMajor
    nvm use $requiredMajor
    Start-Sleep -Seconds 2
    Ensure-NodePathContainsCommonLocations
  } else {
    throw "Node.js $requiredMajor+ is required for this setup. Install Node.js $requiredMajor+ and re-run setup."
  }

  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    throw "Node.js install completed, but node is still unavailable. Restart PowerShell and re-run setup."
  }

  $raw = node -p "process.versions.node"
  $major = [int]($raw.Split('.')[0])
  if ($major -lt $requiredMajor) {
    throw "Node.js $requiredMajor+ is required for this setup. Current version: $raw"
  }

  Write-Host "node version ok ($raw)"
}

# ── helper: backup retention (keep newest N, prune older) ─────────────────────
function Invoke-BackupRetention {
  param([string]$BackupRoot)
  if (-not (Test-Path $BackupRoot)) { return }
  $keep = [int]($env:HARNESS_BACKUP_RETENTION ?? '5')
  $dirs = Get-ChildItem -Path $BackupRoot -Directory | Sort-Object Name -Descending
  if ($dirs.Count -gt $keep) {
    $toRemove = $dirs | Select-Object -Skip $keep
    foreach ($dir in $toRemove) {
      Write-Host "[backup retention] removing old backup: $($dir.FullName)" -ForegroundColor DarkGray
      Invoke-Action "remove old backup $($dir.FullName)" { Remove-Item -Recurse -Force $dir.FullName }
    }
  }
}

function Write-ProjectConfig {
  $envFile = Join-Path $HarnessDir '.env.team'
  if (-not (Test-Path $envFile)) {
    Invoke-Action "copy .env.team.example -> .env.team" {
      Copy-Item (Join-Path $HarnessDir 'templates\.env.team.example') $envFile
    }
  }

  $template = Read-JsonObject (Join-Path $HarnessDir 'templates\opencode.template.jsonc')
  $manifest = Read-JsonObject $StackManifestPath
  $globalTemplate = Read-JsonObject (Join-Path $HarnessDir 'templates\opencode.template.jsonc')

  $mcp = [ordered]@{}
  foreach ($property in $manifest.sharedMcp.PSObject.Properties) {
    $value = $property.Value
    $config = [ordered]@{ type = $value.type }
    if ($null -ne $value.command) { $config['command'] = @($value.command) }
    if ($null -ne $value.url) { $config['url'] = $value.url }
    if ($null -ne $value.enabledByDefault) { $config['enabled'] = [bool]$value.enabledByDefault }
    if ($null -ne $value.oauth -and [bool]$value.oauth) { $config['oauth'] = @{} }
    $mcp[$property.Name] = $config
  }
  $globalTemplate | Add-Member -NotePropertyName mcp -NotePropertyValue $mcp -Force
  $globalTemplate | Add-Member -NotePropertyName plugin -NotePropertyValue @($manifest.opencode.plugins) -Force

  Invoke-Action "write opencode.jsonc" {
    ($template | ConvertTo-Json -Depth 20) + "`n" | Set-Content -Path (Join-Path $RootDir 'opencode.jsonc')
  }

  $globalOpenCodeDir = if ($env:OPENCODE_CONFIG_DIR) { $env:OPENCODE_CONFIG_DIR } else { Join-Path $HOME '.config\opencode' }
  $globalOpenCodeStateDirs = @(
    @{ path = $globalOpenCodeDir; name = 'config' },
    @{ path = (Join-Path $env:APPDATA 'opencode'); name = 'appdata' },
    @{ path = (Join-Path $env:LOCALAPPDATA 'opencode'); name = 'localappdata' },
    @{ path = (Join-Path $HOME '.local\share\opencode'); name = 'localshare' }
  )
  $globalBackupRoot = Join-Path $HOME '.config\opencode-harness-backups'
  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $globalBackupDir = Join-Path $globalBackupRoot $timestamp

  foreach ($entry in $globalOpenCodeStateDirs) {
    if (Test-Path $entry.path) {
      Invoke-Action "backup $($entry.path) -> $globalBackupDir\$($entry.name)" {
        New-Item -ItemType Directory -Force -Path $globalBackupRoot | Out-Null
        New-Item -ItemType Directory -Force -Path $globalBackupDir | Out-Null
        Copy-Item -Recurse $entry.path (Join-Path $globalBackupDir $entry.name)
      }
      if ($Mode -eq 'reset') {
        Invoke-Action "remove $($entry.path) (reset mode)" {
          Remove-Item -Recurse -Force $entry.path
        }
      }
    }
  }

  Invoke-BackupRetention $globalBackupRoot

  Invoke-Action "create $globalOpenCodeDir" {
    New-Item -ItemType Directory -Force -Path $globalOpenCodeDir | Out-Null
  }
  Invoke-Action "write global opencode.json" {
    ($globalTemplate | ConvertTo-Json -Depth 20) + "`n" | Set-Content -Path (Join-Path $globalOpenCodeDir 'opencode.json')
  }

  $projectOpenCode = Join-Path $RootDir '.opencode'
  $projectSkills = Join-Path $projectOpenCode 'skills'
  $globalSkills = Join-Path $globalOpenCodeDir 'skills'
  Invoke-Action "create skills dirs" {
    New-Item -ItemType Directory -Force -Path $projectSkills | Out-Null
    New-Item -ItemType Directory -Force -Path $globalSkills | Out-Null
  }

  Invoke-Action "clear existing project skills" {
    if (Test-Path $projectSkills) {
      Get-ChildItem -Path $projectSkills | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
  Invoke-Action "clear existing global skills" {
    if (Test-Path $globalSkills) {
      Get-ChildItem -Path $globalSkills | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  foreach ($sourceRel in $manifest.opencode.projectSkillsSources) {
    $source = Join-Path $RootDir $sourceRel
    Get-ChildItem -Path $source -Directory | ForEach-Object {
      $target = Join-Path $projectSkills $_.Name
      Invoke-Action "copy project skill $($_.Name)" { Copy-Item -Recurse $_.FullName $target }
    }
  }

  foreach ($sourceRel in $manifest.opencode.globalSkillsSources) {
    $source = Join-Path $RootDir $sourceRel
    Get-ChildItem -Path $source -Directory | ForEach-Object {
      $target = Join-Path $globalSkills $_.Name
      Invoke-Action "copy global skill $($_.Name)" { Copy-Item -Recurse $_.FullName $target }
    }
  }

  if (-not $DryRun -and (Test-Path $globalBackupDir)) {
    Write-Host "backed up prior global OpenCode state to $globalBackupDir"
  }
}

function Install-McpDeps {
  $versions = Read-JsonObject $VersionsPath
  Ensure-NpmGlobalBinInPath
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    if (-not (Get-Command context-mode -ErrorAction SilentlyContinue)) {
      Invoke-Action "npm install -g context-mode@$($versions.mcp.'context-mode')" {
        npm install -g ("context-mode@" + $versions.mcp.'context-mode')
      }
    }
    if (-not (Get-Command context7-mcp -ErrorAction SilentlyContinue)) {
      Invoke-Action "npm install -g @upstash/context7-mcp@$($versions.mcp.'context7-mcp')" {
        npm install -g ("@upstash/context7-mcp@" + $versions.mcp.'context7-mcp')
      }
    }
    Ensure-NpmGlobalBinInPath
    return
  }

  if (-not (Get-Command context-mode -ErrorAction SilentlyContinue)) {
    throw 'context-mode is required and npm is unavailable to install it.'
  }
  if (-not (Get-Command context7-mcp -ErrorAction SilentlyContinue)) {
    throw 'context7-mcp is required and npm is unavailable to install it.'
  }
}

function Validate-Setup {
  $requiredCommands = @('opencode', 'context-mode', 'context7-mcp')
  foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
      throw "Missing required command: $cmd"
    }
  }

  if (-not (Test-OpenCodeRunnable)) {
    $diagnostic = Get-OpenCodeDiagnostic
    throw ("Installed command failed to run: opencode`n" + $diagnostic)
  }

  foreach ($cmd in @('context-mode', 'context7-mcp')) {
    try {
      & $cmd --help *> $null
      if ($LASTEXITCODE -ne 0) {
        & $cmd --version *> $null
      }
    } catch {
      throw "Installed command failed to run: $cmd"
    }
  }

  $requiredPaths = @(
    (Join-Path $RootDir 'opencode.jsonc'),
    (Join-Path $RootDir '.opencode\skills\frontend-design\SKILL.md'),
    (Join-Path $HOME '.config\opencode\opencode.json'),
    (Join-Path $HOME '.config\opencode\skills\understand\SKILL.md')
  )

  foreach ($path in $requiredPaths) {
    if (-not (Test-Path $path)) {
      throw "Missing required path: $path"
    }
  }

  Get-Content (Join-Path $RootDir 'opencode.jsonc') -Raw | ConvertFrom-Json | Out-Null
  $globalConfig = Get-Content (Join-Path $HOME '.config\opencode\opencode.json') -Raw | ConvertFrom-Json
  if (-not $globalConfig.mcp) {
    throw 'Global OpenCode app bundle is missing MCP config.'
  }
  if (-not $globalConfig.plugin) {
    throw 'Global OpenCode app bundle is missing plugin config.'
  }

  Write-Host 'opencode installed'
  Write-Host 'context-mode installed'
  Write-Host 'context7-mcp installed'
  Write-Host 'required commands execute'
  Write-Host 'project config present'
  Write-Host 'core repo-managed OpenCode skills present'
  Write-Host 'global app bundle present'
}

function Install-OpenCode {
  $versions = Read-JsonObject $VersionsPath
  $existingPath = Resolve-OpenCodeCommand
  $existing = if ($existingPath) { Get-Command opencode -ErrorAction SilentlyContinue } else { $null }
  $needsRepair = $false
  if ($existingPath) {
    if (Test-OpenCodeRunnable) {
      Write-Host "opencode already installed ($existingPath)"
      return
    }
    Write-Host "opencode found but not runnable ($existingPath); reinstalling"
    $needsRepair = $true
  }

  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Invoke-Action "scoop install opencode" {
      if ($needsRepair) {
        scoop uninstall opencode *> $null
      }
      scoop install opencode
    }
    return
  }

  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Invoke-Action "choco install opencode" {
      if ($needsRepair) {
        choco install opencode --force -y
      } else {
        choco install opencode -y
      }
      Ensure-OpenCodePathContainsCommonLocations
    }
    return
  }

  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Invoke-Action "npm install -g opencode-ai@$($versions.opencode.npm)" {
      Ensure-NpmGlobalBinInPath
      if ($existing) {
        npm uninstall -g opencode-ai *> $null
      }
      npm install -g ("opencode-ai@" + $versions.opencode.npm)
      Ensure-NpmGlobalBinInPath
    }
    return
  }

  throw 'Unable to install OpenCode automatically on Windows. Install Scoop, Chocolatey, or npm first.'
}

# ── prereq check ──────────────────────────────────────────────────────────────
function Test-Prereqs {
  $versions = Read-JsonObject $VersionsPath
  $requiredMajor = [int]$versions.node.major
  $failed = $false

  $checks = @(
    @{ name = 'python'; test = { Get-Command python -ErrorAction SilentlyContinue } },
    @{ name = 'node';   test = {
      $n = Get-Command node -ErrorAction SilentlyContinue
      if (-not $n) { return $false }
      $raw = node -p "process.versions.node" 2>$null
      [int]($raw.Split('.')[0]) -ge $requiredMajor
    }},
    @{ name = 'npm';    test = { Get-Command npm -ErrorAction SilentlyContinue } },
    @{ name = 'curl';   test = { Get-Command curl -ErrorAction SilentlyContinue } }
  )

  foreach ($check in $checks) {
    $ok = & $check.test
    if (-not $ok) {
      Write-Error "Missing prerequisite: $($check.name). Install it and re-run setup."
      $failed = $true
    }
  }

  if ($failed) { exit 1 }
}

# ── uninstall ─────────────────────────────────────────────────────────────────
function Invoke-Uninstall {
  $backupRoot = Join-Path $HOME '.config\opencode-harness-backups'
  if (-not (Test-Path $backupRoot)) {
    Write-Error 'no backups found; nothing to uninstall'
    exit 1
  }

  $newest = Get-ChildItem -Path $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
  if (-not $newest) {
    Write-Error 'no backups found; nothing to uninstall'
    exit 1
  }

  $restoreMap = @(
    @{ name = 'config';     dest = Join-Path $HOME '.config\opencode' },
    @{ name = 'localshare'; dest = Join-Path $HOME '.local\share\opencode' },
    @{ name = 'appdata';    dest = Join-Path $env:APPDATA 'opencode' },
    @{ name = 'localappdata'; dest = Join-Path $env:LOCALAPPDATA 'opencode' }
  )

  foreach ($entry in $restoreMap) {
    $src = Join-Path $newest.FullName $entry.name
    if (Test-Path $src) {
      Invoke-Action "restore $($entry.dest) from $src" {
        if (Test-Path $entry.dest) { Remove-Item -Recurse -Force $entry.dest }
        Copy-Item -Recurse $src $entry.dest
        Write-Host "restored $($entry.dest)"
      }
    }
  }
}

# ── doctor ────────────────────────────────────────────────────────────────────
function Invoke-Doctor {
  $versions = Read-JsonObject $VersionsPath
  $allGreen = $true

  $tools = @(
    @{ name = 'python'; cmd = 'python' },
    @{ name = 'node';   cmd = 'node' },
    @{ name = 'npm';    cmd = 'npm' },
    @{ name = 'curl';   cmd = 'curl' }
  )
  foreach ($t in $tools) {
    if (Get-Command $t.cmd -ErrorAction SilentlyContinue) {
      Write-Host "[OK]   $($t.name) found: $((Get-Command $t.cmd).Source)"
    } else {
      Write-Host "[FAIL] $($t.name) not found"
      $allGreen = $false
    }
  }

  # version comparison
  foreach ($tool in @('opencode', 'context-mode', 'context7-mcp')) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
      Write-Host "[OK]   $tool installed: $($cmd.Source)"
    } else {
      Write-Host "[WARN] $tool not installed (required after setup)"
    }
  }

  # writable dirs
  $dirs = @(
    (Join-Path $HOME '.config\opencode'),
    (Join-Path $HOME '.local\share\opencode'),
    (Join-Path $HOME '.config\opencode-harness-backups')
  )
  foreach ($dir in $dirs) {
    if (Test-Path $dir) {
      Write-Host "[OK]   $dir exists"
    } else {
      Write-Host "[WARN] $dir does not exist yet (created on first setup)"
    }
  }

  if ($allGreen) { exit 0 } else { exit 1 }
}

# ── entry point ───────────────────────────────────────────────────────────────
Test-Prereqs

if ($Uninstall) {
  Invoke-Uninstall
  exit 0
}
if ($Doctor) {
  Invoke-Doctor
  exit 0
}

Install-OpenCode
Install-OpenCodeDesktop
Assert-NodeVersion
Install-McpDeps
Write-ProjectConfig
if (-not $DryRun) {
  Validate-Setup
} else {
  Write-Host "[dry-run] would run validation checks"
}

Write-Host ''
Write-Host 'Setup complete.'
Write-Host "Next: review $HarnessDir/.env.team, then run opencode from this repo root."
