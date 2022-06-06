Add-Type -Language CSharp @"
public class LogEntry{
    public System.DateTime? TimeStamp;
    public string Server;
    public string MonitorType;
    public string ErrorMessage;
    public bool IsHeartbeat;
}
"@;

Add-Type -Language CSharp @"
public class Issue{
    public string Server;
    public string MonitoringType;
    public string ErrorMessage;
    public System.DateTime? StartTime;
    public System.DateTime? EndTime;
}
"@;

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
    public int LogEntryRetentionDays = 30;
}
"@;