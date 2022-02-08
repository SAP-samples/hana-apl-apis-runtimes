// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: IKxJModelInputWithNames.java
// Author.......: 
// Created......: Tue Jan 07 17:52:08 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

/**
 * The extended Java model input interface. 
 * A class implementing this interface is moreover able to provide variable names of the data source the model is applied on.
 * @see KxJRT.IKxJModelInput IKxJModelInput
 * @see KxJRT.IKxJModel#apply(IKxJModelInput) apply
 * @see KxJRT.KxJModelInputMapper KxJModelInputMapper
 * @version 1.0
 */
public interface IKxJModelInputWithNames extends IKxJModelInput {
	/**
	 * Specifies the input variables the data source can provide to the model.
	 * @return array of available variable names.
	 */
	public String[] getVariables();
}
