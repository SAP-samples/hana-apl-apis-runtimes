// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxFileReader.java
// Author.......: 
// Created......: Wed Jan 08 12:22:51 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PushbackInputStream;
import java.util.Calendar;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.*;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Basic implementation of {@link KxJRT.IKxJModelInput IKxJModelInput } that reads a flat file.
 * @see KxJRT.KxJApplyOnFile KxJApplyOnFile
 */
public class KxJDBCInput implements IKxJModelInput {
	List<String> mInputList;
	ResultSet mResultSet;
	private boolean mMissing = false;

	/**
	 * @param iVarNames list of variable used by the model
	 * @param iResultSet object that contains the data produced by the given query
	 */
	public KxJDBCInput(String[] iVarNames, ResultSet iResultSet) {
		mInputList = Arrays.asList(iVarNames);
		mResultSet = iResultSet;
	}
	
	/**
	 * @return true when the resultset contains data
	 * @throws SQLException
	 */
	public boolean next() throws SQLException {
		return mResultSet.next();
	}

	/**
	 * print the current values for the variable list used by the model
	 * @throws SQLException
	 */
	public void print() throws SQLException {
		System.out.println("");
		for(int lIdx = 0; lIdx < mInputList.size(); lIdx++) {
			System.out.print(mResultSet.getString(mInputList.get(lIdx)) + " ");
		}
		System.out.println("");
	}

	public boolean isEmpty( int iIndex, String iMissingString ) {
		try {
			String lValue = mResultSet.getString(mInputList.get(iIndex));
			if (lValue == null ||
				lValue.equals("") ||
				lValue.equals(iMissingString) ||
				mMissing)
			{
				mMissing = false;
				return true;
			}
		} catch (SQLException e) {
			mMissing = false;
		}
		return false;
	} 
	
	public int intValue( int iIndex ) {		
		int lValue = 0;
		try {
			lValue = mResultSet.getInt(mInputList.get(iIndex));
			mMissing = false;
		}
		catch( SQLException e ) {
			lValue = 0;
			mMissing = true;
		}
		return lValue;
	}
	
	public float floatValue( int iIndex ) {	
		float lValue = (float)0.0;
		try {
			lValue = mResultSet.getFloat(mInputList.get(iIndex));
			mMissing = false;
		}
		catch( SQLException e ) {
			lValue = (float)0.0;
			mMissing = true;
		}
		return lValue;
	}
	
	public double doubleValue( int iIndex ) {	
		double lValue = 0.0;
		try {
			lValue = mResultSet.getDouble(mInputList.get(iIndex));
			mMissing = false;
		}
		catch( SQLException e ) {
			lValue = 0.0;
			mMissing = true;
		}
		return lValue;
	}
	
	public String stringValue( int iIndex ) {
		String lValue = "";
		try {
			lValue = mResultSet.getString(mInputList.get(iIndex));
			mMissing = false;
		}
		catch( SQLException e ) {
			lValue = "";
			mMissing = true;
		}
		return lValue;
	}	

	public Date dateValue( int iIndex ) {
		Date lValue = null;
		try {
			lValue = mResultSet.getDate(mInputList.get(iIndex));
			mMissing = false;
		}
		catch( SQLException e ) {
			lValue = null;
			mMissing = true;
		}
		return lValue;
	}	
}
