-- =============================================
-- Author:		Jeff Cox
-- Create date: 8/31/2016
-- Description:	Set monitoring system alert email flag
-- =============================================
CREATE PROCEDURE [dbo].[uspSetMonitoringAlertEmailStatus]
	@Status as bit,
	@User as varchar(100)
AS
BEGIN
	
	--update row in settings
	UPDATE Settings 
		SET SettingValue = @Status
		,LastSetBy = @User
		,LastSetTimeStamp = GETDATE() 
	WHERE SettingName = 'SendMonitoringAlertEmail'


	--send email notifying that alerts have been disabled
	declare @message as varchar(1000)
	if (@Status = 0)
		set @message = 'Monitoring Alert emails have been DISABLED due to system maintenance by ' + @user + ' .'
	else
		set @message = 'Monitoring Alert emails have been ENABLED by ' + @user + ' .'

	EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Monitoring',
				@recipients = '',
				@body = @message,
				@body_format = 'HTML',
				@subject = 'Monitoring Email Alerts Status' ;

END