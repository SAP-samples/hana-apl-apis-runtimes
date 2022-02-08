/* ----------------------------------------------------------------------------
 * Copyright....: (c) SAP 1999-2021
 * Project......: 
 * Library......: 
 * File.........: KxCppRTValue.h
 * Author.......: 
 * Created......: Fri Apr 21 11:12:12 2006
 * Description..:
 * ----------------------------------------------------------------------------
 */

#ifndef _KXCPPRTVALUE_H
#define _KXCPPRTVALUE_H 1

#include "Config.h"

struct sValueData;

class KX_CPP_API KxCppRTValue
{
 public:
	KxCppRTValue(KxCppRTValue const& iOther);
	KxCppRTValue();
	KxCppRTValue(KxSTL::string const& iValue);
	
	KxCppRTValue(const char* iValue);

	~KxCppRTValue();

	KxSTL::string const& getValue() const;

	KxSTL::string getDayOfWeek() const;
	KxSTL::string getDayOfMonth() const;
	KxSTL::string getDayOfYear() const;
	KxSTL::string getWeekOfMonth() const;
	KxSTL::string getWeekOfYear() const;
	KxSTL::string getMonthOfQuarter() const;
	KxSTL::string getMonthOfYear() const;
	KxSTL::string getYear() const;
	KxSTL::string getQuarter() const;
	KxSTL::string getHour() const;
	KxSTL::string getMinute() const;
	KxSTL::string getSecond() const;
	KxSTL::string getMicroSecond() const;

	KxCppRTValue& operator=(KxCppRTValue const& iOther);

 private:
	struct sValueData*	mValueData;
	struct sDateRepresentation*	mDate;
};

#endif /* _CVALUE_H */
