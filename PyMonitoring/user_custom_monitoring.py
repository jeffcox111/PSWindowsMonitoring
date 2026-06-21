import platform

from monitoring_checks import (
    monitor_freespace,
    monitor_process_running_that_should_not_be,
    monitor_server_is_online,
)
from support_functions import add_error_list

_IS_WINDOWS = platform.system() == "Windows"


def invoke_monitoring_checks(messages: list) -> None:
    # Add your monitoring checks below this line.
    result = monitor_server_is_online("google.com")
    if result:
        add_error_list(result, messages)

    # Drive/partition path differs by OS
    drive = "C:\\" if _IS_WINDOWS else "/"
    result = monitor_freespace("localhost", drive, 100)
    if result:
        add_error_list(result, messages)

    # Process names differ by OS: notepad.exe on Windows, gedit (or similar) on Linux
    process = "notepad" if _IS_WINDOWS else "gedit"
    result = monitor_process_running_that_should_not_be(process, kill_if_running=True)
    if result:
        add_error_list(result, messages)
