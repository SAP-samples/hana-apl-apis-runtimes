// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxInputReader.java
// Author.......: 
// Created......: Tue Mar 18 11:32:33 2008
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.io.*;
import java.lang.*;
import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParseException;

/**
 * Basic implementation of {@link KxJRT.IKxJModelInput IKxJModelInput } that reads a flat file.
 * @see KxJRT.KxJApplyOnFile KxJApplyOnFile
 */
public class KxInputReader implements IKxJModelInput {

	private int mRowCounter=0;
	private int mMissing=0;

	protected String mSeparator = null;
	
	protected String[] mFields = null;

	/**
	 * @param iSeparator string that separates two values
	 */
	public KxInputReader(String iSeparator) {
		mSeparator = iSeparator;
	}
	
	public void initFields( String iLine ) {
		KxSmartTokenizer lSt = new KxSmartTokenizer(iLine, 
													mSeparator);
		KxLog.getInstance().print("Init count fields\n");
		int lFieldsCount = lSt.countTokens();
		mFields = new String[lFieldsCount];
		KxLog.getInstance().print("Count fields is "+lFieldsCount+"\n");
		for( int i=0; i<lFieldsCount; i++ ) {
			String lNextToken = lSt.nextToken();
			try {
				if (lNextToken.equals("")) {
					printEmptyField(i);
				}
				mFields[i] = lNextToken.trim();
			}
			catch (ArrayIndexOutOfBoundsException a) {
				KxLog.getInstance().print("Number of fields exceeds\n");
				System.err.println("Number of fields is not valid at line "
				+ mRowCounter + ".");
			}
		}
	}
	
	private void printEmptyField( int iFieldIndex ) {
		KxLog.getInstance().print("warning : empty value for fields " + 
								  iFieldIndex +" at line " + 
								  mRowCounter + "." );
	}

	public boolean isEmpty( int iVariableIndex, String iMissingString ) {
		String lValue = mFields[ iVariableIndex ];
		if( lValue == null 
			|| lValue.equals("") 
			|| lValue.equals(iMissingString)
			|| mMissing == 1 ) {
			mMissing = 0;
			return true;
		}
		return false;
	} 
	
	public int intValue( int iVariableIndex ) {		
		int lValue = 0;
		try {
			String lSValue = mFields[iVariableIndex];
			try {
				lValue = (Integer.valueOf(lSValue)).intValue();
				mMissing = 0;
			}
			catch( NumberFormatException e ) {
				lValue = 0;
				mMissing = 1;
			}
		}
		catch (NullPointerException a) {
			KxLog.getInstance().print("missing fields in data set line\n");
			System.err.println( "error : missing fields at line "
								+ mRowCounter + "." );
		}
		return lValue;
	}
	
	public float floatValue( int iVariableIndex ) {	
		float lValue = (float)0.0;
		try {
			String lSValue = mFields[iVariableIndex];
			try {
				lValue = (Float.valueOf(lSValue)).floatValue();
				mMissing = 0;
			}
			catch( NumberFormatException e ) {
				lValue = Float.NaN;
				mMissing = 1;
			}
		}
		catch (NullPointerException a) {
			KxLog.getInstance().print("missing fields in data set line\n");
			System.err.println( "error : missing fields at line "
								+ mRowCounter + "." );
		}
		return lValue;
	}
	
	public double doubleValue( int iVariableIndex ) {	
		double lValue = 0.0;
		try {
			String lSValue = mFields[iVariableIndex];
			try {
				lValue = (Double.valueOf(lSValue)).doubleValue();
				mMissing = 0;
			}
			catch( NumberFormatException e ) {
				lValue = Double.NaN;
				mMissing = 1;
			}
		}
		catch (NullPointerException a) {
			KxLog.getInstance().print("missing fields in data set line\n");
			System.err.println( "error : missing fields at line "
								+ mRowCounter + "." );
		}
		return lValue;
	}
	
	public String stringValue( int iVariableIndex ) {
		try {
			return mFields[iVariableIndex];
		}
		catch (NullPointerException a) {
			KxLog.getInstance().print("missing fields in data set line\n");
			System.err.println( "error : missing fields at line "
								+ mRowCounter + "." );
			return "";
		}
	}	

	public Date dateValue( int iVariableIndex ) {
		try {
			String lSValue = mFields[iVariableIndex];
			mMissing = 0;
			try	{
				return DateUtils.getISODateFromString(lSValue);
			} catch (ParseException lExceptionDateTime) {
				mMissing = 1;
				return null;
			}
		}
		catch (NullPointerException a) {
			KxLog.getInstance().print("missing fields in data set line\n");
			System.err.println( "error : missing fields at line "
								+ mRowCounter + "." );
			return null;
		}
	}	
}
