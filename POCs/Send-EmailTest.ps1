Add-Type -Language CSharp @"
public class Settings{
    public int UpdateIntervalMinutes = 5;
    public string SystemName = "Jarvis";
    public string WebhookURL;
    public bool NotifyViaWebhook;
    public bool NotifyViaSMTP; 
    public string SMTPServer;
    public string SMTPUserAccount;
    public string SMTPPassword;
    public string SMTPNotificationEmailAddress;
}
"@;

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
    
    return $settings
}

$settings = Import-Settings

$Body = "Sample Email Body"  
$SmtpServer = $settings.SMTPServer
$SmtpUser = $settings.SMTPUserAccount  
$smtpPassword = $settings.SMTPPassword  
$MailtTo = $settings.SMTPNotificationEmailAddress  
$MailFrom = $settings.SMTPUserAccount  
$MailSubject = "Testing Mail from Powershell"  
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force)  
Send-MailMessage -To "$MailtTo" -from "$MailFrom" -Subject $MailSubject -Body "$Body" -SmtpServer $SmtpServer -Port 587 -BodyAsHtml -UseSsl -Credential $Credentials  

