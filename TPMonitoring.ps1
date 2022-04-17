#load supporting classes and functions
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1


function Run-MonitoringChecks ($SendEmail = 0)
{
    $messages = New-Object Collections.Generic.List[LogEntry]

    #TODO: replicate old SQL logic for Adding new Issues and Resolving existing issues
    
    
    #Run monitoring checks...
    Check-ServerIsOnline google.com | % { Append-ErrorList $_ $messages }
    Check-ServerIsOnline downdetector.com | % { Append-ErrorList $_ $messages }
    Check-Freespace localhost C: 50 | % { Append-ErrorList $_ $messages }
    #TODO: ADD ALL THE FUNCTION CALLS YOU WANT TO RUN HEAR
    #THE FORMAT SHOULD ALWAYS BE LIKE THE LINE ABOVE.
    #FOR EXAMPLE:
    #Check-SOMETHING [thing to check [and parameters]] | % { Append-ErrorList $_ $messages }

    
    #add heartbeat entry if there were no issues detected
    if($messages.Count -eq 0)
    {
        $heartBeat = new-object LogEntry
        $heartBeat.TimeStamp = [DateTime]::Now
        $heartBeat.IsHeartbeat = 1
        $messages.Add($heartBeat)
    }
    
    #log entries to json file
    $messages | ConvertTo-Json | Out-File "LogEntries.json" -Append
    
    
    #email error messaging
    if($SendEmail -gt 0)
    {
        Send-SummaryEmail($messages)
    }

} 

while($true)
{
    Run-MonitoringChecks -SendEmail 0

    for($x = 0; $x -le 300; $x++)
    {
        $percentComplete = ($x / 300) * 100
        Write-Progress -Activity "Time till next monitoring check run..." -Status "$percentComplete%" -PercentComplete $percentComplete
        Start-Sleep -Seconds 1
    }

}
