-- =============================================
-- Author:		Jeff Cox
-- Create date: 9/2/2015
-- Description:	Checks to make sure that the monitoring script is running.
-- =============================================
CREATE PROCEDURE [dbo].[uspCheckScriptIsRunning] 
	
AS
BEGIN
	
if(not exists(select * from logentries where timestamp > dateadd(mi, -10, getdate())))
begin
		
		IF EXISTS(SELECT TOP 1 1 FROM Settings WHERE SettingName = 'SendMonitoringAlertEmail' AND SettingValue = '1')
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Monitoring',
				@recipients = '',
				@body = 'The PowerShell monitoring script has failed to write to the database in more than 10 minutes.',
				@body_format = 'HTML',
				@subject = 'Monitoring System Issue Status' ;
		END
end
END
