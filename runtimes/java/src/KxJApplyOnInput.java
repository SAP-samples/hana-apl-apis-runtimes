// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxJApplyOnInput.java
// Author.......: 
// Created......: Tue Mar 18 11:29:49 2008
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.io.*;
import java.lang.*;
import java.util.TreeMap;

/**
 * Applies a <a href="http://www.kxen.com">Automatic Analytics</a> Java model on a line
 * @see KxJRT.KxInputReader KxInputReader
 */
public class KxJApplyOnInput {
	
	private String 				mInput = null;
	private String 				mVarName = null;
	private String 				mOutFilePath = null;
	private String 				mModelClassName = null;
	private String 				mSeparator = null;

	private PrintStream 		mOutStream = null;
	private KxInputReader 		mInStream = null;
	private IKxJModelInput 		mKxJModelInput = null;
	
	private IKxJModel			mKxJModel = null;
	
	/**
	 * @param iInput input line
	 * @param iOutFilePath path to output file
	 * @param iModelClassName name of model's class
	 * @param iSeparator string that separates two values
	 */
	public KxJApplyOnInput(String	iInput,
						   String	iVarName,
						   String	iOutFilePath,
						   String	iModelClassName,
						   String	iSeparator) {
		mInput = iInput;
		mVarName = iVarName;
		mOutFilePath = iOutFilePath;
		mModelClassName = iModelClassName;
		mSeparator = iSeparator;
	
		initModel();
		initStreams();
		apply();
	}
	
	private void initModel() {
		mKxJModel = KxJModelFactory.getKxJModel( mModelClassName );
	}

	private void initStreams() {
		try {
			mInStream = new KxInputReader(mSeparator);
			mKxJModelInput = (IKxJModelInput) mInStream;
		}
		catch ( Exception e ) {
			KxLog.getInstance().print("cannot instantiate in stream:"
									  +e.getMessage());
			throw new RuntimeException("Error during the instantiation of the in stream");
		}
		try {
			if( null != mOutFilePath ) {
				FileOutputStream lOut = new FileOutputStream( mOutFilePath );
				mOutStream = new PrintStream( lOut );
			}
			else {
				mOutStream = System.out;
			}

			String[] lOutVariables = mKxJModel.getModelOutputVariables();
			for( int i=0; i<lOutVariables.length; i++ ) {
				mOutStream.print( lOutVariables[i] );
				if( i+1<lOutVariables.length ) {
					mOutStream.print(mSeparator);
				}
			}
			mOutStream.println();
		}
		catch ( Exception e ) {
			KxLog.getInstance().print("cannot instantiate in stream:"
									  +e.getMessage());
			throw new RuntimeException("Error during the instantiation of the in stream");
		}
	}

	private void apply() {

		KxSmartTokenizer lSt = new KxSmartTokenizer(mVarName, 
													mSeparator);
		int lVarsCount = lSt.countTokens();
		String[] lVariables = new String[lVarsCount];
		for (int i=0; i < lVarsCount; i++) {
			String lNextToken = lSt.nextToken();
			lVariables[i] = lNextToken.trim();
		}

		lSt = new KxSmartTokenizer(mInput, 
								   mSeparator);
		int lFieldsCount = lSt.countTokens();
		String[] lFields = new String[lFieldsCount];
		for (int i=0; i < lFieldsCount; i++) {
			String lNextToken = lSt.nextToken();
			lFields[i] = lNextToken.trim();
		}
		
		TreeMap lMap = new TreeMap();
		for (int i=0; i < lVariables.length ; i++) {
			lMap.put(lVariables[i], lFields[i]);
		}
		

		String[] lModelVars = mKxJModel.getModelInputVariables();
		String lInput = new String();

		for( int i=0; i < lModelVars.length; i++ ) {
			if (i !=0) {
				lInput += mSeparator;
			}
			lInput += (String)lMap.get(lModelVars[i]);
		}

		mInStream.initFields(lInput);
		Object[] lResults = mKxJModel.apply(mKxJModelInput);

		for (int i=0; i<lResults.length; i++) {
			mOutStream.print(lResults[i].toString());
			if (i+1<lResults.length) {
				mOutStream.print(mSeparator);
			}
		}
		mOutStream.println();
	}
}
