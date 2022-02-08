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


/**
 * Model input with variable names.
 * Feed it with {@link #initFields(String)} for each line to be processed.
 */
public class KxInputReaderWithNames extends KxInputReader
		implements IKxJModelInputWithNames {

	protected String[] mVariables= null;

	private int mKeyPosition;
	/**
	 * @param iSeparator string that separates two values
	 */
	public KxInputReaderWithNames(String iDataSeparator, String iFirstLine, String iFirstLineSeparator, String iKey) {
		super(iDataSeparator);
		KxSmartTokenizer lSt = new KxSmartTokenizer(iFirstLine, iFirstLineSeparator);
		mVariables = new String[lSt.countTokens()];
		for( int i=0; i < lSt.countTokens(); i++ ) {
			mVariables[i] = lSt.nextToken();
			if (mVariables[i].equals(iKey)) {
				mKeyPosition = i;
			}
		}
	}
	
	@Override
	public String[] getVariables() {
		return mVariables;
	}
	
	public int getKeyPosition() {
		return mKeyPosition;
	}

}
