/*
-- Create outbox table
*/
CREATE DATABASE [outbox]
	CONTAINMENT = NONE
ON PRIMARY ( 
	NAME = N'outbox', FILENAME = N'F:\data\outbox.mdf' , SIZE = 2105344KB , FILEGROWTH = 524288KB 
)
LOG ON ( 
	NAME = N'outbox_log', FILENAME = N'G:\log\outbox_log.ldf' , SIZE = 1048576KB , FILEGROWTH = 262144KB 
)
GO
ALTER DATABASE [outbox] SET AUTO_UPDATE_STATISTICS_ASYNC ON 
GO
ALTER DATABASE [outbox] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [outbox] SET MULTI_USER 
GO
ALTER DATABASE [outbox] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [outbox] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [outbox] SET DELAYED_DURABILITY = DISABLED 
GO

/*
-- Change database context
*/
USE [outbox]
GO 

/*
-- Stored procedure to write towards the outbox table
*/
CREATE TABLE [dbo].[outbox](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[topic] [nvarchar](512) NOT NULL,
	[payload] [nvarchar](MAX) NOT NULL,
 CONSTRAINT [PK_Outbox] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) WITH ( 
	PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
	ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
	) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[outbox] WITH CHECK ADD CONSTRAINT [ck_outbox_payload] CHECK (([payload]<>''))
GO

ALTER TABLE [dbo].[outbox] CHECK CONSTRAINT [ck_outbox_payload]
GO

ALTER TABLE [dbo].[outbox] WITH CHECK ADD CONSTRAINT [ck_outbox_topic] CHECK (([topic]<>''))
GO

ALTER TABLE [dbo].[outbox] CHECK CONSTRAINT [ck_outbox_topic]
GO


/*
-- Stored procedure to write towards the outbox table
*/
CREATE OR ALTER PROCEDURE [dbo].[push]
	@topic nvarchar(512),
	@payload nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO dbo.outbox VALUES(@topic, @payload);
END;
GO


/*
-- Stored procedure to read and delete towards the outbox table
*/
CREATE OR ALTER PROCEDURE [dbo].[pull]
	@batchSize int
AS
BEGIN
	SET NOCOUNT ON;
	WITH T AS ( 
		SELECT TOP (@batchSize) * 
		FROM [dbo].[outbox] WITH (READPAST,ROWLOCK) 
		ORDER BY id 
	)
	DELETE FROM T 
	OUTPUT DELETED.*
END
