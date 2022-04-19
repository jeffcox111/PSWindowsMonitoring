Add-Type -Language CSharp @"
public class Settings{
    public int UpdateIntervalMinutes = 5;
    public string SystemName = "Jarvis";
    public string SMTPServerAddress;
    public string NotificationEmailToAddress;
    public bool EmailNotificationsEnabled;   
    public string EmailNotificationFromAddress;
    public string EmailPassword; 
}
"@;

$settings = New-Object Settings

$settings.NotificationEmailToAddress = "jeffcox111@gmail.com"
$settings.SMTPServerAddress = "smtp.gmail.com"
$settings.EmailPassword = "kmgibhiwvxnewxul"
$settings.EmailNotificationFromAddress = "jarvismonitoring111@gmail.com"
$settings.UpdateIntervalMinutes = 5
$settings.SystemName = "Jarvis"
$settings.EmailNotificationsEnabled = $true


$settings | ConvertTo-Json | Out-File "settings.json"