
function Invoke-MonitoringProcess()
{
    while($true)
    {
        $messages = New-Object Collections.Generic.List[LogEntry]
        Invoke-MonitoringChecks -SendEmail 0
        Process-LogEntries $messages
        $sleepSeconds = $settings.UpdateIntervalMinutes * 60
        for($x = 0; $x -le $sleepSeconds; $x++)
        {
            $percentComplete = ($x / $sleepSeconds) * 100
            Write-Progress -Activity "Time till next monitoring check run..." -Status "$percentComplete%" -PercentComplete $percentComplete
            Start-Sleep -Seconds 1
        }
    }
}

function Send-WebhookNotification([Collections.Generic.List[Issue]] $Issues, [string] $status)
{
    $message = [PSCustomObject]@{
        Status = $status
        Issues = $Issues
    }
    Invoke-WebRequest -Uri $settings.WebhookURL -Method Post -Body ($message | ConvertTo-Json)

}

function Send-EmailNotification([Collections.Generic.List[Issue]] $Issues, [string] $status)
{    
    $SmtpServer = $settings.SMTPServer
    $SmtpUser = $settings.SMTPUserAccount  
    $smtpPassword = $settings.SMTPPassword  
    $MailtTo = $settings.SMTPNotificationEmailAddress  
    $MailFrom = $settings.SMTPUserAccount  
    $MailSubject = $settings.SystemName + " - $status"  
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force)  
    $bgColor = ""
    
    if($status.Contains("New")) 
    { 
        $bgColor = "#e86363"
    }
    else
    {
        $bgColor = "#8FDB20"
    }

    $MessageHeader = "System Issue(s) Status<br><br>"
    $MessageFooter = ""
    $TableTail = "</table></body></html>"
    $TableHead = @"
    <html><head><style>
        td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} 
    </style>
    </head>
    <body><table cellpadding=0 cellspacing=0 border=0>
    <tr bgcolor=$bgColor><td align=center><b>Error Messages</b></td></tr>
"@
    $rows = ""
    foreach($item in $Issues)    
    {
        $rows = $rows + "<tr>" + $item.ErrorMessage + "</tr>"
    }

    $Body = $MessageHeader + $TableHead + $rows + $TableTail + $MessageFooter  
    
    Send-MailMessage -To "$MailtTo" -from "$MailFrom" -Subject $MailSubject -Body "$Body" -SmtpServer $SmtpServer -Port 587 -BodyAsHtml -UseSsl -Credential $Credentials  

}

function Add-ErrorList([LogEntry] $logentry, [Collections.Generic.List[LogEntry]]$errorMessageCollection)
{
    if(-Not([string]::IsNullOrEmpty($logentry.ErrorMessage)))
    {
        $errorMessageCollection.Add($logentry)
    }
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
         
        $Result | Select-Object User, Time | Sort-Object Time #| Out-GridView
    }
}

function Import-Settings()
{
    $settingsJson = Get-Content "settings.json" | Out-String | ConvertFrom-Json

    $settings = New-Object Settings

    $settings.UpdateIntervalMinutes = $settingsJson.UpdateIntervalMinutes
    $settings.SystemName = $settingsJson.SystemName
    $settings.WebhookURL = $settingsJson.WebhookURL
    $settings.NotifyViaWebhook = $settingsJson.NotifyViaWebhook
    $settings.NotifyViaSMTP = $settingsJson.NotifyViaSMTP
    $settings.SMTPServer = $settingsJson.SMTPServer
    $settings.SMTPUserAccount = $settingsJson.SMTPUserAccount
    $settings.SMTPPassword = $settingsJson.SMTPPassword
    $settings.SMTPNotificationEmailAddress = $settingsJson.SMTPNotificationEmailAddress
    $settings.LogEntryRetentionDays = $settingsJson.LogEntryRetentionDays
    
    return $settings
}
function Import-LogEntries()
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

function Import-Issues()
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
                
        $existingIssues.Add($tmpIssue)
    }

    return $existingIssues
}

function Add-Heartbeat([Collections.Generic.List[LogEntry]] $messages)
{
    if($messages.Count -eq 0)
    {
        $heartBeat = new-object LogEntry
        $heartBeat.TimeStamp = [DateTime]::Now
        $heartBeat.IsHeartbeat = 1

        $messages.add($heartbeat)
    }
    return $messages
}
function Write-LogEntries([Collections.Generic.List[LogEntry]] $messages)
{
    $resultMessages = New-Object Collections.Generic.List[LogEntry]
    $oldMessages = Import-LogEntries
    if($null -eq $oldMessages)
    {
        $messages | ConvertTo-Json | Out-File "LogEntries.json" 
    }
    else
    {        
        $oldmessages | ForEach-Object { $resultMessages.Add( $_ )}
        $messages | ForEach-Object { $resultMessages.add($_)}
        
        $resultMessages = $resultMessages | ? { $_.TimeStamp -gt (Get-date).AddDays(-$settings.LogEntryRetentionDays)  }
        
        $resultMessages | ConvertTo-Json | Out-File "LogEntries.json"
    }
}
function Add-NewIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    $newLogEntriesInterator = New-Object Collections.Generic.List[LogEntry]
    $newLogEntriesInterator = $newLogEntries.PSObject.Copy()
    
    $existingIssues = New-Object Collections.Generic.List[Issue]    
    $existingIssues = Import-Issues
    
    $openIssues = New-Object Collections.Generic.List[Issue]  
    $openIssues = $existingIssues | Where-Object { $null -eq $_.EndTime }

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

        $existingIssues | ForEach-Object { $resultIssues.Add( $_ )}
        $newIssues | ForEach-Object { $resultIssues.add($_)}

        $resultIssues | ConvertTo-Json | Out-File "Issues.json"
    }

    if($newIssues.Count -gt 0) 
    { 
       if($settings.NotifyViaWebhook) { Send-WebhookNotification $newIssues "New Issues" }
       if($settings.NotifyViaSMTP) {Send-EmailNotification $newIssues "New Issues" }
    }
}

function Resolve-FixedIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    $existingIssues = New-Object Collections.Generic.List[Issue]    
    $existingIssues = Import-Issues
    
    $resolvedIssues = New-Object Collections.Generic.List[Issue]    

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
                $resolvedIssues.Add($ei)
            }
        }
        $count++
    }
    
    $existingIssues | ConvertTo-Json | Out-File "Issues.json"

    if($resolvedIssues.Count -gt 0) 
    { 
       if($settings.NotifyViaWebhook) { Send-WebhookNotification $newIssues "Resolved Issues" }
       if($settings.NotifyViaSMTP) {Send-EmailNotification $resolvedIssues "Resolved Issues" }
    }
}
function UpdateNewAndResolvedIssues([Collections.Generic.List[LogEntry]] $newLogEntries)
{
    Add-NewIssues $newLogEntries
    Resolve-FixedIssues $newLogEntries
    
}

function Process-LogEntries([Collections.Generic.List[LogEntry]] $messages)
{
    #add heartbeat entry if there were no issues detected
    $messages = Add-Heartbeat $messages
        
    #log entries to json file
    Write-LogEntries $messages

    #add new issues, resolve closed issues, send notifications
    UpdateNewAndResolvedIssues $messages
}