function Monitor-SQLBlocking([string]$serverName)
{
    write-host "Looking for blocking in DB $serverName ..."
    $sqlconn = New-Object System.Data.SqlClient.SqlConnection
    $sqlconn.ConnectionString = "Server=" + $serverName + ";Database=master;Integrated Security=SSPI;"
    $sqlconn.Open()

    $sqlcommand = $sqlconn.CreateCommand()
    $sqlcommand.CommandText = "SELECT  count(1) FROM master.dbo.sysprocesses sp JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid and sp.blocked > 0"
    $result = $sqlcommand.ExecuteScalar()
    $sqlconn.Close()

    if($result -gt 0)
    {              
       $logentry = new-object LogEntry
       $logentry.Server = $serverName
       $logentry.TimeStamp = [DateTime]::Now
       $logentry.MonitorType = "Monitor-SQLBlocking"
       $logentry.ErrorMessage = "There is SQL blocking taking place in " + $serverName + "."
       
       write-host $logentry.ErrorMessage
       if($null -ne $messages)
       {
            Add-ErrorList $logentry $messages
       }
       return $logentry       
    }    
}

function Monitor-ServerIsOnline([string]$serverName, [string]$friendlyHostName = "", [int32]$NumberOfAttempts = 1)
{
    if($friendlyHostName -eq "")
    {
        $friendlyHostName = $serverName
    }
    else 
    {
        $friendlyHostName = $friendlyHostName + " (" + $serverName + ")"
    }

    write-host "Testing connectivity with $friendlyHostName..."
    if (-Not (Test-Connection $serverName -Count $NumberOfAttempts -ErrorAction SilentlyContinue))
    {
        $logentry = new-object LogEntry
        $logentry.Server = $friendlyHostName
        $logentry.TimeStamp = [DateTime]::Now
        $logentry.MonitorType = "Monitor-ServerIsOnline"
        $logentry.ErrorMessage = "Cannot connect to $friendlyHostName."

        write-host $logentry.ErrorMessage
        if($null -ne $messages)
        {
            Add-ErrorList $logentry $messages
        }
        return $logentry
    }     
}

function Monitor-MonitoringHostRebooted()
{
   $os = Get-WmiObject win32_operatingsystem
   $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
   $Display = "Checking host uptime... " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes" 
   write-host $display
   if($uptime.days -eq 0 -and $uptime.hours -eq 0 -and $uptime.minutes -gt 10 -and $uptime.minutes -lt 15)
   {
      $logentry = new-object LogEntry
      $logentry.Server = $env:computername
      $logentry.TimeStamp = [DateTime]::Now
      $logentry.MonitorType = "Monitor-MonitoringHostRebooted"
      $logentry.ErrorMessage = "The host of this monitoring script ($env:computername) has successfully rebooted."
      
      write-host $logentry.ErrorMessage
      if($null -ne $messages)
      {
          Add-ErrorList $logentry $messages
      }
      return $logentry
   }
   
}

function Monitor-Freespace([string] $serverName,[string] $drive, [int]$thresholdGigs)
{
    if (Test-Connection $serverName -Count 1 -ErrorAction SilentlyContinue)
    {
        if($null -ne (Get-WmiObject Win32_LogicalDisk -ComputerName $serverName -Filter "DeviceID='$drive'"))
        {
          $freespace = (Get-WmiObject Win32_LogicalDisk -ComputerName $serverName -Filter "DeviceID='$drive'" | Select-Object FreeSpace).FreeSpace / 1024 / 1024 / 1024
          $Display = "Checking free space on $serverName $drive ..."
          write-host $display

          $logentry = new-object LogEntry
          $logentry.Server = $serverName
          $logentry.TimeStamp = [DateTime]::Now
          $logentry.MonitorType = "Monitor-Freespace"

          if ($freespace -eq 0)
          {
              $logentry.ErrorMessage = "Drive $drive on $serverName is out of space."
              write-host $logentry.ErrorMessage
              if($null -ne $messages)
              {
                  Add-ErrorList $logentry $messages
              }
              return $logentry
              
          }
          elseif($freespace -lt $thresholdGigs)
          {
              $mb = "{0:N2}" -f ($freespace * 1024)
              $logentry.ErrorMessage = "Drive $drive on $serverName is below $thresholdGigs gig of free space. There are $mb MB remaining."
              write-host $logentry.ErrorMessage
              if($null -ne $messages)
              {
                  Add-ErrorList $logentry $messages
              }    
              return $logentry            
          }
        }
        else
        {
            $logentry = new-object LogEntry
            $logentry.Server = $serverName
            $logentry.TimeStamp = [DateTime]::Now
            $logentry.MonitorType = "Monitor-Freespace"
            $logentry.ErrorMessage = "Can't currently perform WMI queries against $serverName."
            
            write-host $logentry.ErrorMessage
            if($null -ne $messages)
            {
                Add-ErrorList $logentry $messages
            }
            return $logentry
        }
    }
}

