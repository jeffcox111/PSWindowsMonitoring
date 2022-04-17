Add-Type -Language CSharp @"
public class Settings{
    public string EmailAddress;
    public string EmailServer;
    public string EmailPassword;
}
"@;

$settings = New-Object Settings

$settings.EmailAddress = "jeffcox111@gmail.com"
$settings.EmailServer = "testserver"
$settings.EmailPassword = "testpassword"

$settings | ConvertTo-Json | Out-File "settings.json"