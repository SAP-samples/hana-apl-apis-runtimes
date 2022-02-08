-- @configSQL
-- ================================================================
-- Create table types for input and output arguments of the APL functions
--
-- Assumption: the users & privileges have been created & granted (see apl_admin.sql).


connect USER_APL password Password1;

drop type PROCEDURE_SIGNATURE_T;
create type PROCEDURE_SIGNATURE_T as table (
    "POSITION" INT, 
    "SCHEMA_NAME" NVARCHAR(256), 
    "TYPE_NAME" NVARCHAR(256), 
    "PARAMETER_TYPE" VARCHAR(7)
);

        
drop type CONFIGURATION_T;
create type CONFIGURATION_T as table (
    "name" VARCHAR(512),
    "value" VARCHAR(1024)
);

drop type CONFIGURATION_OUTPUT_T;
create type CONFIGURATION_OUTPUT_T as table (
    "name" VARCHAR(512),
    "value" VARCHAR(1024)
);

drop type PING_OUTPUT_T;
create type PING_OUTPUT_T as table (
    "NAME" VARCHAR(128),
    "VALUE" VARCHAR(1024)
);

drop type FUNCTION_HEADER_T;
create type FUNCTION_HEADER_T as table (
    "KEY" VARCHAR(50),
    "VALUE" VARCHAR(255)
);

drop type TABLE_TYPE_T;
create type TABLE_TYPE_T as table (
    "OID" VARCHAR(50),
    "POSITION" INTEGER, 
    "NAME" VARCHAR(255), 
    "KIND" VARCHAR(50), 
    "PRECISION" INTEGER, 
    "SCALE" INTEGER, 
    "MAXIMUM_LENGTH" INTEGER
);

drop type MODEL_BIN_T;
create type MODEL_BIN_T as table (  
    "FORMAT" VARCHAR(50),
    "LOB" CLOB
);

drop type MODEL_ZBIN_T;
create type MODEL_ZBIN_T as table (  
    "FORMAT" VARCHAR(50),
    "LOB" BLOB
);

drop type MODEL_NATIVE_T;
create type MODEL_NATIVE_T as table (  
    "NAME" VARCHAR(255), 
    "VERSION" INT, 
    "ID" INT,
    "PARENTID" INT,
    "ENUMFLAG" INT, 
    "PARAMNAME" VARCHAR(255), 
    "PARAMTYPE" VARCHAR(255), 
    "PARAMVALUE" VARCHAR(255)
);

drop type ADMIN_T;
create type ADMIN_T as table (  
    "NAME" VARCHAR(255),
    "Class" VARCHAR(255),
    "CLASSVERSION" DOUBLE,
    "SPACENAME"  VARCHAR(255),
    "VERSION"   INT,
    "CREATIONDATE" LONGDATE,
    "Comment" VARCHAR(255)
);

drop type MODEL_BIN_OID_T;
create type MODEL_BIN_OID_T as table (
    "OID" VARCHAR(50),
    "FORMAT" VARCHAR(50),
    "LOB" CLOB
);

drop type MODEL_ZBIN_OID_T;
create type MODEL_ZBIN_OID_T as table (
    "OID" VARCHAR(50),
    "FORMAT" VARCHAR(50),
    "LOB" BLOB
);


drop type MODEL_TXT_T;
create type MODEL_TXT_T as table (
    "ID"  INTEGER,
    "KEY" VARCHAR(1024),
    "VALUE" VARCHAR(1024)
);

drop type MODEL_TXT_OID_T;
create type MODEL_TXT_OID_T as table (
    "OID" VARCHAR(50),
    "ID"  INTEGER,
    "KEY" VARCHAR(1024),
    "VALUE" VARCHAR(1024)
);


drop type MODEL_TXT_EXTENDED_T;
create type MODEL_TXT_EXTENDED_T as table (
    "ID"  INTEGER,
    "KEY" VARCHAR(1024),
    "VALUE" NCLOB
);

drop type MODEL_TXT_OID_EXTENDED_T;
create type MODEL_TXT_OID_EXTENDED_T as table (
    "OID" VARCHAR(50),
    "ID"  INTEGER,
    "KEY" VARCHAR(1024),
    "VALUE" NCLOB
);


