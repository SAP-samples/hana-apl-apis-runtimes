-- @required(hanaMinimumVersion,4.0.0)
connect SYSTEM password Password1;

DO BEGIN
	declare nb_error integer;
	rules              = SELECT rule_namespace, rule_name, category FROM SQLSCRIPT_ANALYZER_RULES WHERE RULE_NAME != 'USE_OF_DDL_STATEMENT' AND CATEGORY != 'INFORMATION';
    procedures_to_scan = SELECT schema_name, procedure_name object_name, definition FROM sys.procedures 
        WHERE procedure_type = 'SQLSCRIPT2' AND schema_name IN('SAP_PA_APL') AND procedure_name like 'sap.pa.apl%';
    CALL analyze_sqlscript_objects(:procedures_to_scan, :rules, procedure_objects, procedure_findings);   
    procedure_results = SELECT t1.schema_name, t1.object_name, t2.*, t1.object_definition FROM :procedure_findings t2 
         JOIN :procedure_objects t1 ON t1.object_definition_id = t2.object_definition_id;

    functions_to_scan = SELECT schema_name, function_name object_name, definition FROM sys.functions 
         WHERE function_type = 'SQLSCRIPT2' AND schema_name IN('SAP_PA_APL') AND function_name like 'sap.pa.apl%';
    CALL analyze_sqlscript_objects(:functions_to_scan, :rules, function_objects, function_findings);
    function_results = SELECT t1.schema_name, t1.object_name, t2.*, t1.object_definition FROM :function_findings t2 
         JOIN :function_objects t1 ON t1.object_definition_id = t2.object_definition_id;

    final_res = SELECT * from ( select 'PROCEDURE' AS "TYPE",object_name,rule_name,category,short_description from :procedure_results union ALL 
       select 'FUNCTION' AS "TYPE",object_name,rule_name,category,short_description from :function_results )
      order by object_name,rule_name;
     
     select count(*) into nb_error  from  :final_res;
     if ( :nb_error != 0 ) then
         SIGNAL SQL_ERROR_CODE 10000 SET MESSAGE_TEXT = 'Analyze Sqlscript detect some errors';
     end if;
     -- EXEC 'create table res_analyze_apl as (select * FROM :final_res )' USING final_res;
 END;
