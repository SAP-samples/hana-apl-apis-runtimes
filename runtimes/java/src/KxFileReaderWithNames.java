// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxFileReaderWithNames.java
// Author.......: 
// Created......: Wed Jan 08 12:22:51 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.io.*;
import java.lang.*;
import java.util.*;

/**
 * Reads variable names on the first line of input file.
 * @see KxJRT.KxFileReader KxFileReader
 */
public class KxFileReaderWithNames extends KxFileReader 
	implements IKxJModelInputWithNames {

	private String[] mVariables = null;

	/**
	 * @see KxJRT.KxFileReader#KxFileReader(String, String) KxFileReader
	 **/
	public KxFileReaderWithNames( String iFilePath, String iSeparator ) {
		super( iFilePath, iSeparator );
		init();
		setName(getVariables());
	}
	
	private void init() { 
		String lFirstLine = null;
		try {
			lFirstLine = mBuffer.readLine();
		}
		catch ( IOException e ) {
			throw new RuntimeException("Uniniatilzed buffer for current reader\n");
		}
		if (lFirstLine != null && !lFirstLine.equals("")) {
			KxSmartTokenizer lSt = new KxSmartTokenizer(lFirstLine, mSeparator);
			int lFieldsCount = lSt.countTokens();
			mFields = new String[lFieldsCount];
			mVariables = new String[lFieldsCount];
			KxLog.getInstance().print("Head file :\n");
			for( int i=0; lSt.hasMoreTokens(); i++ ) {
				mVariables[i] = lSt.nextToken();
				KxLog.getInstance().print(mVariables[i]+",");
			}
			KxLog.getInstance().print("\n");
		}
		else {
			KxLog.getInstance().print("First line is not valid or empty\n");
			throw new RuntimeException("First line is not valid or empty\n");
		}
	}

	final public String[] getVariables() {
		return mVariables;
	}
	
}
