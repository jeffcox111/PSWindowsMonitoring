import json
import platform
import smtplib
import subprocess
import time
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
from typing import Optional

import requests

from models import Issue, LogEntry, Settings

SETTINGS: Optional[Settings] = None


def import_settings(path: str = "settings.json") -> Settings:
    with open(path, "r") as f:
        data = json.load(f)

    s = Settings()
    s.update_interval_minutes = data.get("UpdateIntervalMinutes", s.update_interval_minutes)
    s.system_name = data.get("SystemName", s.system_name)
    s.webhook_url = data.get("WebhookURL", s.webhook_url)
    s.notify_via_webhook = data.get("NotifyViaWebhook", s.notify_via_webhook)
    s.notify_via_smtp = data.get("NotifyViaSMTP", s.notify_via_smtp)
    s.smtp_server = data.get("SMTPServer", s.smtp_server)
    s.smtp_user_account = data.get("SMTPUserAccount", s.smtp_user_account)
    s.smtp_password = data.get("SMTPPassword", s.smtp_password)
    s.smtp_notification_email_address = data.get("SMTPNotificationEmailAddress", s.smtp_notification_email_address)
    s.log_entry_retention_days = data.get("LogEntryRetentionDays", s.log_entry_retention_days)
    return s


def _serialize_log_entry(entry: LogEntry) -> dict:
    return {
        "Server": entry.server,
        "MonitorType": entry.monitor_type,
        "ErrorMessage": entry.error_message,
        "IsHeartbeat": entry.is_heartbeat,
        "TimeStamp": entry.timestamp.isoformat(),
    }


def _deserialize_log_entry(data: dict) -> LogEntry:
    entry = LogEntry()
    entry.server = data.get("Server", "")
    entry.monitor_type = data.get("MonitorType", "")
    entry.error_message = data.get("ErrorMessage", "")
    entry.is_heartbeat = data.get("IsHeartbeat", False)
    ts = data.get("TimeStamp")
    entry.timestamp = datetime.fromisoformat(ts) if ts else datetime.now()
    return entry


def _serialize_issue(issue: Issue) -> dict:
    return {
        "Server": issue.server,
        "MonitoringType": issue.monitoring_type,
        "ErrorMessage": issue.error_message,
        "StartTime": issue.start_time.isoformat() if issue.start_time else None,
        "EndTime": issue.end_time.isoformat() if issue.end_time else None,
    }


def _deserialize_issue(data: dict) -> Issue:
    issue = Issue()
    issue.server = data.get("Server", "")
    issue.monitoring_type = data.get("MonitoringType", "")
    issue.error_message = data.get("ErrorMessage", "")
    st = data.get("StartTime")
    issue.start_time = datetime.fromisoformat(st) if st else None
    et = data.get("EndTime")
    issue.end_time = datetime.fromisoformat(et) if et else None
    return issue


def import_log_entries(path: str = "LogEntries.json") -> list[LogEntry]:
    if not Path(path).exists():
        return []
    with open(path, "r") as f:
        data = json.load(f)
    if not isinstance(data, list):
        data = [data]
    return [_deserialize_log_entry(d) for d in data]


def import_issues(path: str = "Issues.json") -> list[Issue]:
    if not Path(path).exists():
        return []
    with open(path, "r") as f:
        data = json.load(f)
    if not isinstance(data, list):
        data = [data]
    return [_deserialize_issue(d) for d in data]


def add_error_list(log_entry: LogEntry, error_message_collection: list[LogEntry]) -> None:
    if log_entry.error_message:
        error_message_collection.append(log_entry)


def add_heartbeat(messages: list[LogEntry]) -> list[LogEntry]:
    if not messages:
        heartbeat = LogEntry()
        heartbeat.timestamp = datetime.now()
        heartbeat.is_heartbeat = True
        messages.append(heartbeat)
    return messages


def write_log_entries(messages: list[LogEntry], settings: Settings, path: str = "LogEntries.json") -> None:
    old_messages = import_log_entries(path)
    cutoff = datetime.now() - timedelta(days=settings.log_entry_retention_days)
    combined = [e for e in (old_messages + messages) if e.timestamp > cutoff]
    with open(path, "w") as f:
        json.dump([_serialize_log_entry(e) for e in combined], f, indent=2)


def add_new_issues(new_log_entries: list[LogEntry], settings: Settings) -> None:
    existing_issues = import_issues()
    open_issues = [i for i in existing_issues if i.end_time is None]

    entries = list(new_log_entries)
    for i, nle in enumerate(entries):
        for oi in open_issues:
            if nle.server == oi.server and nle.monitor_type == oi.monitoring_type:
                entries[i].is_heartbeat = True

    new_issues: list[Issue] = []
    for nle in entries:
        if not nle.is_heartbeat:
            issue = Issue()
            issue.server = nle.server
            issue.monitoring_type = nle.monitor_type
            issue.error_message = nle.error_message
            issue.start_time = datetime.now()
            new_issues.append(issue)

    all_issues = existing_issues + new_issues
    with open("Issues.json", "w") as f:
        json.dump([_serialize_issue(i) for i in all_issues], f, indent=2)

    if new_issues:
        if settings.notify_via_webhook:
            send_webhook_notification(new_issues, "New Issues", settings)
        if settings.notify_via_smtp:
            send_email_notification(new_issues, "New Issues", settings)


