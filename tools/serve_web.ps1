# Serves the Web export (build/web) at http://localhost:<Port>/ for local testing.
# Sends the MIME types Godot's web build needs (application/wasm) and the
# cross-origin-isolation headers a threaded build would require. The current
# preset is thread-free, so they're only there so a later threaded build works too.
#
# Usage: tools/serve_web.ps1 [-Port 8060] [-Root build/web]   (Ctrl+C to stop)
param(
    [int]$Port = 8060,
    [string]$Root = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\web')
)
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path $Root).Path
$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript'
    '.wasm' = 'application/wasm'
    '.pck'  = 'application/octet-stream'
    '.png'  = 'image/png'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.json' = 'application/json'
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root at http://localhost:$Port/  (Ctrl+C to stop)"

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $res = $ctx.Response
        try {
            $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
            if ($rel -eq '') { $rel = 'index.html' }
            $path = [IO.Path]::GetFullPath((Join-Path $Root $rel))

            $res.Headers.Add('Cross-Origin-Opener-Policy', 'same-origin')
            $res.Headers.Add('Cross-Origin-Embedder-Policy', 'require-corp')
            $res.Headers.Add('Cache-Control', 'no-store')

            if ($path.StartsWith($Root) -and (Test-Path $path -PathType Leaf)) {
                $bytes = [IO.File]::ReadAllBytes($path)
                $type = $mime[[IO.Path]::GetExtension($path).ToLower()]
                $res.ContentType = if ($type) { $type } else { 'application/octet-stream' }
                $res.ContentLength64 = $bytes.Length
                if ($ctx.Request.HttpMethod -ne 'HEAD') {
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                Write-Host "200 $($ctx.Request.HttpMethod) /$rel"
            } else {
                $res.StatusCode = 404
                Write-Host "404 $($ctx.Request.HttpMethod) /$rel"
            }
        } catch {
            Write-Host "error serving $($ctx.Request.Url): $_" -ForegroundColor Red
        } finally {
            $res.Close()
        }
    }
} finally {
    $listener.Stop()
}
