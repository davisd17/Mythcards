[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RemoteName,

    [Parameter(Mandatory = $true)]
    [string]$BucketName,

    [string]$SourcePath = "assets",
    [string]$DestinationPrefix = "assets"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    throw "rclone is required. Install it and configure a Cloudflare R2 remote before running this script."
}

$resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
$destination = "${RemoteName}:${BucketName}/${DestinationPrefix}"

Write-Host "Copying $resolvedSource to $destination"
rclone copy $resolvedSource $destination --checksum --create-empty-src-dirs --progress

if ($LASTEXITCODE -ne 0) {
    throw "rclone failed with exit code $LASTEXITCODE."
}

Write-Host "Upload complete. No remote files were deleted."
