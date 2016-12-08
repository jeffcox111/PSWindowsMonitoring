-- =============================================
-- Author:		Jeff Cox
-- Create date: 8/28/2015
-- Description:	Update Issues table with new and resolved issues
-- ***Schedule this proc to be called by a SQL Job every 5 mintues***
-- =============================================
CREATE PROCEDURE [dbo].[uspUpdateNewAndResolvedIssues]
AS
BEGIN

	-- Add new Issues----------------------------------
	create table #newLogEntries (
	   id bigint IDENTITY(1,1) NOT NULL,
	   server varchar(50),
	   monitoringtype varchar(100),
	   errormessage varchar(500),
	   timestamp datetime2
	   )

	insert into #newLogEntries select Server, MonitoringType, ErrorMessage, TimeStamp from logentries
		where isheartbeat = 0 and timestamp between  dateadd(mi, -5, getdate()) and getdate()


	declare @iterator int = 1
	declare @count int
	select @count = count(1) from #newLogEntries

	while(@count >= @iterator)
	begin
		if(exists(select nle.* from #newlogentries nle 
			join issues i on nle.server = i.server and nle.monitoringtype = i.monitoringtype
			where nle.id = @iterator and i.endtime is null))
		begin
			--issue is already being tracked, so delete it from staging table of new issues
			delete from #newlogentries where id = @iterator
		end

		set @iterator = @iterator + 1
	end

	--anything remaining in #newLogEntries will be a new Issue and needs to be added
    INSERT INTO Issues (Server, MonitoringType, ErrorMessage, StartTime, SendStartEmail, SendEndEmail)
	SELECT server, monitoringtype, errormessage, timestamp, 1, 1 FROM #newLogEntries

	drop table #newLogEntries
	--/end Add new Issues---------------------------------
	
	--Update resolved issues-------------------------------
	create table #currentIssues (
	  tempId bigint identity(1,1) not null,
	  id bigint,
	  server varchar(50),
	  monitoringtype varchar(100),
	  errormessage varchar(500),
	  starttime datetime2,
	  endtime datetime2 null
	  )

	  insert into #currentIssues select id, server, monitoringtype, errormessage, starttime, null from issues
	   where endtime is null 

	
	select @count = count(1) from #currentIssues
	set @iterator = 1

	while(@count >= @iterator)
	begin
		if(not exists(select * from logentries le join #currentIssues ci on le.server = ci.server and le.MonitoringType = ci.monitoringtype and ci.tempid = @iterator
			having max(le.timestamp) > dateadd(mi, -5, getdate())))
		begin
			--issue has been resolved so update with endtime
			update Issues  -- set endtime = getdate()
			set endtime = (select max(le.timestamp) from logentries le join #currentIssues ci on le.server = ci.server and le.MonitoringType = ci.monitoringtype and ci.tempid = @iterator)
			where id = (select id from #currentIssues where tempid = @iterator)
		end

		set @iterator = @iterator + 1
	end

	drop table #currentissues
	--/end Update Resolved Issues---------------------------

	declare @Body varchar(max),
				@TableHead varchar(max),
				@TableTail varchar(max),
				@MessageHeader varchar(max),
				@Footer varchar(max)

	if(exists(select * from issues where SendStartEmail = 1))
	begin

		SET @MessageHeader = 'Current System Issues<br><br>';
		SET @Footer = ''
		SET @TableTail = '</table></body></html>';
		SET @TableHead = '<html><head>' +
                  '<style>' +
                  'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
                  '</style>' +
                  '</head>' +
                  '<body><table cellpadding=0 cellspacing=0 border=0>' +
                  '<tr bgcolor=#e86363><td align=center><b>Error Messages</b></td></tr>';
		SELECT @Body = (SELECT ErrorMessage from monitoring..issues where SendStartEmail = 1 for XML raw('tr'), Elements)
		SET @Body = @MessageHeader + @TableHead + @Body + @TableTail + @Footer;

		IF EXISTS(SELECT TOP 1 1 FROM Settings WHERE SettingName = 'SendMonitoringAlertEmail' AND SettingValue = '1')
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Monitoring',
				@recipients = '',
				@body = @Body,
				@body_format = 'HTML',
				@subject = 'NEW System Issue(s)' ;
		END

		UPDATE Issues set SendStartEmail = 0
	end


	if(exists(select * from issues where SendEndEMail = 1 and endtime is not null ))
	begin

		SET @MessageHeader = 'RESOLVED System Issues<br><br>';
		SET @Footer = ''
		SET @TableTail = '</table></body></html>';
		SET @TableHead = '<html><head>' +
                  '<style>' +
                  'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
                  '</style>' +
                  '</head>' +
                  '<body><table cellpadding=0 cellspacing=0 border=0>' +
                  '<tr bgcolor=#8FDB20><td align=center><b>Error Messages</b></td></tr>';
		SELECT @Body = (SELECT ErrorMessage from monitoring..issues where SendEndEMail = 1 and endtime is not null for XML raw('tr'), Elements)
		SET @Body = @MessageHeader + @TableHead + @Body + @TableTail + @Footer;

		IF EXISTS(SELECT TOP 1 1 FROM Settings WHERE SettingName = 'SendMonitoringAlertEmail' AND SettingValue = '1')
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Monitoring',
				@recipients = '',
				@body = @Body,
				@body_format = 'HTML',
				@subject = 'RESOLVED System Issue(s)' ;
		END

		UPDATE Issues set SendEndEmail = 0 where SendEndEmail = 1 and EndTime is not null
	end

	
	DECLARE @monitoringdisableddate datetime
	DECLARE @dayssinceupdate int

	SELECT @monitoringdisableddate=LastSetTimeStamp FROM Settings WHERE SettingName = 'SendMonitoringAlertEmail' AND SettingValue = 0
	select @monitoringdisableddate = ISNULL(@monitoringdisableddate, GETDATE())
	select @Dayssinceupdate = DATEDIFF(DD,@monitoringdisableddate, GETDATE())

	IF @dayssinceupdate > 0
		UPDATE Settings Set SettingValue = '1', LastSetTimeStamp=GETDATE(), LastSetBy='SQL' where SettingName = 'SendMonitoringAlertEmail'



END
