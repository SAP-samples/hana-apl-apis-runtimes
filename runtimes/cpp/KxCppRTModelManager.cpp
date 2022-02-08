// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxModelManager.cpp
// Author.......: 
// Created......: Fri Jun 02 17:03:33 2006
// Description..: 
// ----------------------------------------------------------------------------

#include "KxCppRTModelManager.h"


struct sPrivateData {
	KxSTL::map< KxSTL::string, KxCppRTModel* > mModelFactory;
};

KxCppRTModelManager::KxCppRTModelManager()
{
	mData = new sPrivateData();
}

KxCppRTModelManager::~KxCppRTModelManager()
{
	delete mData;
}

void
KxCppRTModelManager::registerModel(KxSTL::string const& iModelName,
								   KxCppRTModel* iModelPtr)
{
	mData->mModelFactory[iModelName] = iModelPtr;
}

const KxCppRTModel& 
KxCppRTModelManager::getKxModel (KxSTL::string const& iModelName) 
{
	return instance().getModel(iModelName);
}


const KxCppRTModel&
KxCppRTModelManager::getModel (KxSTL::string const& iModelName) 
{
	KxSTL::map< KxSTL::string, KxCppRTModel* >::const_iterator lIter =
		mData->mModelFactory.find (iModelName);
	if (lIter == mData->mModelFactory.end())
	{
		throw "model not found";
	}
	return *((*lIter).second);
}


KxSTL::vector<KxSTL::string>
KxCppRTModelManager::getListModel()
{
	KxSTL::map< KxSTL::string, KxCppRTModel* >::const_iterator lIter =
		mData->mModelFactory.begin();
	KxSTL::vector<KxSTL::string> lVectModelName;
	while(lIter != mData->mModelFactory.end())
	{
		lVectModelName.push_back((*lIter).first);
		lIter++;
	}
	return lVectModelName;
}


KxCppRTModelManager&
KxCppRTModelManager::instance()
{
	static KxCppRTModelManager lSingleton;
	return lSingleton; 
}
