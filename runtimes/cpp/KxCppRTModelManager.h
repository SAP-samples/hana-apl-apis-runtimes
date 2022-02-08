// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxCppRTModelManager.h
// Author.......: 
// Created......: Fri Jun 02 17:05:01 2006
// Description..: 
// ----------------------------------------------------------------------------


#ifndef _KXCPPRTMODELMANAGER_H
#define _KXCPPRTMODELMANAGER_H 1

#include "KxCppRTModel.h"


struct sPrivateData;

/**
 * model manager returns an KxCppRTModel 
 */
class KX_CPP_API KxCppRTModelManager 
{
public:

	~KxCppRTModelManager ();

	static KxCppRTModelManager& instance();

	/**
	 * Register extern model in the map 
	 */
	void registerModel(KxSTL::string const& iModelName, KxCppRTModel* iModelPtr);
	
	/**
	 * Static method which returns model
	 */
	static const KxCppRTModel& getKxModel (KxSTL::string const& iModelName);

	/**
	 * Return the model list name
	 */
	KxSTL::vector<KxSTL::string> getListModel();

private:
	KxCppRTModelManager ();

	const KxCppRTModel& getModel (KxSTL::string const& iModelName);

	struct sPrivateData *mData;
};

#endif /* _KXCPPRTMODELMANAGER_H */

