CREATE TABLE [dbo].[LogEntries] (
    [ID]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [TimeStamp]      DATETIME2 (7)  NOT NULL,
    [Server]         VARCHAR (50)   NULL,
    [MonitoringType] VARCHAR (100)  NULL,
    [ErrorMessage]   VARCHAR (1000) NULL,
    [IsHeartbeat]    BIT            CONSTRAINT [DF_LogEntries_IsHeartbeat] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LogEntries] PRIMARY KEY CLUSTERED ([ID] ASC)
);

