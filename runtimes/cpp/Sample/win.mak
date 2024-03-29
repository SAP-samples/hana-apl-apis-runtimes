# ----------------------------------------------------------------------------
# Copyright....: (c) SAP 1999-2023
# Project......: 
# Library......: 
# File.........: win.mak
# Author.......: 
# Created......: Tue Mar 09 16:51:38 2010
# Description..:
# ----------------------------------------------------------------------------

# Some macros for SUN OS compiler
COMPILER =cl /EHsc /O2 -DNDEBUG /nologo /MT
COMPILER_FLAGS =/LD /EHsc /W3 /DKX_EXPORT_CPP /DWIN32
MAKE_EXE = link /nologo /machine:Ix86 /INCREMENTAL:NO
RM=rm -f
CP=cp

# Name of the model to be used in the sample
MODEL_FILE=ExportedModelInCPP 

# Model Object file
MODEL_OBJECT=$(MODEL_FILE).obj
# SAP Automated Analytics C++ Runtime objects
KXCPPRT_OBJS=KxCppRTValue.obj KxCppRTModelManager.obj KxCppRTUtilities.obj

# generic rules.
.cpp.obj:
	$(COMPILER) $(COMPILER_FLAGS) -c $<

main.obj: main.cpp
	$(COMPILER) $(COMPILER_FLAGS) -c main.cpp

# Main target
all : before modelapply

modelapply: main.obj $(KXCPPRT_OBJS) $(MODEL_OBJECT)
	$(MAKE_EXE) /out:modelapply.exe main.obj $(KXCPPRT_OBJS) $(MODEL_OBJECT)

# additional dependencies
KxCppRTModelManager.cpp: KxCppRTModelManager.h
KxCppRTValue.cpp: KxCppRTValue.h
KxCppRTUtilities.cpp: KxCppRTUtilities.h

# import here SAP Automated Analytics C++ runtime objects
before:
	$(CP) ../*.cpp .
	$(CP) ../*.h .

# cleanup
clean: 
	$(RM) $(MODEL_OBJECT) $(KXCPPRT_OBJS) main.obj
