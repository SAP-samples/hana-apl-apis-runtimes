# SAP HANA Automated Predictive Library - Samples and Runtimes
[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/hana-apl-apis-runtimes)](https://api.reuse.software/info/github.com/SAP-samples/hana-apl-apis-runtimes)

## Description
This project provides code examples for the SAP HANA Automated Predictive Library (APL). It provides simple APL SQL examples covering all APL APIs, as well as reference implementations of the runtimes needed when predictive models are exported in C++, Java, or JavaScript for real-time scoring.

This repository contains the following:
1. [SQL sample code](sql) of **APL** APIs.
2. Sample data for the sample codes. 
   * For HANA On Premise, the standard HANA import statement or the HANA studio import feature must be used to import the folder [dataForHANAOnPremise](dataForHANAOnPremise).
   * For HANA Cloud, the SAP HANA database explorer import Catalog objects feature must be used to import the archive [dataForHANACloud.tar.gz](dataForHANACloud.tar.gz).
3. Reference implementations of the runtime code needed when exporting a model built by **APL**. Runtime code is provided for the following languages:
   - [C++](runtimes/cpp). Find the details and instructions [here](runtimes/cpp/README.md)
   - [java](runtimes/java). Find the details and instructions [here](runtimes/java/README.md)
   - [javascript](runtimes/javascript). Find the details and instructions [here](runtimes/javascript/README.md)

## Requirements
To use the content, you need access to **SAP HANA Automated Predictive Library** installed on an [**SAP HANA server**](https://www.sap.com/uk/products/hana/what-is-sap-hana.html). Details can be found on our [installation guide](https://help.sap.com/viewer/419fd47c26b345239fdbb5e476a6bc54/2203/en-US).

## Download and Installation
The sample and runtime files can be downloaded and used within the respective user/developer environment, for example, SQL files may be opened and used within the SQL console of SAP HANA studio or SAP HANA database explorer. The sample files don't require an install step for themselves; they can simply be downloaded and then opened in the respective editor.

If you have ve Git installed, clone this repo as shown below, otherwise download the samples as a ZIP file.

```Shell
git clone https://github.com/SAP-samples/hana-apl-apis-runtimes apl_samples
cd apl_samples
```

## Known Issues
None
## How to Get Support
A set of resources about the usage of **APL** is available [in SAP Community](https://community.sap.com/search/?by=updated&ct=blog&q=APL).

[Create an issue](https://github.com/SAP-samples/<repository-name>/issues) in this repository if you find a bug or have questions about the content.
 
For additional support, [ask a question in the community](https://answers.sap.com/questions/ask.html).

## Contributing
If you wish to contribute code, offer fixes or improvements, please send a pull request. Due to legal reasons, contributors will be asked to accept a DCO when they create the first pull request to this project. This happens in an automated fashion during the submission process. SAP uses [the standard DCO text of the Linux Foundation](https://developercertificate.org/).

## License
Copyright (c) 2022 SAP SE or an SAP affiliate company. All rights reserved. This project is licensed under the Apache Software License, version 2.0 except as noted otherwise in the [LICENSE](LICENSES/Apache-2.0.txt) file.
