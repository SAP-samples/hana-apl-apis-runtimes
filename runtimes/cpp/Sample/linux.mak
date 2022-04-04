# ----------------------------------------------------------------------------
# Copyright....: (c) SAP 1999-2021
# Project......: 
# Library......: 
# File.........: linux.mak
# Author.......: 
# Created......: Tue Mar 09 16:40:40 2010
# Description..:
# ----------------------------------------------------------------------------

# Some macros for LINUX compiler
COMPILER = g++ -Wall -DGNU -D_REENTRANT -D__linux__
COMPILER_FLAGS =-O2
LINK_EXE = g++
RM=rm -f
CP=cp

# Name of the model to be used in the sample
MODEL_FILE = ExportedModelInCPP

# Model Object file
MODEL_OBJECT = $(MODEL_FILE).o
# KXEN C++ Runtime objects
KXCPPRT_OBJS = KxCppRTValue.o KxCppRTModelManager.o KxCppRTUtilities.o

# generic rules.
.cpp.o:
	$(COMPILER) $(COMPILER_FLAGS) -c $<

# suppress a warning on minor discrepancy in generated code
$(MODEL_OBJECT): $(MODEL_FILE).cpp
	$(COMPILER) $(COMPILER_FLAGS) -Wno-sign-compare -c $<

main.o: main.cpp	
	$(COMPILER) $(COMPILER_FLAGS) -c main.cpp

# Main target
all : before clean modelapply

modelapply: main.o $(KXCPPRT_OBJS) $(MODEL_OBJECT)
	$(LINK_EXE) -o modelapply main.o $(KXCPPRT_OBJS) $(MODEL_OBJECT)

# additional dependencies
KxCppRTModelManager.cpp: KxCppRTModelManager.h
KxCppRTValue.cpp: KxCppRTValue.h
KxCppRTUtilities.cpp: KxCppRTUtilities.h

# import here KXEN C++ runtime objects
before:
	$(CP) ../*.cpp .
	$(CP) ../*.h .

# cleanup
clean: 
	$(RM) $(MODEL_OBJECT) $(KXCPPRT_OBJS) main.o
