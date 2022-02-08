# Purpose
This is a sample of usage of scoring using exported code in C++.
The exported code is in file [ExportedModelInCPP.cpp](ExportedModelInCPP.cpp)

# Prerequisites
* **make** package must be installed
* **g++** package must be installed

## Compilation
-------------------
Use [linux.mak](linux.mak) file to compile this sample. Main target is `all`.

It will copy all needed files, compile them and link the scoring executable ``modelapply``

```Shell
make -f linux.mak all
```

# Usage
Compilation step has generated an executable named ``modelapply``.

This executable manages 2 command line options:
* ``-in``: the path of the input file in csv format
* ``-out``: the path of the output file in csv format

For convenience, a sample data file [Census.csv](Census.csv) and launch script [apply.bat](apply.bat) are provided:

```Shell
./apply.bat
cat output.csv
```