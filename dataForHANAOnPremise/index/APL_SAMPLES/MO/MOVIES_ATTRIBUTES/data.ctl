import data
into table "APL_SAMPLES"."MOVIES_ATTRIBUTES"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
