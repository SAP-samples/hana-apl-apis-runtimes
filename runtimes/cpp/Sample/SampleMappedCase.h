// ----------------------------------------------------------------------------
// Copyright....: (c)SAP 1999-2021
// Project......: 
// Library......: 
// File.........: SampleMappedCase.h
// Author.......: 
// Created......: Fri Apr 21 12:18:55 2006
// Description..: Simple implementation of iKxCase for library Sample
// ----------------------------------------------------------------------------

#ifndef _SAMPLEMAPPEDCASE_
#define _SAMPLEMAPPEDCASE_H 1

#include "KxCppRTModel.h"

class SampleMappedCase : public virtual KxCppRTCase {

 private:
    KxSTL::vector<KxSTL::string> mNames;
    KxSTL::map<KxSTL::string, KxCppRTValue> mValues;

 public:
    SampleMappedCase();

    SampleMappedCase(KxSTL::vector<KxSTL::string> const& iNames);

    virtual ~SampleMappedCase();

    void setValue(KxSTL::string const& iName, KxCppRTValue const& iValue);

    const KxCppRTValue& getValue(unsigned int i) const;

    const KxCppRTValue& getValueFromName(KxSTL::string const& iName) const;

	unsigned int getSize() const;
};


#endif // _SAMPLEMAPPEDCASE_H
