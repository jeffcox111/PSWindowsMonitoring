#load supporting classes and functions
. .\Define-Classes.ps1
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1


function Run-MonitoringChecks ($notifications = $true)
{
    $messages = New-Object Collections.Generic.List[LogEntry]

    #TODO: ADD ALL THE FUNCTION CALLS YOU WANT TO RUN HEAR
    #THE FORMAT SHOULD ALWAYS BE LIKE THE LINE ABOVE.
    #FOR EXAMPLE:
    #Check-SOMETHING [thing to check [and parameters]] | % { Append-ErrorList $_ $messages }
    
    #Run monitoring checks...
    Check-ServerIsOnline google.com | % { Append-ErrorList $_ $messages }
    Check-ServerIsOnline downdetector.com | % { Append-ErrorList $_ $messages }
    Check-Freespace localhost C: 50 | % { Append-ErrorList $_ $messages }
    
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
