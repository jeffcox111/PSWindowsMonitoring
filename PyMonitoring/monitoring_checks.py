import subprocess
import socket
import platform
from datetime import datetime

import psutil
import requests

from models import LogEntry


def _make_entry(server: str, monitor_type: str, error_message: str) -> LogEntry:
    entry = LogEntry()
    entry.server = server
    entry.monitor_type = monitor_type
    entry.error_message = error_message
    entry.timestamp = datetime.now()
    return entry


def monitor_server_is_online(server_name: str, friendly_host_name: str = "", number_of_attempts: int = 1) -> LogEntry | None:
    label = f"{friendly_host_name} ({server_name})" if friendly_host_name else server_name
    print(f"Testing connectivity with {label}...")

    param = "-n" if platform.system().lower() == "windows" else "-c"
    reachable = False
    for _ in range(number_of_attempts):
        result = subprocess.run(
            ["ping", param, "1", server_name],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if result.returncode == 0:
            reachable = True
            break

    if not reachable:
        entry = _make_entry(label, "monitor_server_is_online", f"Cannot connect to {label}.")
        print(entry.error_message)
        return entry
    return None


def monitor_freespace(server_name: str, drive: str, threshold_gigs: int) -> LogEntry | None:
    print(f"Checking free space on {server_name} {drive} ...")
    try:
        usage = psutil.disk_usage(drive)
        free_gigs = usage.free / (1024 ** 3)

        if free_gigs == 0:
            msg = f"Drive {drive} on {server_name} is out of space."
        elif free_gigs < threshold_gigs:
            free_mb = free_gigs * 1024
            msg = f"Drive {drive} on {server_name} is below {threshold_gigs} gig of free space. There are {free_mb:.2f} MB remaining."
        else:
            return None

        entry = _make_entry(server_name, "monitor_freespace", msg)
        print(entry.error_message)
        return entry
    except Exception as e:
        entry = _make_entry(server_name, "monitor_freespace", f"Can't currently perform disk queries against {server_name}: {e}")
        print(entry.error_message)
        return entry


def monitor_website_online(url: str, friendly_name: str) -> LogEntry | None:
    print(f"Checking website {friendly_name} ...")
    try:
        response = requests.head(url, timeout=20)
        if response.status_code in (200, 401, 404):
            return None
        status = response.status_code
    except requests.RequestException:
        status = "unreachable"

    msg = f"{friendly_name} is offline or unreachable."
    entry = _make_entry(friendly_name, "monitor_website_online", msg)
    print(entry.error_message)
    return entry


def monitor_monitoring_host_rebooted() -> LogEntry | None:
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime = datetime.now() - boot_time
    total_minutes = int(uptime.total_seconds() / 60)
    days = uptime.days
    hours = uptime.seconds // 3600
    minutes = (uptime.seconds % 3600) // 60
    print(f"Checking host uptime... {days} days, {hours} hours, {minutes} minutes")

    if days == 0 and hours == 0 and 10 < minutes < 15:
        hostname = socket.gethostname()
        msg = f"The host of this monitoring script ({hostname}) has successfully rebooted."
        entry = _make_entry(hostname, "monitor_monitoring_host_rebooted", msg)
        print(entry.error_message)
        return entry
    return None


def monitor_sql_blocking(server_name: str) -> LogEntry | None:
    print(f"Looking for blocking in DB {server_name} ...")
    try:
        import pyodbc
        conn = pyodbc.connect(
            f"Driver={{SQL Server}};Server={server_name};Database=master;Trusted_Connection=yes;"
        )
        cursor = conn.cursor()
        cursor.execute(
            "SELECT count(1) FROM master.dbo.sysprocesses sp "
            "JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid and sp.blocked > 0"
        )
        result = cursor.fetchval()
        conn.close()

        if result and result > 0:
            msg = f"There is SQL blocking taking place in {server_name}."
            entry = _make_entry(server_name, "monitor_sql_blocking", msg)
            print(entry.error_message)
            return entry
    except Exception as e:
        entry = _make_entry(server_name, "monitor_sql_blocking", f"Failed to query {server_name}: {e}")
        print(entry.error_message)
        return entry
    return None


def monitor_db_email_failures(server: str) -> LogEntry | None:
    print(f"Checking for failed emails on {server}...")
    try:
        import pyodbc
        conn = pyodbc.connect(
            f"Driver={{SQL Server}};Server={server};Database=Monitoring;Trusted_Connection=yes;"
        )
        cursor = conn.cursor()
        cursor.execute(
            "SELECT count(1) FROM msdb..sysmail_allitems "
            "WHERE sent_status <> 'sent' "
            "AND last_mod_date BETWEEN dateadd(mi, -5, getdate()) AND getdate()"
        )
        count = cursor.fetchval()
        conn.close()

        if count and count > 0:
            msg = f"{count} email(s) failed being sent from {server}."
            entry = _make_entry(server, "monitor_db_email_failures", msg)
            print(entry.error_message)
            return entry
    except Exception as e:
        entry = _make_entry(server, "monitor_db_email_failures", f"Failed to query {server}: {e}")
        print(entry.error_message)
        return entry
    return None


def monitor_used_disk_space_linux(server: str, partition: str, threshold_percentage: int) -> LogEntry | None:
    print(f"Checking free drive space on server: {server}, file system: {partition}...")
    try:
        import paramiko
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(server, username="tproot", key_filename="privatekey.ppk")
        _, stdout, _ = client.exec_command(f"df | grep {partition} | awk '{{print $4}}'")
        output = stdout.read().decode().strip()
        client.close()

        if not output:
            msg = f"The partition {partition} on server {server} does not exist."
            entry = _make_entry(server, "monitor_used_disk_space_linux", msg)
            print(entry.error_message)
            return entry

        used_percent = int(output.replace("%", ""))
        if used_percent > threshold_percentage:
            msg = f"On the server {server}, the partition {partition} is at {used_percent}% capacity and should be below {threshold_percentage}%."
            entry = _make_entry(server, "monitor_used_disk_space_linux", msg)
            print(entry.error_message)
            return entry
    except Exception as e:
        entry = _make_entry(server, "monitor_used_disk_space_linux", f"Failed to check {server}: {e}")
        print(entry.error_message)
        return entry
    return None


def monitor_process_running_that_should_not_be(process_name: str, kill_if_running: bool = False) -> LogEntry | None:
    print(f"Checking to see if process {process_name} is running ...")
    matching = [p for p in psutil.process_iter(["name"]) if p.info["name"] and process_name.lower() in p.info["name"].lower()]

    if not matching:
        return None

    process = matching[0]

    if kill_if_running:
        process.terminate()
        try:
            process.wait(timeout=5)
            msg = f"The process {process_name} was found running and was stopped successfully."
        except psutil.TimeoutExpired:
            process.kill()
            msg = f"The process {process_name} was found running and forced stop is being attempted."
    else:
        msg = f"The process {process_name} was found running; no attempt made to stop."

    entry = _make_entry("localhost", "monitor_process_running_that_should_not_be", msg)
    print(entry.error_message)
    return entry


def monitor_process_not_running(process_name: str) -> LogEntry | None:
    # TODO: implement
    pass
