class LogEntry
{
    [string]$Server = ""
    [string]$MonitorType = ""
    [string]$ErrorMessage = ""
    [bool]$IsHeartBeat
    [System.DateTime]$TimeStamp
}

class Issue
{
    [string]$Server = ""
    [string]$MonitoringType = ""
    [string]$ErrorMessage = ""
    [nullable[System.DateTime]]$StartTime
    [nullable[System.DateTime]]$EndTime
}

class Settings
{
    [int]$UpdateIntervalMinutes = 5
    [string]$SystemName = "Jarvis"
    [string]$WebhookURL = ""
    [bool]$NotifyViaWebhook
    [bool]$NotifyviaSMTP
    [string]$SMTPServer = ""
    [string]$SMTPUserAccount = ""
    [string]$SMTPPassword = ""
    [string]$SMTPNotificationEmailAddress = ""
    [int]$LogEntryRetentionDays = 30;
}