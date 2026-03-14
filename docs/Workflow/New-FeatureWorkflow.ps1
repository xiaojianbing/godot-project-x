[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]*$')]
    [string]$Slug,

    [Parameter()]
    [string]$FeatureName,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workflowRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$handoffTemplate = Join-Path $workflowRoot 'Handoffs\_Template.md'
$sessionTemplate = Join-Path $workflowRoot 'Sessions\_Template.md'
$handoffTarget = Join-Path $workflowRoot "Handoffs\$Slug.md"
$sessionDir = Join-Path $workflowRoot "Sessions\$Slug"
$roles = @('producer', 'architect', 'developer', 'tester')
$displayName = if ([string]::IsNullOrWhiteSpace($FeatureName)) { $Slug } else { $FeatureName.Trim() }
$today = Get-Date -Format 'yyyy-MM-dd'

if (-not (Test-Path -LiteralPath $handoffTemplate)) {
    throw "Missing handoff template: $handoffTemplate"
}

if (-not (Test-Path -LiteralPath $sessionTemplate)) {
    throw "Missing session template: $sessionTemplate"
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Initialize-HandoffContent {
    $content = Get-Content -LiteralPath $handoffTemplate -Raw -Encoding UTF8
    $content = $content -replace '(?m)^- Name:$', "- Name: $displayName"
    $content = $content -replace '(?m)^- Slug:$', "- Slug: $Slug"
    $content = $content -replace '(?m)^- Current Stage: `Producer` / `Architect` / `Developer` / `Tester`$', '- Current Stage: `Producer`'
    $content = $content -replace '(?m)^- Next Owner:$', '- Next Owner: Producer'
    return $content.TrimEnd() + [Environment]::NewLine
}

function Initialize-SessionContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Role
    )

    $content = Get-Content -LiteralPath $sessionTemplate -Raw -Encoding UTF8
    $content = $content -replace '(?m)^- Role:$', "- Role: $Role"
    $content = $content -replace '(?m)^- Feature:$', "- Feature: $displayName"
    $content = $content -replace '(?m)^- Slug:$', "- Slug: $Slug"
    $content = $content -replace '(?m)^- Date:$', "- Date: $today"
    return $content.TrimEnd() + [Environment]::NewLine
}

if ((Test-Path -LiteralPath $handoffTarget) -and -not $Force) {
    throw "Handoff already exists: $handoffTarget`nUse -Force to overwrite generated files."
}

if ($PSCmdlet.ShouldProcess($handoffTarget, 'Create handoff file')) {
    Write-Utf8File -Path $handoffTarget -Content (Initialize-HandoffContent)
}

if (-not (Test-Path -LiteralPath $sessionDir)) {
    if ($PSCmdlet.ShouldProcess($sessionDir, 'Create session directory')) {
        New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
    }
}

$createdFiles = @($handoffTarget)

foreach ($role in $roles) {
    $sessionPath = Join-Path $sessionDir ("$role.md")

    if ((Test-Path -LiteralPath $sessionPath) -and -not $Force) {
        throw "Session already exists: $sessionPath`nUse -Force to overwrite generated files."
    }

    if ($PSCmdlet.ShouldProcess($sessionPath, 'Create role session file')) {
        Write-Utf8File -Path $sessionPath -Content (Initialize-SessionContent -Role $role)
    }

    $createdFiles += $sessionPath
}

Write-Host 'Workflow scaffold ready:'
foreach ($path in $createdFiles) {
    Write-Host "- $path"
}
