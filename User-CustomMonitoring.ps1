function Run-MonitoringChecks ($notifications = $true)
{    
    #Run monitoring checks...
    #This is where you come in!  
    #Add lines below this comment block to check on the things you want to monitor.
    Check-ServerIsOnline google.com 
    Check-Freespace localhost C: 100 
    Check-ProcessRunningThatShouldNotBe notepad $true
} 