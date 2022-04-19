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

function Load-Settings()
{
    $settingsJson = Get-Content "settings.json" | Out-String | ConvertFrom-Json

    $settings = New-Object Settings

    $settings.UpdateIntervalMinutes = $settingsJson.UpdateIntervalMinutes
    $settings.SystemName = $settingsJson.SystemName
    $settings.SMTPServerAddress = $settingsJson.SMTPServerAddress
    $settings.EmailNotificationsEnabled = $settingsJson.EmailNotificationsEnabled
    $settings.NotificationEmailToAddress = $settingsJson.NotificationEmailToAddress
    $settings.EmailNotificationFromAddress = $settingsJson.EmailNotificationFromAddress
    $settings.EmailPassword = $settingsJson.EmailPassword

    return $settings
}
$settings = Load-Settings

# $SmtpClient = $settings.smtpSer
# $MailMessage = New-Object system.net.mail.mailmessage
# $SmtpClient.Host = ""
# $mailmessage.from = ("")
# $mailmessage.To.add("")
# $mailmessage.Subject = “PowerShell Monitoring System Alert”
# $body = $errorMessageCollection | % {$_.ErrorMessage + "`r`n"}
# $mailmessage.Body = $body
# $smtpclient.Send($mailmessage)

$Body = "Sample Email Body"  
$SmtpServer = $settings.SMTPServerAddress
$SmtpUser = $settings.EmailNotificationFromAddress  
$smtpPassword = $settings.EmailPassword  
$MailtTo = $settings.NotificationEmailToAddress  
$MailFrom = $settings.EmailNotificationFromAddress  
$MailSubject = "Testing Mail from Powershell"  
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force)  
Send-MailMessage -To "$MailtTo" -from "$MailFrom" -Subject $MailSubject -Body "$Body" -SmtpServer $SmtpServer -BodyAsHtml -UseSsl -Credential $Credentials  