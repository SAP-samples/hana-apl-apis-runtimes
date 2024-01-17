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

#include "KxCppRTValue.h"
#include "KxCppRTUtilities.h"
#include "DateUtilities.h"

#include <stdio.h>

struct sValueData {
	KxSTL::string 	mValue;

	sValueData() {}
	sValueData(KxSTL::string const& iValue) : mValue(iValue) {}
	sValueData(const char* iValue) : mValue(iValue) {}
	sValueData(sValueData const& iOther) : mValue(iOther.mValue) {}
};

struct sDateRepresentation {
	int 	mYear;
	int 	mMonth;
	int 	mDay;
	int 	mHour;
	int 	mMinute;
	int 	mSecond;
	int 	mMuSecond;
	bool 	mIsADateTime;

	sDateRepresentation() {}
	sDateRepresentation(int iYear,int iMonth, int iDay) :
		mYear(iYear), mMonth(iMonth), mDay(iDay), mHour(0), mMinute(0),
		mSecond(0), mMuSecond(0),  mIsADateTime(false) {}

	sDateRepresentation(int iYear,int iMonth, int iDay, int iHour, int iMinute,
						int iSecond, int iMuSecond) :
		mYear(iYear), mMonth(iMonth), mDay(iDay), mHour(iHour),
		mMinute(iMinute), mSecond(iSecond), mMuSecond(iMuSecond),
		mIsADateTime(true) {}

	sDateRepresentation(sDateRepresentation const& iOther) :
		mYear(iOther.mYear), mMonth(iOther.mMonth), mDay(iOther.mDay),
		mHour(iOther.mHour), mMinute(iOther.mMinute), mSecond(iOther.mSecond),
		mMuSecond(iOther.mMuSecond), mIsADateTime(iOther.mIsADateTime) {}
};

KxCppRTValue::KxCppRTValue()
{
	mValueData = new sValueData();
	mDate = new sDateRepresentation();
}

KxCppRTValue::KxCppRTValue(KxSTL::string const& iValue)
{
	mValueData = new sValueData(iValue);

	KxSTL::vector<KxSTL::string> lFields;

	KxStringSplitNoDupSTL(lFields,
						  iValue,
						  KX_FIELDDATESEPARATOR,
						  KX_TRIMEDCHAR);

	if (lFields.size() == 3)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()));
	}
	else if (lFields.size() == 6)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()),
										(int)atoi(lFields[3].c_str()),
										(int)atoi(lFields[4].c_str()),
										(int)atoi(lFields[5].c_str()),
										0);
	}
	else if (lFields.size() > 6)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()),
										(int)atoi(lFields[3].c_str()),
										(int)atoi(lFields[4].c_str()),
										(int)atoi(lFields[5].c_str()),
										(int)atoi(lFields[6].c_str()));
	}
	else
	{
		mDate = new sDateRepresentation();
	}
}
	
KxCppRTValue::KxCppRTValue(const char* iValue)
{
	mValueData = new sValueData(iValue);
	KxSTL::vector<KxSTL::string> lFields;

	KxStringSplitNoDupSTL(lFields,
						  iValue,
						  KX_FIELDDATESEPARATOR,
						  KX_TRIMEDCHAR);
	if (lFields.size() == 3)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()));
	}
	else if (lFields.size() == 6)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()),
										(int)atoi(lFields[3].c_str()),
										(int)atoi(lFields[4].c_str()),
										(int)atoi(lFields[5].c_str()),
										0);
	}
	else if (lFields.size() > 6)
	{
		mDate = new sDateRepresentation((int)atoi(lFields[0].c_str()),
										(int)atoi(lFields[1].c_str()),
										(int)atoi(lFields[2].c_str()),
										(int)atoi(lFields[3].c_str()),
										(int)atoi(lFields[4].c_str()),
										(int)atoi(lFields[5].c_str()),
										(int)atoi(lFields[6].c_str()));
	}
	else
	{
		mDate = new sDateRepresentation();
	}
}

KxCppRTValue::KxCppRTValue(KxCppRTValue const& iOther)
{
	mValueData = new sValueData(*(iOther.mValueData));
	mDate = new sDateRepresentation(*(iOther.mDate));
}


KxCppRTValue::~KxCppRTValue()
{
	delete mValueData;
	delete mDate;
}

KxSTL::string const&
KxCppRTValue::getValue() const
{
	return mValueData->mValue;
}

KxSTL::string
KxCppRTValue::getDayOfWeek() const
{
    const int lBuffersize = 2;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getDOW(mDate->mYear, mDate->mMonth, mDate->mDay));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getDayOfMonth() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mDay);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getDayOfYear() const
{
    const int lBuffersize = 4;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getDOY(mDate->mYear, mDate->mMonth, mDate->mDay));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getWeekOfMonth() const
{
    const int lBuffersize = 2;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getWOM(mDate->mYear, mDate->mMonth, mDate->mDay));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getWeekOfYear() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getWOY(mDate->mYear, mDate->mMonth, mDate->mDay));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getMonthOfQuarter() const
{
    const int lBuffersize = 2;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getMOQ(mDate->mMonth));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getMonthOfYear() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mMonth);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getYear() const
{
    const int lBuffersize = 5;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mYear);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getQuarter() const
{
    const int lBuffersize = 2;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", getQOY(mDate->mMonth));
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getHour() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mHour);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getMinute() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mMinute);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getSecond() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mSecond);
	return KxSTL::string(lValue);
}

KxSTL::string
KxCppRTValue::getMicroSecond() const
{
    const int lBuffersize = 3;
	char lValue[lBuffersize];
	snprintf(lValue, lBuffersize, "%d", mDate->mMuSecond);
	return KxSTL::string(lValue);
}


KxCppRTValue& KxCppRTValue::operator=(KxCppRTValue const& iOther)
{
	*mValueData = *(iOther.mValueData);
	*mDate = *(iOther.mDate);
	return *this;
}
