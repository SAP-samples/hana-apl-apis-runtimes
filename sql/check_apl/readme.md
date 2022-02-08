# How to check APL installation
## Purpose
This script validate APL is properly installed by:
1. checking installation of low level APL AFL
2. checking installation of APL high level helpers (SQLScripts artefacts and APL role)
3. checking APL runtime

A report is done on each test and a global analysis is done.

## Audience
DBAs or DevOps can run this script each time an issue is reported with APL in order to quickly understand if issue is a bad installation or a functional issue. 

In case of a bad installation is detected, outputs can be provided to APL support for detailed analysis.

# Perimeter and dependencies
This script can be run on HANA 2.x and Hana Cloud. HANA 1.2 is not supported.
It analyzes APL artifacts delivered via a Delivery Unit as well as new HanaCloud's SQL Auto Content.

This is a pure SQLScript, meaning it can be run on server side as well as client side (even Windows) as soon as the HANA client *hdbsql* is available

## Assumptions and prerequisites
* Script server is activated
* SYSTEM password is known

## Command line
````bash
hdbsql -n <host>:<port> -u SYSTEM -p <system password> -I ./check_apl.sql -g '' -V SYSTEM_PASSWORD=<system password> -j -A 2>/dev/null
````
Example :
````bash
hdbsql -n <host>:<port> -u SYSTEM -p <system password> -I ./check_apl.sql -g '' -V SYSTEM_PASSWORD=<system password> -j -A 2>/dev/null
````
Output can be saved in a text file and then provided to APL support with
````bash
hdbsql -n <host>:<port> -u SYSTEM -p <system password> -I ./check_apl.sql -g '' -V SYSTEM_PASSWORD=<system password> -j -A >check_results.txt
````

## Results
The script outputs a resultset with 3 parts:
1. High level analysis of APL install and APL runtime. Status can be *OK* or *ERROR*

> | KEY                                                                                | ST | DETAILS                 |
> | ---------------------------------------------------------------------------------  | -- | ----------------------- |
> | Analysis of install of APL plugin properly ended                                  | OK |                         |
>| Analysis of APL runtime properly ended                                            | OK |                         |
> | All tests were done. List of issues is supposed to be complete                    |    |                         |
> | No issue detected in APL install/runtime                                          | OK |                         |

2. Detailed list of checks. Status can be *OK* or *ISSUE*
 
> | KEY                                                                                | ST | DETAILS                 |
> | ---------------------------------------------------------------------------------  | -- | ----------------------- |
> |                         |
> | Checking installation of APL plugin                                               |    |                         |
> | ...                                   |    |                         |
> | Good # of APL low level calls                                                     | OK | 54                      |
> | Good # of descriptions of APL low level calls                                     | OK | 821                     |
> | ...                                                         |    |                         |
> | Checking APL run time                                                             |    |                         |
> | ...                                                         |    |                         |
> | ...                                                   | OK | 21                      |
> | Found HCE tags in proc PING results                                               | OK | 3                       |
> | ...                                               |    |                         |
> | Check APL runtime done                                                            | OK | 
3. Full results produced by APL ping which conveys detailed version informations

> | KEY                                                                                | ST | DETAILS                 |
> | ---------------------------------------------------------------------------------  | -- | ----------------------- |
> | APL.Version.Major: 4                                                              |    |                         |
> | APL.Version.Minor: 400                                                            |    |                         |
> | APL.Version.ServicePack: 2016                                                     |    |                         |
> | APL.Version.Patch: 0                                                              |    |                         |
> | ...                                                              |    |                         |

Results 
## Cleanup
This script is designed to always delete all objects (technical user, code, tables ) at end of execution.
If for an unexpected reason, this cleanup step has not been done, manual cleanup can be done with (connected as SYSTEM or DBADMIN)
````SQL
DROP USER CHECK_APL CASCADE;
````

