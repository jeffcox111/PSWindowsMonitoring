Add-Type -Language CSharp @"
public class LogEntry{
    public System.DateTime TimeStamp;
    public string Server;
    public string MonitorType;
    public string ErrorMessage;
    public bool IsHeartbeat;
}
"@;

Add-Type -Language CSharp @"
public class Issue{
    public string Server;
    public string MonitoringType;
    public string ErrorMessage;
    public System.DateTime StartTime;
    public System.DateTime EndTime;
    public bool SendStartEmail;
    public book SendEndEmail;
}
"@;

$messages = New-Object Collections.Generic.List[LogEntry]

$m1 = New-Object LogEntry
$m1.Server = "192.168.1.1"
$m1.TimeStamp = [DateTime]::Now
$m1.MonitorType = "Check-ServerOnline"
$m1.ErrorMessage = "This server is offline"

$m2 = New-Object LogEntry
$m2.Server = "192.168.1.1"
$m2.TimeStamp = [DateTime]::Now
$m2.MonitorType = "Check-ServerOnline"
$m2.ErrorMessage = "This server is offline"

$m3 = New-Object LogEntry
$m3.Server = "192.168.1.1"
$m3.TimeStamp = [DateTime]::Now
$m3.MonitorType = "Check-ServerOnline"
$m3.ErrorMessage = "This server is offline"

$m4 = New-Object LogEntry
$m4.Server = "192.168.1.1"
$m4.TimeStamp = [DateTime]::Now
$m4.MonitorType = "Check-ServerOnline"
$m4.ErrorMessage = "This server is offline"

$m5 = New-Object LogEntry
$m5.Server = "192.168.1.1"
$m5.TimeStamp = [DateTime]::Now
$m5.MonitorType = "Check-ServerOnline"
$m5.ErrorMessage = "This server is offline"

$messages.Add($m1)
$messages.add($m2)
$messages.Add($m3)
$messages.add($m4)
$messages.Add($m5)

$jsonData = $messages | ConvertTo-Json

$reloadedMessages = New-Object Collections.Generic.List[LogEntry]

$reloadedMessages = ConvertFrom-Json $jsonData
$reloadedMessages
