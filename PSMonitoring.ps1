#load supporting classes and functions
. .\Define-Classes.ps1
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1
function Run-MonitoringChecks ($notifications = $true)
{    
    #Run monitoring checks...
    #This is where you come in!  
    #Add lines below this comment block to check on the things you want to monitor.
    Check-ServerIsOnline google.com 
    Check-Freespace localhost C: 100 
} 

$settings = Load-Settings
$messages = New-Object Collections.Generic.List[LogEntry]
Run-MonitoringProcess


