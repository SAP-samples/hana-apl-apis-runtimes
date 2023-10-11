/* ----------------------------------------------------------------------------
 * Copyright....: (c) SAP 1999-2021
 * Project......: 
 * Library......: 
 * File.........: KxCppRTUtilities.h
 * Author.......: 
 * Created......: Tue Mar 09 17:59:32 2010
 * Description..:
 * ----------------------------------------------------------------------------
 */

#ifndef _cKXCPPRTUTILITIES_H
#define _cKXCPPRTUTILITIES_H 1

#include "Config.h"

#ifndef KX_LINESIZE
#define KX_LINESIZE 2048
#endif
#ifndef KX_FIELDSEPARATOR
#define KX_FIELDSEPARATOR ",;\t"
#endif
#ifndef KX_TRIMEDCHAR
#define KX_TRIMEDCHAR " \t"
#endif
#ifndef KX_FIELDDATESEPARATOR
#define KX_FIELDDATESEPARATOR ",-./: "
#endif


#define KXEN_S_OK 		0
#define KXEN_S_FALSE	1
#define KXEN_E_INVALIDARG	-1

void KX_CPP_API KxStringTrim(const char* iWord, size_t iLeft, size_t iLength,
				  const char* iSeparators, size_t* oLeft, size_t* oLength);

long KX_CPP_API KxStringTokenSTL(const char* iLine, size_t iLeft, const char* iSeparators,
					  size_t* oLength);

long KX_CPP_API KxStringSplitNoDupSTL(cStringVector	&oWords,
						   cString iLine,
						   const char* iSeparators,
						   const char* iTrimedChars);

int KX_CPP_API KxGetStringSTL( FILE* iFile, cString& oString);

double KX_CPP_API KxConvertToDouble(const char* iValue, bool& oMissing);

#endif
