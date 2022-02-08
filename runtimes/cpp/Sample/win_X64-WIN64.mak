# ----------------------------------------------------------------------------
# Copyright....: (c) SAP 1999-2021
# Project......: 
# Library......: 
# File.........: win.mak
# Author.......: 
# Created......: Tue Mar 09 16:51:38 2010
# Description..: 
# 
# CVS infos....: 
# .............. $Id: win_X64-WIN64.mak,v 1.2 2012/05/30 10:28:17 port Exp $
# .............. $Date: 2012/05/30 10:28:17 $
# .............. $Revision: 1.2 $
# ----------------------------------------------------------------------------

# Some macros for SUN OS compiler
COMPILER =cl /EHsc /O2 -DNDEBUG /nologo /MT
COMPILER_FLAGS =/LD /EHsc /W3 /DKX_EXPORT_CPP /DWIN32
LINK_EXE = link /nologo /machine:X64 /INCREMENTAL:NO
RM=del
CP=copy

# Name of the model to be used in the sample
MODEL_FILE=ExportedModelInCPP

# Model Object file
MODEL_OBJECT=$(MODEL_FILE).obj
# SAP Automated Analytics C++ Runtime objects
KXCPPRT_OBJS=KxCppRTValue.obj KxCppRTModelManager.obj KxCppRTUtilities.obj

# generic rules.
.cpp.obj:
	$(COMPILER) $(COMPILER_FLAGS) -c $<

# Main target
all : before clean modelapply

modelapply: main.obj $(KXCPPRT_OBJS) $(MODEL_OBJECT)
	$(LINK_EXE) /out:modelapply.exe main.obj $(KXCPPRT_OBJS) $(MODEL_OBJECT)

# additional dependencies
KxCppRTModelManager.cpp: KxCppRTModelManager.h
KxCppRTValue.cpp: KxCppRTValue.h
KxCppRTUtilities.cpp: KxCppRTUtilities.h

# import here SAP Automated Analytics C++ runtime objects
before:
	$(CP) ..\*.cpp .
	$(CP) ..\*.h .

# cleanup
clean: 
	$(RM) $(MODEL_OBJECT) $(KXCPPRT_OBJS) main.obj
