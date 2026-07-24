try {
    $r = Invoke-WebRequest -Uri 'http://api-h5.tangdou.com/sample/share/main?vid=20000010517625' -Headers @{'Referer'='https://www.tangdoucdn.com/'; 'User-Agent'='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36'} -UseBasicParsing
    Write-Output "STATUS: $($r.StatusCode)"
    $content = $r.Content
    if ($content.Length -gt 2000) { $content = $content.Substring(0, 2000) }
    Write-Output $content
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
