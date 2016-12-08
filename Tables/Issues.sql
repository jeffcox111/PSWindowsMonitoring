CREATE TABLE [dbo].[Issues] (
    [ID]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [Server]         VARCHAR (50)   NOT NULL,
    [MonitoringType] VARCHAR (100)  NOT NULL,
    [ErrorMessage]   VARCHAR (1000) NOT NULL,
    [StartTime]      DATETIME2 (7)  NOT NULL,
    [EndTime]        DATETIME2 (7)  NULL,
    [SendStartEmail] BIT            CONSTRAINT [DF_Issues_SendStartEmail] DEFAULT ((0)) NOT NULL,
    [SendEndEmail]   BIT            CONSTRAINT [DF_Issues_SendEndEmail] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Issues] PRIMARY KEY CLUSTERED ([ID] ASC)
);



