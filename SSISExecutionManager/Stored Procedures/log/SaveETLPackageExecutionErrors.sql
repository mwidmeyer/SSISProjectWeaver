﻿CREATE PROCEDURE [log].SaveETLPackageExecutionErrors @ETLBatchId                       INT,
                                                     @ErrorsRequiringNotificationCount INT OUT,
                                                     @ETLPackagesRequiringRestartCount INT OUT
AS
    --Insert unexpected terminations
    INSERT INTO [log].ETLPackageExecutionError
                ([SSISDBExecutionId]
                 ,[SSISDBEventMessageId]
                 ,[ETLBatchId]
                 ,[ETLPackageId]
                 ,[ErrorDateTime]
                 ,[ErrorMessage]
                 ,[ETLPackageExecutionErrorTypeId])
    SELECT
      e.execution_id            AS [SSISDBExecutionId]
      ,NULL                     AS [SSISDBEventMessageId]
      ,ebe.ETLBatchId           AS [ETLBatchId]
      ,p.ETLPackageId           AS [ETLPackageId]
      ,e.end_time               AS [ErrorDateTime]
      ,'Unexpected termination' AS [ErrorMessage]
      ,2                        AS [ETLPackageExecutionErrorTypeId] --Unexpected termination	 
    FROM
      [$(SSISDB)].[catalog].[executions] e
      JOIN ctl.ETLBatchSSISDBExecutions ebe
        ON e.execution_id = ebe.SSISDBExecutionId
      JOIN ctl.ETLPackage p
        ON e.folder_name = p.SSISDBFolderName
           AND e.project_name = p.SSISDBProjectName
           AND e.package_name = p.SSISDBPackageName
    WHERE
      ebe.ETLBatchId = @ETLBatchId
      AND [status] = 6
      AND p.ETLPackageId NOT IN (SELECT
                                   ETLPackageId
                                 FROM
                                   [log].ETLPackageExecutionError
                                 WHERE
                                  ETLPackageExecutionErrorTypeId = 2
								  AND ETLBatchId = @ETLBatchId);

    --Insert or update packages stats based on SSISDB errors
    MERGE [log].ETLPackageExecutionError AS Target
    USING (SELECT
             err.[SSISDBExecutionId]
             ,err.[EventMessageId]
             ,err.[ETLBatchId]
             ,err.[ETLPackageId]
             ,err.[ErrorDateTime]
             ,err.[ErrorMessage]
             ,1 AS [ETLPackageExecutionErrorTypeId] --SSISDB
           FROM
             dbo.func_GetETLPackageExecutionErrorsForBatch(@ETLBatchId) err) AS source ([SSISDBExecutionId], [SSISDBEventMessageId], [ETLBatchId], [ETLPackageId], [ErrorDateTime], [ErrorMessage], [ETLPackageExecutionErrorTypeId])
    ON target.[SSISDBEventMessageId] = source.[SSISDBEventMessageId]
       AND target.ETLPackageId = source.ETLPackageId
    WHEN Matched THEN
      UPDATE SET [SSISDBExecutionId] = source.[SSISDBExecutionId]
                 ,[SSISDBEventMessageId] = source.[SSISDBEventMessageId]
                 ,ETLBatchId = source.ETLBatchId
                 ,ETLPackageId = source.ETLPackageId
                 ,[ErrorDateTime] = source.[ErrorDateTime]
                 ,[ErrorMessage] = source.[ErrorMessage]
                 ,[ETLPackageExecutionErrorTypeId] = source.[ETLPackageExecutionErrorTypeId]
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([SSISDBExecutionId]
              ,[SSISDBEventMessageId]
              ,ETLBatchId
              ,ETLPackageId
              ,[ErrorDateTime]
              ,[ErrorMessage]
              ,[ETLPackageExecutionErrorTypeId])
      VALUES(source.[SSISDBExecutionId]
             ,source.[SSISDBEventMessageId]
             ,source.ETLBatchId
             ,source.ETLPackageId
             ,source.[ErrorDateTime]
             ,source.[ErrorMessage]
             ,source.[ETLPackageExecutionErrorTypeId]);

    SET @ErrorsRequiringNotificationCount = (SELECT
                                               COUNT(*)
                                             FROM
                                               [log].ETLPackageExecutionError
                                             WHERE
                                              EmailNotificationSentDateTime IS NULL
                                              AND ETLBatchId = @ETLBatchId)
    SET @ETLPackagesRequiringRestartCount = (SELECT
                                               COUNT(*)
                                             FROM
                                               [log].ETLPackageExecutionError
                                             WHERE
                                              ETLPackageRestartDateTime IS NULL
                                              AND ETLBatchId = @ETLBatchId)

    RETURN 0 