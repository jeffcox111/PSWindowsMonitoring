function Invoke-MonitoringChecks ($notifications = $true)
{    
    #Run monitoring checks...
    #This is where you come in!  
    #Add lines below this comment block to check on the things you want to monitor.
    Monitor-ServerIsOnline google.com 
    Monitor-Freespace localhost C: 100
    Monitor-ProcessRunningThatShouldNotBe notepad $true
        
} 