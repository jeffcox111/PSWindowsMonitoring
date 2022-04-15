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


function UpdateNewAndResolvedIssues()
{

    
}