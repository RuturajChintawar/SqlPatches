GO
ALTER PROCEDURE [dbo].[GenerateAuditTrail]      
    @Schemaname sysname = 'dbo' ,      
    @Tablename sysname ,      
    @GenerateScriptOnly BIT = 0 ,      
    @ForceDropAuditTable BIT = 0 ,      
    @IgnoreExistingColumnMismatch BIT = 0,      
    @AuditExtension VARCHAR(50) = '_Audit',          
    @CreateInsertTrigger BIT = 1,      
    @CreateDeleteTrigger BIT = 1,      
    @CreateUpdateTrigger BIT = 1,
	@ColumnsToExclude VARCHAR(MAX) = NULL
          
AS      
    SET NOCOUNT ON;        
        
/*        
Parameters        
@Schemaname            - SchemaName to which the table belongs to. Default value 'dbo'.        
@Tablename            - TableName for which the procs needs to be generated.        
@GenerateScriptOnly - When passed 1 , this will generate the scripts alone..        
                      When passed 0 , this will create the audit tables and triggers in the current database.        
                      Default value is 1        
@ForceDropAuditTable - When passed 1 , will drop the audit table and recreate      
                       When passed 0 , will generate the alter scripts      
                       Default value is 0      
@IgnoreExistingColumnMismatch - When passed 1 , will not stop with the error on the mismatch of existing column and will create the trigger.      
                                When passed 0 , will stop with the error on the mismatch of existing column.      
                                Default value is 0      
      
*/        
        
    DECLARE @SQL VARCHAR(MAX);        
    DECLARE @SQLTrigger VARCHAR(MAX);        
    DECLARE @AuditTableName sysname;        
        
    SELECT  @AuditTableName = @Tablename + @AuditExtension;        
        
