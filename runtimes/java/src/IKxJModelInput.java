// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: IKxJModelInput.java
// Author.......: 
// Created......: Tue Jan 07 17:38:33 2003
// Description..: Interface for Auutomated Analytics Java Model's Input
// ----------------------------------------------------------------------------

package KxJRT;
import java.util.Date;

/**
 * The Automatic Analytics Java model input interface. 
 * A class implementing this interface is able to provide the model with input data values it needs.
 * @see KxJRT.IKxJModel#apply(IKxJModelInput) apply
 * @version 1.0
 */
public interface IKxJModelInput {

	/**
	 * Called from within the model to know whether current input is empty.
	 * @param iVariableIndex index of input variable.
	 * @param iMissingString the missing string the model was trained with
	 * @return true if current value is empty, false otherwize.
	 */
	public boolean isEmpty( int iVariableIndex, String iMissingString );
	
	/**
	 * Called from within the model, converts input variable with index 
	 * iVariableIndex to int value.
	 * @param iVariableIndex index of input variable.
	 * @return int value of input variable.
	 */
	public int intValue( int iVariableIndex );

	/**
	 * Called from within the model, converts input variable with index 
	 * iVariableIndex to float value.
	 * @param iVariableIndex index of input variable.
	 * @return float value of input variable.
	 */
	public float floatValue( int iVariableIndex );

	/**
	 * Called from within the model, converts input variable with index 
	 * iVariableIndex to double value.
	 * @param iVariableIndex index of input variable.
	 * @return double value of input variable.
	 */
	public double doubleValue( int iVariableIndex );

	/**
	 * Called from within the model, converts input variable with index 
	 * iVariableIndex to String value.
	 * @param iVariableIndex index of input variable.
	 * @return String value of input variable.
	 */
	public String stringValue( int iVariableIndex );
	
	/**
	 * Called from within the model, converts input variable with index 
	 * iVariableIndex to Date value.
	 * @param iVariableIndex index of input variable.
	 * @return Date value of input variable.
	 */
	public Date dateValue( int iVariableIndex );
}
