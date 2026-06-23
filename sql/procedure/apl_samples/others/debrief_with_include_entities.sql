-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- APL_AREA, GET_MODEL_DEBRIEF with APL/DebriefIncludeEntities filter
--
-- Demonstrates how to retrieve only a subset of debrief entity types.
-- The APL/DebriefIncludeEntities parameter accepts a comma-separated list
-- of entity type names; only those entities (and their dependencies) are
-- returned, producing a smaller, faster debrief output.
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DO BEGIN
    declare INVALID_INPUT condition for SQL_ERROR_CODE 10001;
    declare full_metric_count   integer;
    declare filtered_metric_count integer;
    declare unexpected_types    integer;

    declare header       "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config       "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
    declare filter_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
    declare var_desc     "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
    declare var_role     "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
    declare out_model    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
    declare out_log      "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
    declare out_sum      "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
    declare out_indic    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

    declare full_metric    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";
    declare full_property  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";
    declare filt_metric    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";
    declare filt_property  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

    :header.insert(('Oid', '#42'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'regression',null));
    :var_role.insert(('age', 'target', null, null, null));

    -- Train the model
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(
        :header, :config, :var_desc, :var_role,
        'APL_SAMPLES', 'ADULT01',
        out_model, out_log, out_sum, out_indic);

    -- Step 1: full debrief (no filter) — used as reference
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(
        :header, :out_model, :config,
        full_metric, full_property, out_sum);

    select count(*) into full_metric_count from :full_metric;
    if ( :full_metric_count = 0 ) then
        signal INVALID_INPUT set MESSAGE_TEXT = 'Full debrief_metric must not be empty';
    end if;

    -- Step 2: filtered debrief — request only SL_REGRESSION_RESULT_STAT
    :filter_config.insert(('APL/DebriefIncludeEntities', 'SL_REGRESSION_RESULT_STAT', null));

    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(
        :header, :out_model, :filter_config,
        filt_metric, filt_property, out_sum);

    select count(*) into filtered_metric_count from :filt_metric;
    if ( :filtered_metric_count = 0 ) then
        signal INVALID_INPUT set MESSAGE_TEXT = 'Filtered debrief_metric must not be empty';
    end if;

    -- Filtered result must be smaller than or equal to the full debrief
    if ( :filtered_metric_count > :full_metric_count ) then
        signal INVALID_INPUT set MESSAGE_TEXT = 'Filtered debrief must not exceed full debrief row count';
    end if;

    -- Requested entity must be present in the filtered result
    select count(*) into unexpected_types
        from :filt_metric
        where "OWNER_TYPE" = 'SL_REGRESSION_RESULT_STAT';
    if ( :unexpected_types = 0 ) then
        signal INVALID_INPUT set MESSAGE_TEXT = 'Requested entity SL_REGRESSION_RESULT_STAT must appear in filtered debrief_metric';
    end if;

    -- Non-requested entity types must be absent from the filtered result
    select count(*) into unexpected_types
        from :filt_metric
        where "OWNER_TYPE" != 'SL_REGRESSION_RESULT_STAT';
    if ( :unexpected_types != 0 ) then
        signal INVALID_INPUT set MESSAGE_TEXT = 'Non-requested entity types must not appear in filtered debrief_metric';
    end if;

    -- Display filtered results
    select "OWNER_TYPE", "NAME", "VALUE"
        from :filt_metric
        order by "OWNER_TYPE", "NAME";

END;
