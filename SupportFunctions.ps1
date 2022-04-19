function Send-SummaryEmail ([Collections.Generic.List[LogEntry]]$errorMessageCollection)
{
    if($errorMessageCollection.count -gt 0)
    {
        
        $SmtpClient = new-object system.net.mail.smtpClient
        $MailMessage = New-Object system.net.mail.mailmessage
        $SmtpClient.Host = ""
        $mailmessage.from = ("")
        $mailmessage.To.add("")
        $mailmessage.Subject = “PowerShell Monitoring System Alert”
        $body = $errorMessageCollection | % {$_.ErrorMessage + "`r`n"} 
        $mailmessage.Body = $body
        $smtpclient.Send($mailmessage)
    }
}

function Append-ErrorList([LogEntry] $logentry, [Collections.Generic.List[LogEntry]]$errorMessageCollection)
{
    if(-Not([string]::IsNullOrEmpty($logentry.ErrorMessage)))
    {
        $errorMessageCollection.Add($logentry)
    }
}

function Update-Database([LogEntry]$entry)
{
    $sqlConn = New-Object System.Data.SqlClient.SqlConnection
    $sqlConn.ConnectionString = "Data Source=;Initial Catalog=Monitoring;Persist Security Info=True;User ID=;Password="
    $sqlConn.Open()

    $sql = "INSERT INTO LogEntries (TimeStamp, Server, MonitoringType, ErrorMessage, IsHeartbeat) VALUES ('" + $entry.TimeStamp.ToString("yyyy-MM-dd HH:mm:ss:fff") + "', '" + $entry.Server + "', '" + $entry.MonitorType + "', '" + $entry.ErrorMessage + "', '" + $entry.IsHeartbeat + "')"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sql,$sqlConn)
    $rdr = $cmd.ExecuteNonQuery()
    
    $sqlconn.Close()
    
}

function Check-DBOnline([string]$Server)
{
    $logentry = new-object LogEntry
    $logentry = Check-ServerIsOnline $Server

    if($logentry -eq $null)
    {
        Set-Content dbstatus.txt 1
    }
    else
    {
        $status = Get-Content dbstatus.txt
        if($status -eq 1)
        {
            $errorMessageCollection = new-object Collections.Generic.List[LogEntry]
            $errorMessageCollection.Add($logentry)
            Send-SummaryEmail $errorMessageCollection 
            Set-Content dbstatus.txt 0
        }
    }
}

function Get-UpTime(){
    Get-WmiObject win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}   


function Get-LogonHistory{
    Param (
     [string]$Computer = 'localhost', #(Read-Host Remote computer name),
     [int]$Days = 10
     )
 
     $Result = @()
 
        $ELogs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-$Days) -ComputerName $Computer
 
     If ($ELogs)
     { 
        ForEach ($Log in $ELogs)
        { 
            If ($Log.InstanceId -eq 7001)
            { 
                $ET = "Logon"
            }
            ElseIf ($Log.InstanceId -eq 7002)
            { 
                $ET = "Logoff"
            }

            Else
            { 
                Continue
            }
   
            $Result += New-Object PSObject -Property @{
                Time = $Log.TimeWritten
                'Event Type' = $ET
                User = (New-Object System.Security.Principal.SecurityIdentifier $Log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])
            }
        }
         
        $Result | Select User, Time | Sort Time #| Out-GridView
    }
}

function Load-Settings()
{
    $settingsJson = Get-Content "settings.json" | Out-String | ConvertFrom-Json

    $settings = New-Object Settings

    $settings.UpdateIntervalMinutes = $settingsJson.UpdateIntervalMinutes
    $settings.SystemName = $settingsJson.SystemName
    $settings.SMTPServerAddress = $settingsJson.SMTPServerAddress
    $settings.EmailNotificationsEnabled = $settingsJson.EmailNotificationsEnabled
    $settings.NotificationEmailAddress = $settingsJson.NotificationEmailAddress

    return $settings
}
function Load-LogEntries()
{
    $existingEntriesJson = Get-Content 'LogEntries.json' | Out-String | ConvertFrom-Json

    $existingLogEntries = New-Object Collections.Generic.List[LogEntry]

    foreach($ele in $existingEntriesJson)
    {
        $tmpLogEntry = New-Object LogEntry
        $tmpLogEntry.Server = $ele.Server
        $tmpLogEntry.ErrorMessage = $ele.ErrorMessage
        $tmpLogEntry.MonitorType = $ele.MonitoringType
        $tmpLogEntry.IsHeartbeat = $ele.IsHeartbeat
        $tmpLogEntry.TimeStamp = $ele.TimeStamp

        $existingLogEntries.Add($tmpLogEntry)
    }

    return $existingLogEntries
}