drop type VARIABLE_DESC_T;
create type VARIABLE_DESC_T as table (
    "RANK" INTEGER,
    "NAME" VARCHAR(255),
    "STORAGE" VARCHAR(10),
    "VALUETYPE" VARCHAR(10),
    "KEYLEVEL" INTEGER,
    "ORDERLEVEL" INTEGER,
    "MISSINGSTRING" VARCHAR(255),
    "GROUPNAME" VARCHAR(255),
    "DESCRIPTION" VARCHAR(255)
);

drop type VARIABLE_DESC_OID_T;
create type VARIABLE_DESC_OID_T as table (
    "RANK" INTEGER,
    "NAME" VARCHAR(255),
    "STORAGE" VARCHAR(10),
    "VALUETYPE" VARCHAR(10),
    "KEYLEVEL" INTEGER,
    "ORDERLEVEL" INTEGER,
    "MISSINGSTRING" VARCHAR(255),
    "GROUPNAME" VARCHAR(255),
    "DESCRIPTION" VARCHAR(255),
    "OID" VARCHAR(50)
);

drop type VARIABLE_ROLES_T;
create type VARIABLE_ROLES_T as table (
    "NAME" VARCHAR(255),
    "ROLE" VARCHAR(10)
);

drop type VARIABLE_ROLES_WITH_COMPOSITES_T;
create type VARIABLE_ROLES_WITH_COMPOSITES_T as table (
    "NAME" VARCHAR(255),
    "ROLE" VARCHAR(10),
    "COMPOSITION_TYPE" VARCHAR(10),
    "COMPONENT_NAME" VARCHAR(255)
);

drop type VARIABLE_ROLES_WITH_COMPOSITES_OID_T;
create type VARIABLE_ROLES_WITH_COMPOSITES_OID_T as table (
    "NAME" VARCHAR(255),
    "ROLE" VARCHAR(10),
    "COMPOSITION_TYPE" VARCHAR(10),
    "COMPONENT_NAME" VARCHAR(255),
    "OID" VARCHAR(50)
);

drop type OPERATION_CONFIG_T;
create type OPERATION_CONFIG_T as table (
    "KEY" VARCHAR(1000),
    "VALUE" VARCHAR(5000)
);

drop type OPERATION_CONFIG_DETAILED_T;
create type OPERATION_CONFIG_DETAILED_T as table (
    "KEY" VARCHAR(1000),
    "VALUE" VARCHAR(5000),
    "CONTEXT" VARCHAR(100)
);

drop type OPERATION_LOG_T;
create type OPERATION_LOG_T as table (
    "OID" VARCHAR(50),
    "TIMESTAMP" TIMESTAMP,
    "LEVEL" INTEGER,
    "ORIGIN" VARCHAR(50),
    "MESSAGE" NCLOB
);

drop type SUMMARY_T;
create type SUMMARY_T as table (
    "OID" VARCHAR(50),
    "KEY" VARCHAR(100),
    "VALUE" VARCHAR(100)
);

drop type RESULT_T;
create type RESULT_T as table (
    "OID" VARCHAR(50),
    "KEY" VARCHAR(100),
    "VALUE" NCLOB
);
	
drop type INDICATORS_T;
create type INDICATORS_T as table (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "KEY" VARCHAR(100),
    "VALUE" NCLOB,
    "DETAIL" NCLOB
);

drop type INDICATORS_DATASET_T;
create type INDICATORS_DATASET_T as table (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "KEY" VARCHAR(100),
    "VALUE" NCLOB,
    "DETAIL" NCLOB,
	"DATASET" VARCHAR(255)
);

drop type PROFITCURVE_T;
create type PROFITCURVE_T as table (
    "OID"        VARCHAR(50),
    "TYPE"       VARCHAR(100),
    "VARIABLE"   VARCHAR(255),
    "TARGET"     VARCHAR(255),
    "Label"      VARCHAR(255),
    "Frequency"  VARCHAR(100),
    "Random"     VARCHAR(100),
    "Wizard"     VARCHAR(100),
    "Estimation" VARCHAR(100),
    "Validation" VARCHAR(100),
    "Test"       VARCHAR(100),
    "ApplyIn"    VARCHAR(100)
);
 
drop type INFLUENCERS_T;
create type INFLUENCERS_T as table (
    "OID" VARCHAR(50),
    "TARGET" VARCHAR(255),
    "RANK" INTEGER,
    "VARIABLE" VARCHAR(255),
    "STORAGE" VARCHAR(10),
    "VALUETYPE" VARCHAR(10),
    "CONTRIBUTION" DOUBLE,
    "BASED_ON" VARCHAR(255),
    "COMPOSITION_FUNCTION" VARCHAR(255)
);
 