----------------------------------------------------------------------------------------------------------------------        
-- Audit Create OR Alter table         
----------------------------------------------------------------------------------------------------------------------        
       
    DECLARE @ColList VARCHAR(MAX);       
    DECLARE @ColListForCreateTable VARCHAR(MAX);       
    DECLARE @InsertColList VARCHAR(MAX);       
    DECLARE @UpdateCheck VARCHAR(MAX);       
    DECLARE @ColumnsToExcludeInternal VARCHAR(MAX);
	SET @ColumnsToExcludeInternal = @ColumnsToExclude 

	SELECT s.s AS cols
	INTO #ColumnsToExclude
	FROM dbo.ParseString(@ColumnsToExcludeInternal,',') s

    DECLARE @NewAddedCols TABLE      
        (      
          ColumnName sysname ,      
          DataType sysname ,      
          CharLength INT ,      
          Collation sysname NULL ,      
          Prec tinyint,      
          Scale tinyint,      
          ChangeType VARCHAR(20) COLLATE DATABASE_DEFAULT NULL  ,      
          MainTableColumnName sysname NULL ,      
          MainTableDataType sysname NULL ,      
          MainTableCharLength INT NULL ,      
          MainTableCollation sysname NULL ,      
          AuditTableColumnName sysname NULL ,      
          AuditTableDataType sysname NULL ,      
          AuditTableCharLength INT NULL ,      
          AuditTableCollation sysname NULL      
        );      
      
       
    SELECT  @ColList = '';       
    SELECT  @ColListForCreateTable = '';      
    SELECT  @UpdateCheck = ' ';       
    SELECT  @SQL = '';      
      
    SELECT  @ColList = @ColList + QUOTENAME(SC.name) + ',' ,      
            @ColListForCreateTable = @ColListForCreateTable + CASE SC.is_identity      
                                    WHEN 1      
                                    THEN 'CONVERT(' + ST.name + ','      
                                         + QUOTENAME(SC.name) + ') as '      
                                         + QUOTENAME(SC.name)      
                                    ELSE QUOTENAME(SC.name)      
                                  END + ',' ,      
            @UpdateCheck = @UpdateCheck + 'CASE WHEN UPDATE('      
            + QUOTENAME(SC.name) + ') THEN ''' + QUOTENAME(SC.name)      
            + '-'' ELSE '''' END + ' + CHAR(10)      
    FROM    sys.columns SC      
            JOIN sys.objects SO ON SC.object_id = SO.object_id      
            JOIN sys.schemas SCH ON SCH.schema_id = SO.schema_id      
            JOIN sys.types ST ON ST.user_type_id = SC.user_type_id      
                                 AND ST.system_type_id = SC.system_type_id 
			LEFT JOIN #ColumnsToExclude exCol ON SC.[name] = exCol.cols
    WHERE   SCH.name = @Schemaname      
            AND SO.name = @Tablename      
            AND UPPER(ST.name) <> UPPER('timestamp')      
            AND ST.name NOT IN ('text','ntext','image')  
			AND  exCol.cols IS NULL
       
    SELECT  @ColList = SUBSTRING(@ColList, 1, LEN(@ColList) - 1);       
    SELECT  @ColListForCreateTable = SUBSTRING(@ColListForCreateTable, 1, LEN(@ColListForCreateTable) - 1);       
    SELECT  @UpdateCheck = SUBSTRING(@UpdateCheck, 1, LEN(@UpdateCheck) - 3);       
      
    SELECT  @InsertColList = @ColList      
            + ',AuditDataState,AuditDMLAction,AuditUser,AuditDateTime,UpdateColumns';      
      
    IF EXISTS ( SELECT  1      
                FROM    sys.objects      
                WHERE   name = @AuditTableName      
                        AND schema_id = SCHEMA_ID(@Schemaname)      
                        AND type = 'U' )      
        AND @ForceDropAuditTable = 0      
        BEGIN      
      
   ----------------------------------------------------------------------------------------------------------------------        
   -- Get the comparision metadata for Main and Audit Tables      
   ----------------------------------------------------------------------------------------------------------------------        
      
            INSERT  INTO @NewAddedCols      
                    ( ColumnName ,      
                      DataType ,      
                      CharLength ,      
                      Collation ,      
                      Prec,      
                      Scale,      
                      ChangeType ,      
                      MainTableColumnName ,      
                      MainTableDataType ,      
                      MainTableCharLength ,      
                      MainTableCollation ,      
                      AuditTableColumnName ,      
                      AuditTableDataType ,      
                      AuditTableCharLength ,      
                      AuditTableCollation      
                    )      
                    SELECT  ISNULL(MainTable.ColumnName, AuditTable.ColumnName) ,      
                            ISNULL(MainTable.DataType, AuditTable.DataType) ,      
                            ISNULL(MainTable.CharLength, AuditTable.CharLength) ,      
                            ISNULL(MainTable.Collation, AuditTable.Collation) ,                                  
                            ISNULL(MainTable.Prec, AuditTable.Prec),      
                            ISNULL(MainTable.Scale, AuditTable.Scale),      
                            CASE WHEN MainTable.ColumnName IS NULL AND AuditTable.ColumnName <> 'AuditId'      
                                 THEN 'Deleted'      
                                 WHEN AuditTable.ColumnName IS NULL      
                                 THEN 'Added'      
                                 ELSE NULL      
                            END ,      
                            MainTable.ColumnName ,      
                            MainTable.DataType ,      
                            MainTable.CharLength ,      
                            MainTable.Collation ,      
                            AuditTable.ColumnName ,      
                            AuditTable.DataType ,      
                            AuditTable.CharLength ,      
                            AuditTable.Collation      
                    FROM    ( SELECT    SC.name AS ColumnName ,      
                                        ST.name AS DataType ,      
                                        SC.is_identity AS isIdentity ,      
                                        SC.max_length AS CharLength ,      
                                        SC.collation_name AS Collation,      
                                        SC.precision AS Prec,      
                                        SC.scale AS Scale      
                              FROM   sys.columns SC      
                                        JOIN sys.objects SO ON SC.object_id = SO.object_id      
                                        JOIN sys.schemas SCH ON SCH.schema_id = SO.schema_id      
                                        JOIN sys.types ST ON ST.user_type_id = SC.user_type_id      
                            AND ST.system_type_id = SC.system_type_id      
                              WHERE     SCH.name = @Schemaname      
                                        AND SO.name = @Tablename      
                                        AND UPPER(ST.name) <> UPPER('timestamp')      
                            ) MainTable      
                            FULL OUTER JOIN ( SELECT    SC.name AS ColumnName ,      
                                                        ST.name AS DataType ,      
                                                        SC.is_identity AS isIdentity ,      
                                                        SC.max_length AS CharLength ,      
                                                        SC.collation_name AS Collation,      
                                                        SC.precision AS Prec,      
                                                        SC.scale AS Scale      
                                              FROM      sys.columns SC      
                                                        JOIN sys.objects SO ON SC.object_id = SO.object_id      
                                                        JOIN sys.schemas SCH ON SCH.schema_id = SO.schema_id      
                                                        JOIN sys.types ST ON ST.user_type_id = SC.user_type_id      
                                                              AND ST.system_type_id = SC.system_type_id      
                                              WHERE     SCH.name = @Schemaname      
                                                        AND SO.name = @AuditTableName      
                                                        AND UPPER(ST.name) <> UPPER('timestamp')      
                                                        AND SC.name NOT IN (      
                                                        'AuditDataState',      
                                                        'AuditDMLAction',      
                                                        'AuditUser',      
                                                        'AuditDateTime',      
                                                        'UpdateColumns' )      
                                            ) AuditTable ON MainTable.ColumnName = AuditTable.ColumnName;      
         
   ----------------------------------------------------------------------------------------------------------------------        
  -- Find data type changes between table      
  ----------------------------------------------------------------------------------------------------------------------        
      
            IF EXISTS ( SELECT  *      
                        FROM    @NewAddedCols NC      
                        WHERE   NC.MainTableColumnName = NC.AuditTableColumnName      
                                AND ( NC.MainTableDataType <> NC.AuditTableDataType      
                                      OR NC.MainTableCharLength > NC.AuditTableCharLength      
                                      OR NC.MainTableCollation <> NC.AuditTableCollation      
                                    ) )      
                BEGIN      
                    SELECT  CONVERT(VARCHAR(50), CASE WHEN NC.MainTableDataType <> NC.AuditTableDataType      
                                                      THEN 'DataType Mismatch'      
                                                      WHEN NC.MainTableCharLength > NC.AuditTableCharLength      
                                                      THEN 'Length in maintable is greater than Audit Table'      
                                                      WHEN NC.MainTableCollation <> NC.AuditTableCollation      
                                                      THEN 'Collation Difference'      
                                                 END) AS Mismatch ,      
                            NC.MainTableColumnName ,      
                            NC.MainTableDataType ,      
                            NC.MainTableCharLength ,      
                            NC.MainTableCollation ,      
                            NC.AuditTableColumnName ,      
                            NC.AuditTableDataType ,      
                            NC.AuditTableCharLength ,      
                            NC.AuditTableCollation      
                    FROM    @NewAddedCols NC      
                    WHERE   NC.MainTableColumnName = NC.AuditTableColumnName      
                            AND ( NC.MainTableDataType <> NC.AuditTableDataType      
                                  OR NC.MainTableCharLength > NC.AuditTableCharLength      
                                  OR NC.MainTableCollation <> NC.AuditTableCollation      
                                );      
      
                    RAISERROR('There are differences in Datatype or Lesser Length or Collation difference between the Main table and Audit Table. Please refer the output',16,1);      
                    IF @IgnoreExistingColumnMismatch = 0      
                        BEGIN      
                            RETURN;      
                        END;      
                END;      
      
  ----------------------------------------------------------------------------------------------------------------------        
  -- Find the new and deleted columns       
  ----------------------------------------------------------------------------------------------------------------------        
      
            IF EXISTS ( SELECT  *      
                        FROM    @NewAddedCols      
                        WHERE   ChangeType IS NOT NULL )      
                BEGIN      
      
                    SELECT  @SQL = @SQL + 'ALTER TABLE '      
                            + QUOTENAME(@Schemaname) + '.'      
                            + QUOTENAME(@AuditTableName)      
                            + CASE WHEN NC.ChangeType = 'Added'      
                                   THEN ' ADD ' + QUOTENAME(NC.ColumnName)      
                                        + ' ' + NC.DataType + ' '      
                                        + CASE WHEN NC.DataType IN ( 'char',      
                                                              'varchar',      
                                                              'nchar',      
                                                              'nvarchar' )      
                                                    AND NC.CharLength = -1      
                                               THEN '(max) COLLATE '      
                                                    + NC.Collation + ' NULL '      
                                               WHEN NC.DataType IN ( 'char',      
                                                              'varchar' )      
                                               THEN '('      
                                                    + CONVERT(VARCHAR(5), NC.CharLength)      
                                                    + ') COLLATE '      
                                                    + NC.Collation + ' NULL '      
                                               WHEN NC.DataType IN ( 'nchar',      
                                                              'nvarchar' )      
                                               THEN '('      
                                                    + CONVERT(VARCHAR(5), NC.CharLength      
                                                    / 2) + ') COLLATE '      
                                                    + NC.Collation + ' NULL '      
                                                          
                                               WHEN NC.DataType IN ( 'decimal' )      
                                               THEN '('      
                                                    + + CONVERT(VARCHAR(2), NC.Prec) + ',' + CONVERT(VARCHAR(2), NC.Scale)      
                                                    + ')'      
                                                    + ' NULL '      
                                                     
                                               ELSE ''      
                                          END      
       WHEN NC.ChangeType = 'Deleted'      
                                   THEN ' DROP COLUMN '      
                                        + QUOTENAME(NC.ColumnName)      
                              END + CHAR(10)      
                    FROM    @NewAddedCols NC      
                    WHERE   NC.ChangeType IS NOT NULL;      
                END;      
      
      
        END;      
    ELSE      
        BEGIN      
       
            SELECT  @SQL = '         
     SELECT ' + @ColListForCreateTable + '        
      ,AuditDataState=CONVERT(VARCHAR(10),'''')         
      ,AuditDMLAction=CONVERT(VARCHAR(10),'''')          
      ,AuditUser =CONVERT(SYSNAME,'''')        
      ,AuditDateTime=CONVERT(DATETIME,''01-JAN-1900'')        
      ,UpdateColumns = CONVERT(VARCHAR(MAX),'''')       
      Into ' + @Schemaname + '.' + @AuditTableName + '        
     FROM ' + @Schemaname + '.' + @Tablename + '        
     WHERE 1=2 ALTER TABLE ' + @Schemaname + '.' + @AuditTableName + ' ADD AuditId BIGINT IDENTITY(1,1) NOT NULL ALTER TABLE ' +@Schemaname + '.' + @AuditTableName + ' ADD CONSTRAINT PK_'+ @AuditTableName+' PRIMARY KEY(AuditId)';        
      
           
        END;      
        
      
    IF @GenerateScriptOnly = 1      
        BEGIN        
            PRINT REPLICATE('-', 200);        
            PRINT '--Create \ Alter Script Audit table for ' + @Schemaname      
                + '.' + @Tablename;        
            PRINT REPLICATE('-', 200);        
            PRINT @SQL;        
            IF LTRIM(RTRIM(@SQL)) <> ''      
                BEGIN      
                    PRINT 'GO';       
                END;      
            ELSE      
                BEGIN      
                    PRINT '-- No changes in table structure';      
                END;       
        END;        
    ELSE      
        BEGIN        
            IF RTRIM(LTRIM(@SQL)) = ''      
                BEGIN      
                    PRINT 'No Table Changes Found';       
                END;      
            ELSE      
                BEGIN      
                    PRINT 'Creating \ Altered Audit table for ' + @Schemaname      
                        + '.' + @Tablename;        
                    EXEC(@SQL);        
                    PRINT 'Audit table ' + @Schemaname + '.' + @AuditTableName      
                        + ' Created \ Altered succesfully';        
                END;      
        END;        
        
        
----------------------------------------------------------------------------------------------------------------------        
-- Create Insert Trigger        
----------------------------------------------------------------------------------------------------------------------        
      
 IF (@CreateInsertTrigger = 1)        
 BEGIN        
   SELECT  @SQL = '        
  IF EXISTS (SELECT 1         
      FROM sys.objects         
     WHERE Name=''' + @AuditTableName + '_Insert' + '''        
       AND Schema_id=Schema_id(''' + @Schemaname + ''')        
       AND Type = ''TR'')        
  DROP TRIGGER ' + @AuditTableName + '_Insert        
  ';        
   SELECT  @SQLTrigger = '        
  CREATE TRIGGER ' + @AuditTableName + '_Insert        
  ON ' + @Schemaname + '.' + @Tablename + '        
  FOR INSERT        
  AS        
   SET NOCOUNT ON      
   INSERT INTO ' + @Schemaname + '.' + @AuditTableName + CHAR(10) + '('      
     + @InsertColList + ')' + CHAR(10) + 'SELECT ' + @ColList      
     + ',''New'',''Insert'',SUSER_SNAME(),getdate(),''''  FROM INSERTED SET NOCOUNT OFF ';        
          
   IF @GenerateScriptOnly = 1      
    BEGIN        
     PRINT REPLICATE('-', 200);        
     PRINT '--Create Script Insert Trigger for ' + @Schemaname + '.'      
      + @Tablename;        
     PRINT REPLICATE('-', 200);        
     PRINT @SQL;        
     PRINT 'GO';        
     PRINT @SQLTrigger;        
     PRINT 'GO';        
    END;        
   ELSE      
    BEGIN        
     PRINT 'Creating Insert Trigger ' + @Tablename + '_Insert  for '      
      + @Schemaname + '.' + @Tablename;        
     EXEC(@SQL);        
     EXEC(@SQLTrigger);        
     PRINT 'Trigger ' + @Schemaname + '.' + @Tablename      
      + '_Insert  Created succesfully';        
    END;        
       
 END      
----------------------------------------------------------------------------------------------------------------------        
-- Create Delete Trigger        
----------------------------------------------------------------------------------------------------------------------        
        
 IF (@CreateDeleteTrigger = 1)        
 BEGIN      
        
  SELECT  @SQL = '        
         
 IF EXISTS (SELECT 1         
     FROM sys.objects         
    WHERE Name=''' + @AuditTableName + '_Delete' + '''        
      AND Schema_id=Schema_id(''' + @Schemaname + ''')        
      AND Type = ''TR'')        
 DROP TRIGGER ' + @AuditTableName + '_Delete        
 ';        
         
  SELECT  @SQLTrigger = '        
 CREATE TRIGGER ' + @AuditTableName + '_Delete        
 ON ' + @Schemaname + '.' + @Tablename + '        
 FOR DELETE        
 AS        
   SET NOCOUNT ON      
   INSERT INTO ' + @Schemaname + '.' + @AuditTableName + CHAR(10) + '('      
    + @InsertColList + ')' + CHAR(10) + 'SELECT ' + @ColList      
    + ',''Old'',''Delete'',SUSER_SNAME(),getdate(),''''  FROM DELETED SET NOCOUNT OFF ';        
         
  IF @GenerateScriptOnly = 1      
   BEGIN        
    PRINT REPLICATE('-', 200);        
    PRINT '--Create Script Delete Trigger for ' + @Schemaname + '.'      
     + @Tablename;        
    PRINT REPLICATE('-', 200);        
    PRINT @SQL;        
    PRINT 'GO';        
    PRINT @SQLTrigger;        
    PRINT 'GO';        
   END;        
  ELSE      
   BEGIN        
    PRINT 'Creating Delete Trigger ' + @Tablename + '_Delete  for '      
     + @Schemaname + '.' + @Tablename;        
    EXEC(@SQL);        
    EXEC(@SQLTrigger);        
    PRINT 'Trigger ' + @Schemaname + '.' + @Tablename      
     + '_Delete  Created succesfully';        
   END;        
 END      
----------------------------------------------------------------------------------------------------------------------        
-- Create Update Trigger        
----------------------------------------------------------------------------------------------------------------------        
        
 IF (@CreateUpdateTrigger = 1)      
 BEGIN      
        
  SELECT  @SQL = '        
         
 IF EXISTS (SELECT 1         
     FROM sys.objects         
    WHERE Name=''' + @AuditTableName + '_Update' + '''        
      AND Schema_id=Schema_id(''' + @Schemaname + ''')        
      AND Type = ''TR'')        
 DROP TRIGGER ' + @AuditTableName + '_Update        
 ';        
         
  SELECT  @SQLTrigger = '        
 CREATE TRIGGER ' + @AuditTableName + '_Update        
 ON ' + @Schemaname + '.' + @Tablename + '        
 FOR UPDATE        
 AS        
   SET NOCOUNT ON       
   DECLARE @CurrentDate DATETIME      
   SET @CurrentDate = GETDATE()      
   INSERT INTO ' + @Schemaname + '.' + @AuditTableName + CHAR(10) + '('      
    + @InsertColList + ')' + CHAR(10) + 'SELECT ' + @ColList      
    + ',''New'',''Update'',SUSER_SNAME(),@CurrentDate,' + @UpdateCheck      
    + '  FROM INSERTED         
         
   INSERT INTO ' + @Schemaname + '.' + @AuditTableName + CHAR(10) + '('      
    + @InsertColList + ')' + CHAR(10) + 'SELECT ' + @ColList      
    + ',''Old'',''Update'',SUSER_SNAME(),@CurrentDate,' + @UpdateCheck      
    + '  FROM DELETED SET NOCOUNT OFF';        
         
  IF @GenerateScriptOnly = 1      
   BEGIN        
    PRINT REPLICATE('-', 200);        
    PRINT '--Create Script Update Trigger for ' + @Schemaname + '.'      
     + @Tablename;        
    PRINT REPLICATE('-', 200);        
    PRINT @SQL;        
    PRINT 'GO';        
    PRINT @SQLTrigger;        
    PRINT 'GO';        
   END;        
  ELSE      
   BEGIN        
    PRINT 'Creating Delete Trigger ' + @Tablename + '_Update  for '      
     + @Schemaname + '.' + @Tablename;        
    EXEC(@SQL);        
    EXEC(@SQLTrigger);        
    PRINT 'Trigger ' + @Schemaname + '.' + @Tablename      
     + '_Update  Created succesfully';        
   END;        
 END      
       
    SET NOCOUNT OFF; 
GO
