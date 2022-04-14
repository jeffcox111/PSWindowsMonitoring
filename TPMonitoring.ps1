##DEPRECATED##
#schedule this script to run every 5 minutes to work with SQL procs and tables
##/DEPRECATED##

#load supporting classes and functions
. .\MonitoringChecks.ps1
. .\SupportFunctions.ps1








function Run-MonitoringChecks ($LogToDB = 0, $SendEmail = 0)
{
    $messages = New-Object Collections.Generic.List[LogEntry]

    #Run monitoring checks...
    Check-ServerIsOnline google.com | % { Append-ErrorList $_ $messages }
    #TODO: ADD ALL THE FUNCTION CALLS YOU WANT TO RUN HEAR
    #THE FORMAT SHOULD ALWAYS BE LIKE THE LINE ABOVE.
    #FOR EXAMPLE:
    #Check-SOMETHING [thing to check [and parameters]] | % { Append-ErrorList $_ $messages }

    #log to DB
    if($LogToDB -gt 0)
    {
       $messages | % { Update-Database $_ }

       if($messages.Count -eq 0)
       {
            $heartBeat = new-object LogEntry
            $heartBeat.TimeStamp = [DateTime]::Now
            $heartBeat.IsHeartbeat = 1
            Update-Database $heartBeat
       }
    }

    #email error messaging
    if($SendEmail -gt 0)
    {
        Send-SummaryEmail($messages)
    }

} 


##DEPRECATED##
#Check-DBOnline [DBNAME]
##DEPRECATED##

Run-MonitoringChecks -LogToDB 0 -SendEmail 0

