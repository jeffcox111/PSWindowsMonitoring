from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class LogEntry:
    server: str = ""
    monitor_type: str = ""
    error_message: str = ""
    is_heartbeat: bool = False
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class Issue:
    server: str = ""
    monitoring_type: str = ""
    error_message: str = ""
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None


@dataclass
class Settings:
    update_interval_minutes: int = 5
    system_name: str = "Jarvis"
    webhook_url: str = ""
    notify_via_webhook: bool = False
    notify_via_smtp: bool = False
    smtp_server: str = ""
    smtp_user_account: str = ""
    smtp_password: str = ""
    smtp_notification_email_address: str = ""
    log_entry_retention_days: int = 30
