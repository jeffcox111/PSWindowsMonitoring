
#$headers = @{"User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36"}

$userAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
$headers = @{authority= "l.evidon.com"
method = "GET"
path = "https://downdetector.com/status/rocket-league"
scheme = "https"
accept = "application/xml"
acceptencoding = "gzip, deflate, br"
acceptlanguage = "en-US,en;q=0.9"
cachecontrol = "no-cache"
pragma = "no-cache"
referer = "https://downdetector.com/"
useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36" 
}

$HTML = Invoke-WebRequest 'https://downdetector.com/status/rocket-league' -UserAgent $userAgent -Headers $headers
$HTML -match 'User reports indicate no current problems at Rocket League'