def resolve_fixed_issues(new_log_entries: list[LogEntry], settings: Settings) -> None:
    existing_issues = import_issues()
    resolved_issues: list[Issue] = []

    for issue in existing_issues:
        if issue.end_time is None:
            still_present = any(
                nle.server == issue.server and nle.monitor_type == issue.monitoring_type
                for nle in new_log_entries
            )
            if not still_present:
                issue.end_time = datetime.now()
                resolved_issues.append(issue)

    with open("Issues.json", "w") as f:
        json.dump([_serialize_issue(i) for i in existing_issues], f, indent=2)

    if resolved_issues:
        if settings.notify_via_webhook:
            send_webhook_notification(resolved_issues, "Resolved Issues", settings)
        if settings.notify_via_smtp:
            send_email_notification(resolved_issues, "Resolved Issues", settings)


def update_new_and_resolved_issues(new_log_entries: list[LogEntry], settings: Settings) -> None:
    add_new_issues(new_log_entries, settings)
    resolve_fixed_issues(new_log_entries, settings)


def process_log_entries(messages: list[LogEntry], settings: Settings) -> None:
    messages = add_heartbeat(messages)
    write_log_entries(messages, settings)
    update_new_and_resolved_issues(messages, settings)


def send_webhook_notification(issues: list[Issue], status: str, settings: Settings) -> None:
    payload = {
        "Status": status,
        "Issues": [_serialize_issue(i) for i in issues],
    }
    requests.post(settings.webhook_url, json=payload)


def send_email_notification(issues: list[Issue], status: str, settings: Settings) -> None:
    bg_color = "#e86363" if "New" in status else "#8FDB20"

    rows = "".join(f"<tr>{i.error_message}</tr>" for i in issues)
    body = f"""System Issue(s) Status<br><br>
    <html><head><style>
        td {{border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;}}
    </style></head>
    <body><table cellpadding=0 cellspacing=0 border=0>
    <tr bgcolor={bg_color}><td align=center><b>Error Messages</b></td></tr>
    {rows}
    </table></body></html>"""

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"{settings.system_name} - {status}"
    msg["From"] = settings.smtp_user_account
    msg["To"] = settings.smtp_notification_email_address
    msg.attach(MIMEText(body, "html"))

    with smtplib.SMTP(settings.smtp_server, 587) as server:
        server.starttls()
        server.login(settings.smtp_user_account, settings.smtp_password)
        server.sendmail(settings.smtp_user_account, settings.smtp_notification_email_address, msg.as_string())


def get_logon_history(computer: str = "localhost", days: int = 10) -> list[dict]:
    if platform.system() == "Windows":
        return _get_logon_history_windows(computer, days)
    else:
        return _get_logon_history_linux(days)


def _get_logon_history_windows(computer: str, days: int) -> list[dict]:
    try:
        import win32evtlog
        import win32security

        handle = win32evtlog.OpenEventLog(computer, "System")
        flags = win32evtlog.EVENTLOG_BACKWARDS_READ | win32evtlog.EVENTLOG_SEQUENTIAL_READ
        cutoff = datetime.now() - timedelta(days=days)
        results = []

        while True:
            events = win32evtlog.ReadEventLog(handle, flags, 0)
            if not events:
                break
            for event in events:
                if event.TimeWritten < cutoff:
                    win32evtlog.CloseEventLog(handle)
                    return results
                if event.SourceName == "Microsoft-Windows-Winlogon" and event.EventID in (7001, 7002):
                    event_type = "Logon" if event.EventID == 7001 else "Logoff"
                    try:
                        sid = event.StringInserts[1]
                        user = win32security.LookupAccountSid(None, win32security.ConvertStringSidToSid(sid))[0]
                    except Exception:
                        user = "Unknown"
                    results.append({"Time": event.TimeWritten, "Event Type": event_type, "User": user})

        win32evtlog.CloseEventLog(handle)
        return sorted(results, key=lambda x: x["Time"])
    except ImportError:
        print("pywin32 is required for get_logon_history on Windows. Install with: pip install pywin32")
        return []


def _get_logon_history_linux(days: int) -> list[dict]:
    # `last` is available on all Linux/macOS systems and covers both logons and logoffs.
    # Format: username tty host weekday month day time - logoff_or_still_logged_in
    try:
        result = subprocess.run(
            ["last", "-F", "-w"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(f"get_logon_history: 'last' command failed: {result.stderr.strip()}")
            return []

        cutoff = datetime.now() - timedelta(days=days)
        records = []

        for line in result.stdout.splitlines():
            # Skip summary lines and blanks
            if not line.strip() or line.startswith("wtmp begins") or line.startswith("reboot"):
                continue

            parts = line.split()
            # `last -F` produces lines with at least 9 parts when a full timestamp is present
            if len(parts) < 9:
                continue

            user = parts[0]
            # Full timestamp starts at index 4: e.g. "Mon Jan  6 08:12:34 2025"
            try:
                time_str = " ".join(parts[4:9])
                login_time = datetime.strptime(time_str, "%a %b %d %H:%M:%S %Y")
            except ValueError:
                continue

            if login_time < cutoff:
                break

            event_type = "Logoff" if "- " in line else "Logon"
            records.append({"Time": login_time, "Event Type": event_type, "User": user})

        return sorted(records, key=lambda x: x["Time"])
    except FileNotFoundError:
        print("get_logon_history: 'last' command not found on this system.")
        return []


def invoke_monitoring_process(settings: Settings, run_checks_fn) -> None:
    while True:
        messages: list[LogEntry] = []
        run_checks_fn(messages)
        process_log_entries(messages, settings)
        sleep_seconds = settings.update_interval_minutes * 60
        for elapsed in range(sleep_seconds + 1):
            pct = (elapsed / sleep_seconds) * 100
            print(f"\rTime till next check: {pct:.1f}%", end="", flush=True)
            time.sleep(1)
        print()
