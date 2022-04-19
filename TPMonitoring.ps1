#load supporting classes and functions
. .\Define-Classes.ps1
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1


function Run-MonitoringChecks ($SendEmail = 0)
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
    
    
    #add heartbeat entry if there were no issues detected
    if($messages.Count -eq 0)
    {
        $heartBeat = new-object LogEntry
        $heartBeat.TimeStamp = [DateTime]::Now
        $heartBeat.IsHeartbeat = 1
        $messages.Add($heartBeat)
    }
    
    #log entries to json file
    $resultMessages = New-Object Collections.Generic.List[LogEntry]
    $oldMessages = Load-LogEntries
    if($null -eq $oldMessages)
    {
        $messages | ConvertTo-Json | Out-File "LogEntries.json" 
    }
    else
    {        
        $oldmessages | % { $resultMessages.Add( $_ )}
        $messages | % { $resultMessages.add($_)}

        $resultMessages | ConvertTo-Json | Out-File "LogEntries.json"
    }
    
    
    #TODO: replicate old SQL logic for Adding new Issues and Resolving existing issues
    UpdateNewAndResolvedIssues $messages

    #email error messaging
    if($SendEmail -gt 0)
    {
        Send-SummaryEmail($messages)
    }

} 

$settings = Load-Settings

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
