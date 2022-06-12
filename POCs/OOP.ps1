class LogEntry 
{
    [string]$ServerName
    [string]$MonitoringType
    [System.DateTime]$TimeStamp

}


$testlog = New-Object LogEntry
$testlog.ServerName = "testserver"
$testlog.MonitoringType = "Test-ServerIsOnline"
$testlog.TimeStamp = [System.DateTime]::Now

$testlog