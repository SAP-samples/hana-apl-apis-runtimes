  # Check APL installation and runtime                                                                                                                  
  Report date: 2025-12-16 13:46:14                                                                                                                      
  ## Notes                                                                                                                                              
  Note|Status                                                                                                                                           
  ---|---                                                                                                                                               
  SERVICE ADMIN and MONITORING rights have been granted to temporary user CHECK_APL so scriptserver and system informations can be checked|Information  
    
  - [Full check of APL installation and runtime](#full-check-of-apl-installation-and-runtime)                                                                                                
      - [Pre-analysis](#pre-analysis)                                                                                                                                                        
      - [Checking installation of APL in database H00](#checking-installation-of-apl-in-database-h00)                                                                                        
          - [Global status of APL plugin](#global-status-of-apl-plugin)                                                                                                                      
          - [Detailed registration of APL plugin](#detailed-registration-of-apl-plugin)                                                                                                      
          - [Detailed registration of APL high level SQL procedures - DU or SQLAutoContent](#detailed-registration-of-apl-high-level-sql-procedures---du-or-sqlautocontent)                  
          - [Checking known deployment issues of APL SQL](#checking-known-deployment-issues-of-apl-sql)                                                                                      
      - [APL Run-time checks](#apl-run-time-checks)                                                                                                                                          
          - [Checking APL basic run time in direct mode](#checking-apl-basic-run-time-in-direct-mode)                                                                                        
          - [Checking APL basic run time in procedure mode](#checking-apl-basic-run-time-in-procedure-mode)                                                                                  
          - [Checking APL full train run time in procedure mode](#checking-apl-full-train-run-time-in-procedure-mode)                                                                        
      - [Analysis of results](#analysis-of-results)                                                                                                                                          
          - [Summary of results](#summary-of-results)                                                                                                                                        
  - [Annexes](#annexes)                                                                                                                                                                      
      - [System and HANA instance informations](#system-and-hana-instance-informations)                                                                                                      
          - [Active plugins](#active-plugins)                                                                                                                                                
          - [System Overview](#system-overview)                                                                                                                                              
          - [Host informations](#host-informations)                                                                                                                                          
          - [Databases](#databases)                                                                                                                                                          
          - [Database history](#database-history)                                                                                                                                            
          - [Services](#services)                                                                                                                                                            
          - [Current database](#current-database)                                                                                                                                            
          - [Most used APL functions since restart](#most-used-apl-functions-since-restart)                                                                                                  
          - [Content of APL caches](#content-of-apl-caches)                                                                                                                                  
          - [Memory usage of APL since restart](#memory-usage-of-apl-since-restart)                                                                                                          
      - [Some support statements **valid only in this instance**](#some-support-statements-**valid-only-in-this-instance**)                                                                  
          - [Connection to HANA instance](#connection-to-hana-instance)                                                                                                                      
          - [Post Install step](#post-install-step)                                                                                                                                          
          - [APL files on server](#apl-files-on-server)                                                                                                                                      
          - [HANA Traces](#hana-traces)                                                                                                                                                      
  ## Full check of APL installation and runtime                                                                                                                                              
  ### Pre-analysis                                                                                                                                                                           
  |Main component|Status|Details|                                                                                                                                                            
  |---|---|---|                                                                                                                                                                              
  |HANA Cloud||4.00.000.00.1762969583 on linuxx86_64|                                                                                                                                        
  |APL is installed|<span style="color:green">**OK**</span>|4.400.2522.0|                                                                                                                    
  |Script Server is activated|<span style="color:green">**OK**</span>|Full analysis will be done|                                                                                            
  ### Checking installation of APL in database H00                                                                                                                                           
  #### Global status of APL plugin                                                                                                                                                           
  |Check|Status|Details|                                                                                                                                                                     
  |---|---|---|                                                                                                                                                                              
  |APL Manifest|HANA auxversion|0000.00.0|                                                                                                                                                   
  |APL Manifest|HANA changeinfo|CONT 036ac362bdd1796b3ff7b7897cb7624cc34ac7c5 (ce_nightly)|                                                                                                  
  |APL Manifest|HANA cloud_edition|2025.48.0-nightly.20251112|                                                                                                                               
  |APL Manifest|HANA compilebranch|ce_nightly|                                                                                                                                               
  |APL Manifest|HANA compiler-version-full|gcc (SAP release 20250423, based on SUSE gcc13-13.2.1+git7813-150000.1.6.1) 13.2.1 20230912 [revision b96e66fd4ef3e36983969fb8cdd1956f551a074b]|  
  |APL Manifest|HANA compiletype|rel|                                                                                                                                                        
  |APL Manifest|HANA date|2025-11-12 17:57:05|                                                                                                                                               
  |APL Manifest|HANA fullversion|4.00.000.00 Build 1762969583-1530|                                                                                                                          
  |APL Manifest|HANA git-hash|036ac362bdd1796b3ff7b7897cb7624cc34ac7c5|                                                                                                                      
  |APL Manifest|HANA git-headcount|502032|                                                                                                                                                   
  |APL Manifest|HANA git-mergeepoch|1762969583|                                                                                                                                              
  |APL Manifest|HANA git-mergetime|2025-11-12 17:46:23|                                                                                                                                      
  |APL Manifest|HANA hdb-state|RAMP|                                                                                                                                                         
  |APL Manifest|HANA makeid|14906906|                                                                                                                                                        
  |APL Manifest|HANA rev-changelist|1762969583|                                                                                                                                              
  |APL Manifest|HANA rev-patchlevel|00|                                                                                                                                                      
  |APL Manifest|HANA sapexe-branch|754_REL|                                                                                                                                                  
  |APL Manifest|HANA sapexe-changelist|0|                                                                                                                                                    
  |APL Manifest|HANA sapexe-version|754|                                                                                                                                                     
  |APL Manifest|HANA sp-patchlevel|00|                                                                                                                                                       
  |APL Manifest|PPMS-Build-Version|000|                                                                                                                                                      
  |APL Manifest|PPMS-Build-Version-Patch-Level|0000|                                                                                                                                         
  |APL Manifest|PPMS-Technical-Name|SAP_AFL_SDK_APL|                                                                                                                                         
  |APL Manifest|PPMS-Technical-Release|4.400|                                                                                                                                                
  |APL Manifest|afl-state|RAMP|                                                                                                                                                              
  |APL Manifest|auxversion|0000.00.0|                                                                                                                                                        
  |APL Manifest|changeinfo|CONT b1ce1eaa5331c41d927c5b1361449dc7648ebfde (afl-ce_nightly)|                                                                                                   
  |APL Manifest|compilebranch|afl-ce_nightly|                                                                                                                                                
  |APL Manifest|compiletype|rel|                                                                                                                                                             
  |APL Manifest|component-key|sap_afl_sdk_apl|                                                                                                                                               
  |APL Manifest|compversion-id|73554900100200013849|                                                                                                                                         
  |APL Manifest|date|2025-10-08 10:21:30|                                                                                                                                                    
  |APL Manifest|fullversion|4.400.2522.0|                                                                                                                                                    
  |APL Manifest|git-hash|b1ce1eaa5331c41d927c5b1361449dc7648ebfde|                                                                                                                           
  |APL Manifest|git-headcount|5201|                                                                                                                                                          
  |APL Manifest|git-mergeepoch|1762984658|                                                                                                                                                   
  |APL Manifest|git-mergetime|2025-11-12 21:57:38|                                                                                                                                           
  |APL Manifest|hana_afl_sdk-major-version|2|                                                                                                                                                
  |APL Manifest|hana_afl_sdk-minor-version|13|                                                                                                                                               
  |APL Manifest|keycaption|Automated Predictive Library|                                                                                                                                     
  |APL Manifest|keyname|sap_afl_sdk_apl|                                                                                                                                                     
  |APL Manifest|keyvendor|sap.com|                                                                                                                                                           
  |APL Manifest|lcmsdk-kind|Cloud|                                                                                                                                                           
  |APL Manifest|lcmsdk-major-version|1|                                                                                                                                                      
  |APL Manifest|lcmsdk-minor-version|0|                                                                                                                                                      
  |APL Manifest|lcmsdk-patch-version|178|                                                                                                                                                    
  |APL Manifest|lcmsdk-version|1.0.178|                                                                                                                                                      
  |APL Manifest|makeid|14907308|                                                                                                                                                             
  |APL Manifest|original-compilebranch|undefined|                                                                                                                                            
  |APL Manifest|platform|linuxx86_64|                                                                                                                                                        
  |APL Manifest|plugin-type|AFL|                                                                                                                                                             
  |APL Manifest|release|4.400|                                                                                                                                                               
  |APL Manifest|required-components|name="HDB"; vendor="sap.com"; version="[4.00.000.00.0000000000,9.99.999.99.9999999999]"|                                                                 
  |APL Manifest|rev-changelist|0|                                                                                                                                                            
  |APL Manifest|rev-number|2522|                                                                                                                                                             
  |APL Manifest|rev-patchlevel|0|                                                                                                                                                            
  |APL Manifest|server-plugin|1|                                                                                                                                                             
  |Good high level status of registration of APL plugin|<span style="color:green">**OK**</span>|REGISTRATION SUCCESSFUL|                                                                     
  |No detected issue during registration process of APL plugin|<span style="color:green">**OK**</span>|REGISTRATION SUCCESSFUL|                                                              
  #### Detailed registration of APL plugin                                                                                                                                                   
  |Check|Status|Details                                                                                                                                                                      
  |---|---|---|                                                                                                                                                                              
  |Good # of APL AREA|<span style="color:green">**OK**</span>|1|                                                                                                                             
  |Good # of APL PACKAGES|<span style="color:green">**OK**</span>|1|                                                                                                                         
  |Good # of APL low level calls|<span style="color:green">**OK**</span>|59|                                                                                                                 
  |Good # of descriptions of APL low level calls|<span style="color:green">**OK**</span>|921|                                                                                                
  #### Detailed registration of APL high level SQL procedures - DU or SQLAutoContent                                                                                                         
  |Check|Status|Details                                                                                                                                                                      
  |---|---|---|                                                                                                                                                                              
  |Good # of APL roles|<span style="color:green">**OK**</span>|Expected roles AFLPM_CREATOR_ERASER_EXECUTE,AFL__SYS_AFL_APL_AREA_EXECUTE,sap.pa.apl.base.roles::APL_EXECUTE are granted|     
  |Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared|<span style="color:green">**OK**</span>|1|                                                                                   
  |This is an HCE version of APL||there is no potential issue on du packaging to check|                                                                                                      
  |# of APL tables and types||145 to be checked|                                                                                                                                             
  |# of SQL APL APIS||193 to be checked|                                                                                                                                                     
  |Expected debrief version from running HCE SQL code||1.3.4.11|                                                                                                                             
  #### Checking known deployment issues of APL SQL                                                                                                                                           
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Versions of C++ & AutoContent are aligned|<span style="color:green">**OK**</span>|4.400.2522.0|                                                                                           
  ### APL Run-time checks                                                                                                                                                                    
  #### Checking APL basic run time in direct mode                                                                                                                                            
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |ping direct|AFLSDK.Build.Version.Major|2|                                                                                                                                                 
  |ping direct|AFLSDK.Build.Version.Minor|13|                                                                                                                                                
  |ping direct|AFLSDK.Build.Version.Patch|0|                                                                                                                                                 
  |ping direct|AFLSDK.Info|2.16.0|                                                                                                                                                           
  |ping direct|AFLSDK.Version.Major|2|                                                                                                                                                       
  |ping direct|AFLSDK.Version.Minor|16|                                                                                                                                                      
  |ping direct|AFLSDK.Version.Patch|0|                                                                                                                                                       
  |ping direct|APL.Info|Automated Predictive Library|                                                                                                                                        
  |ping direct|APL.Version.Major|4|                                                                                                                                                          
  |ping direct|APL.Version.Minor|400|                                                                                                                                                        
  |ping direct|APL.Version.Patch|0|                                                                                                                                                          
  |ping direct|APL.Version.ServicePack|2522|                                                                                                                                                 
  |ping direct|AutomatedAnalytics.Info|Automated Analytics|                                                                                                                                  
  |ping direct|AutomatedAnalytics.Version.Major|10|                                                                                                                                          
  |ping direct|AutomatedAnalytics.Version.Minor|2522|                                                                                                                                        
  |ping direct|AutomatedAnalytics.Version.Patch|0|                                                                                                                                           
  |ping direct|AutomatedAnalytics.Version.ServicePack|0|                                                                                                                                     
  |Calling direct PING successful|<span style="color:green">**OK**</span>||                                                                                                                  
  #### Checking APL basic run time in procedure mode                                                                                                                                         
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Try to really call sap.pa.apl.base::PING|||                                                                                                                                               
  |ping proc|AFLSDK.Build.Version.Major|2|                                                                                                                                                   
  |ping proc|AFLSDK.Build.Version.Minor|13|                                                                                                                                                  
  |ping proc|AFLSDK.Build.Version.Patch|0|                                                                                                                                                   
  |ping proc|AFLSDK.Info|2.16.0|                                                                                                                                                             
  |ping proc|AFLSDK.Version.Major|2|                                                                                                                                                         
  |ping proc|AFLSDK.Version.Minor|16|                                                                                                                                                        
  |ping proc|AFLSDK.Version.Patch|0|                                                                                                                                                         
  |ping proc|APL.Info|Automated Predictive Library|                                                                                                                                          
  |ping proc|APL.Version.Major|4|                                                                                                                                                            
  |ping proc|APL.Version.Minor|400|                                                                                                                                                          
  |ping proc|APL.Version.Patch|0|                                                                                                                                                            
  |ping proc|APL.Version.ServicePack|2522|                                                                                                                                                   
  |ping proc|AutomatedAnalytics.Info|Automated Analytics|                                                                                                                                    
  |ping proc|AutomatedAnalytics.Version.Major|10|                                                                                                                                            
  |ping proc|AutomatedAnalytics.Version.Minor|2522|                                                                                                                                          
  |ping proc|AutomatedAnalytics.Version.Patch|0|                                                                                                                                             
  |ping proc|AutomatedAnalytics.Version.ServicePack|0|                                                                                                                                       
  |ping proc|HDB.Version|4.00.000.00.1762969583|                                                                                                                                             
  |ping proc|SQLAutoContent.Caption|Automated Predictive SQL Library for Hana Cloud|                                                                                                         
  |ping proc|SQLAutoContent.Date|2025-10-08|                                                                                                                                                 
  |ping proc|SQLAutoContent.Version|4.400.2522.0|                                                                                                                                            
  |Calling proc PING successful|<span style="color:green">**OK**</span>||                                                                                                                    
  |Found HCE tags in proc PING results|<span style="color:green">**OK**</span>|3|                                                                                                            
  #### Checking APL full train run time in procedure mode                                                                                                                                    
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Try to really call sap.pa.apl.base::CREATE_MODEL_AND_TRAIN|||                                                                                                                             
  |Call APL DU proc sap.pa.apl.base::CREATE_MODEL_AND_TRAIN has been successful|<span style="color:green">**OK**</span>||                                                                    
  ### Analysis of results                                                                                                                                                                    
  #### Summary of results                                                                                                                                                                    
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Analysis of install of APL plugin properly ended|<span style="color:green">**OK**</span>||                                                                                                
  |Analysis of APL deployment issue properly ended|<span style="color:green">**OK**</span>||                                                                                                 
  |Analysis of APL basic runtime properly ended|<span style="color:green">**OK**</span>||                                                                                                    
  |Analysis of runtime train proc properly ended|<span style="color:green">**OK**</span>||                                                                                                   
  |No issue detected in APL install/runtime|<span style="color:green">**OK**</span>||                                                                                                        
  |All tests were done. List of detected issues is supposed to be complete|||                                                                                                                
  ## Annexes                                                                                                                                                                                 
  ### System and HANA instance informations                                                                                                                                                  
  #### Active plugins                                                                                                                                                                        
  |Name| | |                                                                                                                                                                                 
  |---|---|---|                                                                                                                                                                              
  |APL|||                                                                                                                                                                                    
  |PAL|||                                                                                                                                                                                    
  #### System Overview                                                                                                                                                                       
  |Info|Status|Details|                                                                                                                                                                      
  |---|---|---|                                                                                                                                                                              
  |CPU:CPU|<span style="color:green">**OK**</span>|Available 22, Used 0.22|                                                                                                                  
  |Disk:Data|<span style="color:green">**OK**</span>|Size 955.6 GB, Used 468.5 GB, Free 51 %|                                                                                                
  |Disk:Log|<span style="color:green">**OK**</span>|Size 955.6 GB, Used 468.5 GB, Free 51 %|                                                                                                 
  |Disk:Trace|<span style="color:green">**OK**</span>|Size 955.6 GB, Used 468.5 GB, Free 51 %|                                                                                               
  |Memory:Memory|<span style="color:green">**OK**</span>|Physical 56.89 GB, Swap 15.00 GB, Used 3.66|                                                                                        
  |Services:All Started|<span style="color:green">**OK**</span>|Yes|                                                                                                                         
  |Services:Max Start Time||2025-12-16 13:28:35.473|                                                                                                                                         
  |Services:Min Start Time||2025-12-16 13:28:24.000|                                                                                                                                         
  |Statistics:Alerts|<span style="color:green">**OK**</span>|No Alerts|                                                                                                                      
  |System:Distributed||No|                                                                                                                                                                   
  |System:Instance ID||H00|                                                                                                                                                                  
  |System:Instance Number||00|                                                                                                                                                               
  |System:Platform||SUSE Linux Enterprise Server 15 SP5|                                                                                                                                     
  |System:Version||4.00.000.00.1762969583 (ce_nightly)|                                                                                                                                      
  #### Host informations                                                                                                                                                                     
  |Host|Info|Value|                                                                                                                                                                          
  |---|---|---|                                                                                                                                                                              
  |hce|container||                                                                                                                                                                           
  |hce|cpu_summary||                                                                                                                                                                         
  |hce|daemon_active||                                                                                                                                                                       
  |hce|hw_model||                                                                                                                                                                            
  |hce|mem_phys|0|                                                                                                                                                                           
  |hce|net_realhostname||                                                                                                                                                                    
  |hce|os_name||                                                                                                                                                                             
  |hce|os_user||                                                                                                                                                                             
  |hce|sap_retrieval_path||                                                                                                                                                                  
  |hce|sapsystem|00|                                                                                                                                                                         
  |hce|sid|H00|                                                                                                                                                                              
  #### Databases                                                                                                                                                                             
  |Name|Status|Description|                                                                                                                                                                  
  |---|---|---|                                                                                                                                                                              
  |H00|ACTIVE_STATUS:YES:ACTIVE||                                                                                                                                                            
  #### Database history                                                                                                                                                                      
  |Version| | Date|                                                                                                                                                                          
  |---|---|---|                                                                                                                                                                              
  |4.00.000.00.1762969583||2025-11-19 14:45:39|                                                                                                                                              
  |4.00.000.00.1760436283||2025-10-23 14:17:02|                                                                                                                                              
  #### Services                                                                                                                                                                              
  |Host|Service:status|Port:SQL Port|                                                                                                                                                        
  |---|---|---|                                                                                                                                                                              
  |hce|compileserver:YES|30010:0|                                                                                                                                                            
  |hce|daemon:YES|30000:0|                                                                                                                                                                   
  |hce|indexserver:YES|30040:30041|                                                                                                                                                          
  |hce|nameserver:YES|30001:0|                                                                                                                                                               
  |hce|scriptserver:YES|30043:30044|                                                                                                                                                         
  #### Current database                                                                                                                                                                      
  |SID|Name|Usage|                                                                                                                                                                           
  |---|---|---|                                                                                                                                                                              
  |H00|H00|CUSTOM|                                                                                                                                                                           
  |No tenant and tenant users found|Standard HANA Cloud instance||                                                                                                                           
  #### Most used APL functions since restart                                                                                                                                                 
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |PING|6|2025-12-16 13:46:15|                                                                                                                                                               
  |CREATE_MODEL_AND_TRAIN|2|2025-12-16 13:46:16|                                                                                                                                             
  #### Content of APL caches                                                                                                                                                                 
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Cached SQL wrappers|SAP_PA_APL:CHECK_APL|1|                                                                                                                                               
  |Cached types|SAP_PA_APL|1|                                                                                                                                                                
  ||||                                                                                                                                                                                       
  |Apl caches: |Global statistics||                                                                                                                                                          
  |SAP_PA_APL: |Nb distinct users using default schema for APL cache|1|                                                                                                                      
  |SAP_PA_APL: |Nb Wrappers in default schema for APL cache|1|                                                                                                                               
  |SAP_PA_APL: |Nb table types in default schema for APL cache|1|                                                                                                                            
  |Private APL caches: |Nb Wrappers: |0|                                                                                                                                                     
  |Private APL caches: |Nb table types: |0|                                                                                                                                                  
  |Private APL caches|Nb: |0|                                                                                                                                                                
  |Private APL caches|Nb distinct users: |0|                                                                                                                                                 
  #### Memory usage of APL since restart                                                                                                                                                     
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |scriptserver|Pool/AFL_SDK/APL|EXCL_HEAPMEM_USED:7.26MB:EXCL_MAX_SINGLE_ALLOCATION_SIZE:0.10MB:EXCL_PEAK_ALLOCATION_SIZE:7.26MB|                                                           
  |scriptserver|Pool/malloc/libaflapl.so|EXCL_HEAPMEM_USED:0.23MB:EXCL_MAX_SINGLE_ALLOCATION_SIZE:0.03MB:EXCL_PEAK_ALLOCATION_SIZE:0.23MB|                                                   
  ### Some support statements **valid only in this instance**                                                                                                                                
  #### Connection to HANA instance                                                                                                                                                           
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Connect to system db using hdbsql|server side|/usr/sap/H00/HDB00/exe/hdbsql -i 00 -d SYSTEMDB -u SYSTEM|                                                                                  
  |Connect to tenant using hdbsql|server side|/usr/sap/H00/HDB00/exe/hdbsql -i 00 -d H00 -u SYSTEM|                                                                                          
  |Connect to system db using hdbsql|client side (experimental)|hdbsql -n hce -i 00 -d SYSTEMDB -u SYSTEM|                                                                                   
  |Connect to tenant using hdbsql|client side (experimental)|hdbsql -n hce -i 00 -d H00 -u SYSTEM|                                                                                           
  #### Post Install step                                                                                                                                                                     
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |Add a script server|to database H00|/usr/sap/H00/HDB00/exe/hdbsql -i 00 -d SYSTEMDB -u SYSTEM "ALTER DATABASE H00 ADD 'scriptserver'"|                                                    
  #### APL files on server                                                                                                                                                                   
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |List plugin folders on server||ls -la /hana/shared/H00/exe/linuxx86_64/plugins|                                                                                                           
  |List APL files on server||ls -la /hana/shared/H00/exe/linuxx86_64/plugins/sap_afl_sdk_apl*|                                                                                               
  |List APL SQLautocontent on server||ls -la /hana/shared/H00/exe/linuxx86_64/plugins/sap_afl_sdk_apl*/aflpm_autoexec*.sql|                                                                  
  #### HANA Traces                                                                                                                                                                           
  | | | |                                                                                                                                                                                    
  |---|---|---|                                                                                                                                                                              
  |List traces on server|of database H00|ls -la /hana/mounts/trace/hana/DB_H00|                                                                                                              
  |List other traces on server||ls -la /hana/mounts/trace/hana|                                                                                                                              
