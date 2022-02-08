/* ----------------------------------------------------------------------------
 * Copyright....: (c) SAP 1999-2021
 * Project......: KxCRT
 * Library......: 
 * File.........: KxCppRTModel.h
 * Author.......: 
 * Created......: Mon Apr 10 16:50:00 2006
 * Description..: Framework for the C++ generated code
 * ----------------------------------------------------------------------------
 */


#ifndef _cKXCPPRTMODEL_H
#define _cKXCPPRTMODEL_H 1

#include "Config.h"
#include "KxCppRTValue.h"


/**
 * Intrerface allows feed models with values. It provides services that
 * allows the model to access values by rank (KMX generated codes use the
 * variable rank internally), but it allows the external environment to set
 * the values using the names of the input variables.
 */
class KX_CPP_API KxCppRTCase {
public:
	virtual ~KxCppRTCase() {};
/**
 * setValue
 * is used by the calling program to fill the input case with proper values
 * associated with variable names. This method is also used by the model in 
 * order to fill the proper output value.
 */
    virtual void setValue(KxSTL::string const& iName,
						  KxCppRTValue const& iValue) = 0;
/**
 * getValue
 * is used by the model in order to get the value associated by the variable
 * of rank from the input case provided by the integrator.
 * @return value stored at the specified index
 */
    virtual const KxCppRTValue& getValue(unsigned int i) const = 0;
/**
 * can be used by the external program in order to get back the generated value
 * from the model in the output case.
 * @return value stored for the variable name
 */
    virtual const KxCppRTValue& getValueFromName(KxSTL::string const& iName) 
		const = 0;
};

/**
 * Each generated model implements a generic interface called "KxCppRTModel".
 */
class KX_CPP_API KxCppRTModel
{
 public:
	virtual ~KxCppRTModel() {};

	/**
	 * Specifies the model name.
	 * @return the model name.
	 */   
	virtual const KxSTL::string& getModelName() const = 0;

	/**
	 * Specifies the input variables the model needs.
	 * @return vector of input variable names.
	 */   
	virtual const cStringVector& getModelInputVariables() const = 0;

	/**
	 * Specifies the output variables generated by the model.
	 * @return vector of output variable names. 
	 */
	virtual const cStringVector& getModelOutputVariables() const = 0;
	
	/**
	 * Apply this model on a data row.
	 * @param iInput object providing input variables value.
	 * @param oOutput object providing output variables value.
	 */
	virtual void apply(KxCppRTCase const& iInput, KxCppRTCase& iOutput) const = 0;
};

//#include "KxCppRTModelManager.h"


#endif