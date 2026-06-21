from support_functions import import_settings, invoke_monitoring_process
from user_custom_monitoring import invoke_monitoring_checks

if __name__ == "__main__":
    settings = import_settings("settings.json")
    invoke_monitoring_process(settings, invoke_monitoring_checks)
