#Import supporting classes and functions
. .\Define-Classes.ps1
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1
. .\User-CustomMonitoring.ps1

$settings = Import-Settings
$messages = New-Object Collections.Generic.List[LogEntry]
Invoke-MonitoringProcess


