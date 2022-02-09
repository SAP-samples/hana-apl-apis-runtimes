<!--- Register repository https://api.reuse.software/register, then add REUSE badge:
[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/hana-apl-apis-runtimes)](https://api.reuse.software/info/github.com/SAP-samples/hana-apl-apis-runtimes)
-->

# SAP HANA Automated Predictive Library - Samples and Runtimes

## Description
This repository contains the following:
1. [SQL sample code](sql) of **APL** APIs.
2. [Sample data](data) for the sample code. The standard HANA import statement or the HANA studio/SAP HANA database explorer import feature must be used to import the data.
3. Reference implementations of the runtime code needed when exporting a model built by **APL**. Runtime code is provided for the following languages:
   - [C++](runtimes/cpp). Find the details and instructions [here](runtimes/cpp/README.md)
   - [java](runtimes/java). Find the details and instructions [here](runtimes/java/README.md)
   - [javascript](runtimes/javascript). Find the details and instructions [here](runtimes/javascript/README.md)

## Requirements
To use the content, you need access to **SAP HANA Automated Predictive Library** installed on an [**SAP HANA server**](https://www.sap.com/uk/products/hana/what-is-sap-hana.html). Details can be found on our [installation guide](https://help.sap.com/viewer/419fd47c26b345239fdbb5e476a6bc54/2203/en-US).

## Download and Installation
The sample and runtime files can be downloaded and used within the respective user/developer environment, for example, SQL files may be opened and used within the SQL console of SAP HANA studio or SAP HANA database explorer. The sample files don't require an install step for themselves; they can simply be downloaded and then opened in the respective editor.

If you have ve Git installed, clone this repo as shown below, otherwise download the samples as ZIP file.

```Shell
git clone https://github.com/SAP-samples/hana-apl-apis-runtimes apl_samples
cd apl_samples
```

## Known Issues
None
## How to Get Support
A set of resources about the usage of **APL** is available [here](https://community.sap.com/search/?by=updated&ct=blog&q=APL)

[Create an issue](https://github.com/SAP-samples/<repository-name>/issues) in this repository if you find a bug or have questions about the content.
 
For additional support, [ask a question in SAP Community](https://answers.sap.com/questions/ask.html).


## License
Copyright (c) 2022 SAP SE or an SAP affiliate company. All rights reserved. This project is licensed under the Apache Software License, version 2.0 except as noted otherwise in the [LICENSE](LICENSES/Apache-2.0.txt) file.
