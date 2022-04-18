Add-Type -Language CSharp @"
public class Issue{
    public int ID;
    public string Server;
    public string MonitoringType;
    public string ErrorMessage;
    public System.DateTime StartTime;
    public System.DateTime? EndTime;
    public bool SendStartEmail;
    public bool SendEndEmail;
}
"@;

$issues = New-Object Collections.Generic.List[Issue]

$issue1 = New-Object Issue
$issue1.Server = "localhost"
$issue1.MonitoringType = "Check-IsOnline"
$issue1.ErrorMessage = "Server is offline"
$issue1.StartTime = Get-Date
$issue1.EndTime = $null
$issue1.SendStartEmail = $true
$issue1.SendEndEmail = $true

$issue2 = New-Object Issue
$issue2.Server = "localhost"
$issue2.MonitoringType = "Check-IsOnline"
$issue2.ErrorMessage = "Server is offline"
$issue2.StartTime = Get-Date
$issue2.EndTime = $null
$issue2.SendStartEmail = $true
$issue2.SendEndEmail = $true

$issues.add($issue1)
$issues.add($issue2)


$issues | ConvertTo-Json | Out-File "Issues.json"