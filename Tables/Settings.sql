CREATE TABLE [dbo].[Settings] (
    [ID]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [SettingName]    VARCHAR (100)  NOT NULL,
    [SettingValue]   VARCHAR (100)  NOT NULL,
    CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED ([ID] ASC)
);



