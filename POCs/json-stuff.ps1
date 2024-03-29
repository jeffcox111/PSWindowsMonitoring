Add-Type -Language CSharp @"
public class LogEntry{
    public System.DateTime TimeStamp;
    public string Server;
    public string MonitorType;
    public string ErrorMessage;
    public bool IsHeartbeat;
}
"@;

$messages = New-Object Collections.Generic.List[LogEntry]

$m1 = New-Object LogEntry
$m1.Server = "192.168.1.1"
$m1.TimeStamp = [DateTime]::Now
$m1.MonitorType = "Monitor-ServerOnline"
$m1.ErrorMessage = "This server is offline"

$m2 = New-Object LogEntry
$m2.Server = "192.168.1.1"
$m2.TimeStamp = [DateTime]::Now
$m2.MonitorType = "Monitor-ServerOnline"
$m2.ErrorMessage = "This server is offline"

$m3 = New-Object LogEntry
$m3.Server = "192.168.1.1"
$m3.TimeStamp = [DateTime]::Now
$m3.MonitorType = "Monitor-ServerOnline"
$m3.ErrorMessage = "This server is offline"
$m3.IsHeartbeat = $true

$m4 = New-Object LogEntry
$m4.Server = "192.168.1.1"
$m4.TimeStamp = [DateTime]::Now
$m4.MonitorType = "Monitor-ServerOnline"
$m4.ErrorMessage = "This server is offline"

$m5 = New-Object LogEntry
$m5.Server = "192.168.1.1"
$m5.TimeStamp = [DateTime]::Now
$m5.MonitorType = "Monitor-ServerOnline"
$m5.ErrorMessage = "This server is offline"

$messages.Add($m1)
$messages.add($m2)
$messages.Add($m3)
$messages.add($m4)
$messages.Add($m5)

$jsonData = $messages | ConvertTo-Json | Out-File "mydata.json"

$reImportedMessages = New-Object Collections.Generic.List[LogEntry]

$reImportedMessages = Get-Content 'mydata.json' | Out-String | ConvertFrom-Json
#$reImportedMessages

$reImportedMessages | ? {$_.IsHeartbeat -eq $true} | % {$_}