drop type CONTINUOUS_GROUPS_T;
create type CONTINUOUS_GROUPS_T as table (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "GROUP" VARCHAR(1024),
    "HIGHERBOUND" VARCHAR(255),
    "HIGHERBOUND_IN" INTEGER,
    "LOWERBOUND" VARCHAR(255),
    "LOWERBOUND_IN" INTEGER
);
 
drop type OTHER_GROUPS_T;
create type OTHER_GROUPS_T as table (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "GROUP" VARCHAR(1024),
    "CATEGORY" VARCHAR(255)
);

drop type ASSOCIATION_RULES_T;
create type ASSOCIATION_RULES_T as table (
    "OID" VARCHAR(50),
    "RULE_ID" INTEGER,
    "ANTECEDENT_ITEM_ID1" INTEGER,
    "ANTECEDENT_ITEM_ID2" INTEGER,
    "ANTECEDENT_ITEM_ID3" INTEGER,
    "CONSEQUENT_ID" INTEGER,
    "RULE_KI" DOUBLE,
    "RULE_LIFT" DOUBLE,
    "RULE_CONFIDENCE" DOUBLE,
    "RULE_SUPPORT" INTEGER,
    "RULE_SIZE" INTEGER,
    "ANTECEDENT_SUPPORT" INTEGER,
    "CONSEQUENT_SUPPORT" INTEGER
);

drop type RULE_ITEMS_T;
create type RULE_ITEMS_T as table (
    "OID" VARCHAR(50),
    "ITEM_ID" INTEGER,
    "VARIABLE" VARCHAR(255),
    "CATEGORY" VARCHAR(255)
);

drop type GRAPH_FILTERS_T;
create type GRAPH_FILTERS_T as table (
    "GRAPH_NAME" NVARCHAR(100),
    "COLUMN" NVARCHAR(127), 
    "OPERATOR" NVARCHAR(10), -- may be 'accept', 'discard', 'minimum' or 'maximum'
    "VALUE" NCLOB
);

drop type GRAPH_POST_PROCESSINGS_T;
create type GRAPH_POST_PROCESSINGS_T as table (
    "NAME" NVARCHAR(100),
    "TYPE" NVARCHAR(50),  -- may be 'communities','megahub','pairing' or 'bipartiteprojection'
    "KEY" NVARCHAR(1000), 
    "VALUE" NVARCHAR(100)
);

drop type GRAPH_INDICATORS_T;
create type GRAPH_INDICATORS_T as table (
    "OID" VARCHAR(50),
    "GRAPH_NAME" VARCHAR(100),
	"KEY" VARCHAR(127),
    "VALUE" NCLOB
);


drop type DEBRIEF_METRIC_T;
create type DEBRIEF_METRIC_T as table (
    "MODEL_ID"   INTEGER, 
    "OWNER_ID"   INTEGER, 
    "DATASET_ID" INTEGER, 
    "OWNER_TYPE" VARCHAR(255),
    "NAME"       VARCHAR(255),
    "VALUE"      DOUBLE
);


drop type DEBRIEF_PROPERTY_T;
create type DEBRIEF_PROPERTY_T as table (
    "MODEL_ID"    INTEGER, 
    "OWNER_ID"    INTEGER, 
    "OWNER_TYPE"  VARCHAR(255),
    "NAME"        VARCHAR(255),
    "VALUE"       VARCHAR(255),
    "LONG_VALUE"  NCLOB,
    "D_VALUE"     DOUBLE,
    "I_VALUE"     INTEGER   
);

drop type DEBRIEF_METRIC_OID_T;
create type DEBRIEF_METRIC_OID_T as table (
    "OID"        VARCHAR(512), 
    "OWNER_ID"   INTEGER, 
    "DATASET_ID" INTEGER, 
    "OWNER_TYPE" VARCHAR(255),
    "NAME"       VARCHAR(255),
    "VALUE"      DOUBLE
);


drop type DEBRIEF_PROPERTY_OID_T;
create type DEBRIEF_PROPERTY_OID_T as table (
    "OID"         VARCHAR(512), 
    "OWNER_ID"    INTEGER, 
    "OWNER_TYPE"  VARCHAR(255),
    "NAME"        VARCHAR(255),
    "VALUE"       VARCHAR(512),
    "LONG_VALUE"  NCLOB,
    "D_VALUE"     DOUBLE,
    "I_VALUE"     INTEGER   
);
