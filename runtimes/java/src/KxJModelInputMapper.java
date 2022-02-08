// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxJModelInputMapper.java
// Author.......: Benoit Rognier
// Created......: Tue Jan 07 18:01:27 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;


import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import KxJRT.DateUtils;

/**
 * This implementation of IKxJModelInput performs the "glue" between data source variables and model variables. Instanciations should be passed to the {@link KxJRT.IKxJModel#apply(IKxJModelInput) apply } method.
 * @see KxJRT.Mapper Mapper
 * @version 1.0
 */
public class KxJModelInputMapper implements IKxJModelInput {
	
	/**
	 * Mapper instance used for indirection.
	 * @see KxJRT.Mapper Mapper
	 */ 
	private Mapper mMapper = null;

	/**
	 * Data source provider.
	 * @see KxJRT.IKxJModelInputWithNames IKxJModelInputWithNames
	 */
	private IKxJModelInputWithNames mKxInputWithNames = null;
	
	/**
	 * @param iIKxInputWithNames data source variable names and values provider
	 * @param iKxJModel model variable names provider
	 * @see KxJRT.IKxJModelInputWithNames#getVariables() getVariables
	 * @see KxJRT.IKxJModel#getModelInputVariables() getModelInputVariables
	 */
	public KxJModelInputMapper( IKxJModelInputWithNames iIKxInputWithNames, 
								IKxJModel iKxJModel ) {
	
		mKxInputWithNames = iIKxInputWithNames;
		mMapper = new Mapper( iIKxInputWithNames.getVariables(), 
							  iKxJModel.getModelInputVariables() );
	}
	
	public boolean isEmpty( int iVariableIndex, String iMissingString ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.isEmpty( lIdx,
										  iMissingString );
	}

	public int intValue( int iVariableIndex ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.intValue(lIdx);
	}

	public float floatValue( int iVariableIndex ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.floatValue(lIdx);
	}

	public double doubleValue( int iVariableIndex ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.doubleValue(lIdx);
	}

	public String stringValue( int iVariableIndex ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.stringValue(lIdx);
	}

	public Date dateValue( int iVariableIndex ) {
		int lIdx = mMapper.getIndex(iVariableIndex);
		return mKxInputWithNames.dateValue(lIdx);
	}
}
