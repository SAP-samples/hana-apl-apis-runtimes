// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: SampleMappedCase.cpp
// Author.......: 
// Created......: Fri Apr 21 12:18:55 2006
// Description..: Simple implementation of iKxCase for library Sample
// ----------------------------------------------------------------------------

#include "SampleMappedCase.h"

SampleMappedCase::SampleMappedCase()
{}

SampleMappedCase::SampleMappedCase(KxSTL::vector<KxSTL::string> const& iNames)
	: mNames(iNames)
{}

SampleMappedCase::~SampleMappedCase()
{
	mNames.clear();
	mValues.clear();
}	

void
SampleMappedCase::setValue(KxSTL::string const& iName, KxCppRTValue const& iValue)
{
	mValues[iName] = iValue;
}

const KxCppRTValue&
SampleMappedCase::getValue(unsigned int i) const
{
	if (mNames.size() <= i)
	{
		throw "invalid value index";
	}
	KxSTL::map< KxSTL::string, KxCppRTValue >::const_iterator lIter =
		mValues.find (mNames[i]);
	if (lIter == mValues.end())
	{
		throw "no defined value for index";
	}
	return (*lIter).second;
}

const KxCppRTValue&
SampleMappedCase::getValueFromName(KxSTL::string const& iName) const
{
	KxSTL::map< KxSTL::string, KxCppRTValue >::const_iterator lIter =
		mValues.find (iName);
	if (lIter == mValues.end())
	{
		throw "no defined value for name";
	}
	return (*lIter).second;
}

unsigned int
SampleMappedCase::getSize() const
{
	return mNames.size();
}
