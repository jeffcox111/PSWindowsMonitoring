#load supporting classes and functions
. .\Define-Classes.ps1
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1


function Run-MonitoringChecks ($notifications = $true)
{
    #define container for all logged messages
    $messages = New-Object Collections.Generic.List[LogEntry]

    #Run monitoring checks...
    #This is where you come in!  Add lines below this comment block to check on the things you want to monitor.
    #The format should always be like the example below, including the pipe and everything after it:
    #Check-SOMETHING [thing to check [and parameters]] | % { Append-ErrorList $_ $messages }
    
    Check-ServerIsOnline google.com | % { Append-ErrorList $_ $messages }
    Check-Freespace localhost C: 100 | % { Append-ErrorList $_ $messages }
  
    #process all logged messages
    Process-LogEntries $messages

} 

$settings = Load-Settings

while($true)
{
    Run-MonitoringChecks -SendEmail 0
    $sleepSeconds = $settings.UpdateIntervalMinutes * 60
    for($x = 0; $x -le $sleepSeconds; $x++)
    {
        $percentComplete = ($x / $sleepSeconds) * 100
        Write-Progress -Activity "Time till next monitoring check run..." -Status "$percentComplete%" -PercentComplete $percentComplete
        Start-Sleep -Seconds 1
    }
}
