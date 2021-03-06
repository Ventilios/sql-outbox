/*
-- Create outbox database
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
-- Create outbox table
*/
CREATE TABLE [dbo].[outbox] (
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[topic] [nvarchar](512) NOT NULL,
	[payload] [nvarchar](MAX) NOT NULL,
 CONSTRAINT [pk_outbox] PRIMARY KEY CLUSTERED 
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
-- Create watermark tracking table
-- Idea from: https://forrestmcdaniel.com/2021/06/30/fixing-queues-with-watermarks
-- When reading with multiple threads and pulling larger batch sizes, out of sync watermark table can occur. 
*/
CREATE TABLE dbo.outboxtrack
(
    id INT PRIMARY KEY
);
GO 

INSERT dbo.outboxtrack
VALUES (0);
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
-- Stored procedure to read and delete from the outbox table
*/
CREATE OR ALTER PROCEDURE [dbo].[pull]
	@batchsize int
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION
	
		DECLARE @d TABLE
		(
			[id] [bigint] NOT NULL
			--, [topic] [nvarchar](512) NOT NULL
			--, [payload] [nvarchar](max) NOT NULL
		);

		DECLARE @wm INT = (SELECT TOP(1) ID FROM [dbo].[outboxtrack]);

		;WITH T AS (
			SELECT TOP (@batchsize) 
				 [id]
				 , [topic]
				 , [payload]
			FROM [dbo].[outbox] WITH (READPAST,ROWLOCK)
			WHERE ID >= @wm
			ORDER BY id ASC
		)
		DELETE FROM T 
		OUTPUT deleted.id
			   --, deleted.topic
			   --, deleted.payload
		INTO @d;

		DECLARE @t INT = (SELECT MAX(ID) FROM @d)
		IF @t % 100 = 0
		BEGIN
			UPDATE [dbo].[outboxtrack]
			SET ID = @t - 100;
		END;

	COMMIT TRANSACTION
END;