function Monitor-WebsiteOnline([string]$url, [string]$friendlyName)
{
    write-host "Checking website $friendlyName ..."
    $statusCode = ""
    $request = $null 
    try
    {
       $request = Invoke-WebRequest -Uri $url -TimeoutSec 20 -Method head 
       $statusCode = $request.StatusCode
    }  
    catch 
    { 
       $request = $_.Exception.Response 
       $statusCode = $request.StatusCode
    }  

    if(-Not($statusCode -eq 200 -or $statusCode -eq "Unauthorized" -or $statusCode -eq "NotFound"))
    {
       $logentry = new-object LogEntry
       $logentry.Server = $friendlyName
       $logentry.TimeStamp = [DateTime]::Now
       $logentry.MonitorType = "Monitor-WebsiteOnline"
       $logentry.ErrorMessage = "$friendlyName is offline or unreachable."

       write-host $logentry.ErrorMessage
       if($null -ne $messages)
       {
           Add-ErrorList $logentry $messages
       } 
       return $logentry
    }
}

function Monitor-DBEmailFailures([string] $server)
{
    write-host "Checking for failed emails on $server..."
    $sqlConn = New-Object System.Data.SqlClient.SqlConnection
    $sqlConn.ConnectionString = "Data Source=$server;Initial Catalog=Monitoring;Persist Security Info=True;User ID=;Password="
    $sqlConn.Open()

    $sql = "select count(1) from msdb..sysmail_allitems where sent_status <> 'sent' and last_mod_date between dateadd(mi, -5, getdate()) and getdate()"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sql,$sqlConn)
    $count = $cmd.ExecuteScalar()

    if($count -gt 0)
    {
    
       $logentry = new-object LogEntry
       $logentry.Server = $server
       $logentry.TimeStamp = [DateTime]::Now
       $logentry.MonitorType = "Monitor-DBEmailFailure"
       $logentry.ErrorMessage = "$count email(s) failed being sent from $server."

       write-host $logentry.ErrorMessage
       if($null -ne $messages)
       {
           Add-ErrorList $logentry $messages
       }
       return $logentry
    }
}

function Monitor-UsedDiskSpaceLinux([string]$server, [string]$partition, [int]$thresholdPercentage)
{
    if (Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)
    {
        write-host "Checking free drive space on server: $server, file system: $partition..."
        $x = . 'c:\program files\git\usr\bin\ssh.exe' $server -l tproot -i privatekey.ppk "df | grep $partition | awk '{print `$4}'"

        if($null -eq $x)
        {
     
          $logentry = new-object LogEntry
          $logentry.Server = $server
          $logentry.TimeStamp = [DateTime]::Now
          $logentry.MonitorType = "Monitor-UsedDiskSpaceLinux"
          $logentry.ErrorMessage = "The partition $partition on server $server does not exist."
      
          write-host $logentry.ErrorMessage
          if($null -ne $messages)
          {
              Add-ErrorList $logentry $messages
          }
          return $logentry
        }

        $usedSpacePercent = $x.replace("%", "")
       

        if([int]$usedSpacePercent -gt $thresholdPercentage)
        {
          $logentry = new-object LogEntry
          $logentry.Server = $server
          $logentry.TimeStamp = [DateTime]::Now
          $logentry.MonitorType = "Monitor-UsedDiskSpaceLinux"
          $logentry.ErrorMessage = "On the server $server, the partition $partition is at $usedSpacePercent % capacity and should be below $threshholdPercentage %."
      
          write-host $logentry.ErrorMessage
          if($null -ne $messages)
          {
              Add-ErrorList $logentry $messages
          }
          return $logentry
        }
    }
}


function Monitor-ProcessNotRunning([string]$ProcessName)
{
    #TODO: code the dang logic
}

function Monitor-ProcessRunningThatShouldNotBe([string]$ProcessName, [bool]$KillIfRunning = $false)
{
    write-host "Checking to see of process $ProcessName is running ..."
    $process = Get-Process $ProcessName -ErrorAction SilentlyContinue
    if ($process) 
    {
        $logentry = new-object LogEntry

        if($KillIfRunning)
        {
            # try gracefully first
            $process.CloseMainWindow()
            # kill after five seconds
            Start-Sleep 5

            if (!$process.HasExited) 
            {
                $process | Stop-Process -Force
                
                $logentry.Server = "localhost"
                $logentry.TimeStamp = [DateTime]::Now
                $logentry.MonitorType = "Monitor-ProcessRunningThatShouldNotBe"
                $logentry.ErrorMessage = "The process $ProcessName was found running and forced stop is being attempted."
            
                write-host $logentry.ErrorMessage
                if($null -ne $messages)
                {
                    Add-ErrorList $logentry $messages
                }
                return $logentry
            }

            $logentry.Server = "localhost"
            $logentry.TimeStamp = [DateTime]::Now
            $logentry.MonitorType = "Monitor-ProcessRunningThatShouldNotBe"
            $logentry.ErrorMessage = "The process $ProcessName was found running and was stopped successfully."
        
            write-host $logentry.ErrorMessage
            if($null -ne $messages)
            {
                Add-ErrorList $logentry $messages
            }
            return $logentry
        }

        $logentry.Server = "localhost"
        $logentry.TimeStamp = [DateTime]::Now
        $logentry.MonitorType = "Monitor-ProcessRunningThatShouldNotBe"
        $logentry.ErrorMessage = "The process $ProcessName was found running; no attempt made to stop."
    
        write-host $logentry.ErrorMessage
        if($null -ne $messages)
        {
            Add-ErrorList $logentry $messages
        }
        return $logentry
    }
    
}