function Load-Issues()
{
    $existingIssuesJson = Get-Content 'Issues.json' | Out-String | ConvertFrom-Json

    $existingIssues = New-Object Collections.Generic.List[Issue]

    foreach($ele in $existingIssuesJson)
    {
        $tmpIssue = New-Object Issue
        $tmpIssue.Server = $ele.Server
        $tmpIssue.ErrorMessage = $ele.ErrorMessage
        $tmpIssue.MonitoringType = $ele.MonitoringType
        $tmpIssue.StartTime = $ele.StartTime
        $tmpIssue.EndTime = $ele.EndTime
        $tmpIssue.SendEndEmail = $ele.SendEndEmail
        $tmpIssue.SendStartEmail = $ele.SendStartEmail
        
        $existingIssues.Add($tmpIssue)
    }

    return $existingIssues
}

function Add-NewIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    $newLogEntriesInterator = New-Object Collections.Generic.List[LogEntry]
    $newLogEntriesInterator = $newLogEntries.PSObject.Copy()
    
    $existingIssues = New-Object Collections.Generic.List[Issue]    
    $existingIssues = Load-Issues
    
    $openIssues = New-Object Collections.Generic.List[Issue]  
    $openIssues = $existingIssues | ? { $null -eq $_.EndTime }

    $newIssues = New-Object Collections.Generic.List[Issue]  

    $count = 0
    foreach($nle in $newLogEntriesInterator)
    {
        foreach($oi in $openIssues)
        {
            if($nle.Server -eq $oi.Server -and $nle.MonitorType -eq $oi.MonitoringType -and $null -eq $oi.EndTime)
            {
                #this means we can ignore this log entry, so setting IsHeartbeat to True will ignore it in subsequent logic
                $newLogEntries[$count].IsHeartbeat = $true
            }
        }
        $count++
    }

    if($newLogEntries -ne $null -and $newLogEntries.Count -gt 0)
    {
        foreach($nle in $newLogEntries)
        {
            if($nle.IsHeartbeat -eq $false)
            {
                $issue = New-Object Issue
                $issue.Server = $nle.Server
                $issue.MonitoringType = $nle.MonitorType
                $issue.ErrorMessage = $nle.ErrorMessage
                $issue.StartTime = [DateTime]::Now
                $issue.EndTime = $null
                $issue.SendStartEmail = $true
                $issue.SendEndEmail = $true

                $newIssues.Add($issue)
            }
        }
    }

    if($null -eq $existingIssues)
    {
        $newIssues | ConvertTo-Json | Out-File "Issues.json" 
    }
    else
    {        
        $resultIssues = New-Object Collections.Generic.List[Issue]

        $existingIssues | % { $resultIssues.Add( $_ )}
        $newIssues | % { $resultIssues.add($_)}

        $resultIssues | ConvertTo-Json | Out-File "Issues.json"
    }
}

function Resolve-FixedIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    $existingIssues = New-Object Collections.Generic.List[Issue]    
    $existingIssues = Load-Issues
    
    $count = 0
    foreach($ei in $existingIssues)
    {
        if($null -eq $ei.EndTime)
        {
            $resolutionExists = $true
            foreach($nle in $newLogEntries)
            {
                if($nle.Server -eq $ei.Server -and $nle.MonitorType -eq $ei.MonitoringType)
                {
                    $resolutionExists = $false
                }
            }

            if($resolutionExists)
            {
                $existingIssues[$count].EndTime = [DateTime]::Now
            }
        }
        $count++
    }
    
    $existingIssues | ConvertTo-Json | Out-File "Issues.json"
}
function UpdateNewAndResolvedIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    Add-NewIssues $newLogEntries
    Resolve-FixedIssues $newLogEntries
    
}