/* ----------------------------------------------------------------------------
 * Copyright....: (c) SAP 1999-2021
 * Project......:
 * Library......:
 * File.........: Config.h
 * Author.......:
 * Created......: Mon Apr 10 15:59:13 2006
 * Description..:
 * ----------------------------------------------------------------------------
 */


#ifndef _CONFIG_H
#define _CONFIG_H 1

#if defined(_WIN32)
// Added some pragma to remove strange warning that appear
// when switched on /W4
// warning C4786:  identifier was truncated to '255' characters in
// the debug information
#pragma warning(disable : 4786)
#endif

#define KxSTL std

#include <string.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

#include <string>
#include <vector>
#include <map>
#include <sstream>


#define cString KxSTL::string

#define cIntVector KxSTL::vector<int>

#define cFloatVector KxSTL::vector<float>

#define cDoubleVector KxSTL::vector<double>

#define cStringVector KxSTL::vector<cString>

class iKxModel; // forward declaration, defined in iKxModel.h

// Mainly usefull for WIN32
//
// To compile the DLL version of KxCPP, define KX_EXPORT_CPP
// To use the DLL version of KxCPP, define KX_IMPORT_CPP
// To compile or use the static version, no define required.
//

#ifndef FLT_MAX
#define FLT_MAX 3.402823466e+38F
#endif

#if defined(KX_EXPORT_CPP)
#define KX_CPP_API __declspec(dllexport)

#else
#if defined(KX_IMPORT_CPP)
#define KX_CPP_API _declspec(dllimport)

#else
#define KX_CPP_API
#endif
#endif


#endif //  _CONFIG_H
