import data
into table "APL_SAMPLES"."CASHFLOWS_FULL"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
