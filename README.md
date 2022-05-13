# PSWindowsMonitoring
A library of PowerShell functions to assist in monitoring Windows-based networks.

Provides PowerShell functions for performing the following monitoring checks...

Monitor-ServerIsOnline - Works like ping but a tiny bit smarter.

Monitor-Freespace - Determines of a volume on a server is below a specified threshhold of free space remaining.

Monitor-WebsiteOnline - Looks for a status 200 message from a URL to ensure that not only is the server online, but the site it is hosting is online as well.

Monitor-DBEmailFailures - Looks for failed SQL mail in the queue of a MS SQL Server.

Check - UsedDiskSpaceLinux - works like Monitor-Freespace, but for a Linux host.  This requires setting up ssh.exe on the Windows machine the script is run from, as well as SSH keys to the Linux host you are checking for free space.

Monitor-Monitoring Host Rebooted - Determines if the system that is performing these check routines, presumably on a schedule of every few minutes, has been rebooted.

Monitor-SQLBlocking - Works with MS SQL Server and returns if blocking is occurring.  Blocking inherently is not a bad thing, but monitoring increased frequency of blocking can help resolve deadlocking issues.
