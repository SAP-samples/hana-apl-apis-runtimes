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

/**
 * Basic implementation of {@link KxJRT.IKxJModelInput IKxJModelInput } that reads a flat file.
 * @see KxJRT.KxJApplyOnFile KxJApplyOnFile
 */
public class KxFileReader implements IKxJModelInput {
	private int mRowCounter=0;
	private int mMissing=0;

	protected String mSeparator = null;
	protected BufferedReader mBuffer = null;
	
	protected String[] mFields = null;
	protected String[] mNameFields = null;

	/**
	 * @param iFilePath path to input file
	 * @param iSeparator string that separates two values
	 */
	public KxFileReader( String iFilePath, String iSeparator ) {
		mSeparator = iSeparator;
		try {
			InputStream lFile = new FileInputStream(iFilePath);
			UTF8BomReader lUTF8Reader = new UTF8BomReader(lFile);
			boolean lIsUTF8 = lUTF8Reader.hasUTF8ByteOrderMarker();
			InputStreamReader lStreamReader =
				(lIsUTF8 ? new InputStreamReader(lUTF8Reader, "UTF8")
						: new InputStreamReader(lUTF8Reader));
			mBuffer = new BufferedReader(lStreamReader);
		}
		catch( Exception e ) {
			KxLog.getInstance().print("Error during the open of " + iFilePath + "\n");
			throw new RuntimeException("Error during the open of "+iFilePath);
		};
	}
	
	public void setName(String[] iNames) {
		mNameFields = iNames;
	}
	
	/**
	 * Class used to skip the (optionnal) UTF8 Byte Order Marker at 
	 * the beginning of an UTF8 File.
	 */
	public static class UTF8BomReader extends InputStream {
		/** Internal stream. */
		private PushbackInputStream mStream;
		/** size of Byte Order Marker. */
		final private static int BOM_SIZE = 3;
		/**
		 * Construct a new stream taht will skip UTF8 BOM if any.
		 * @param iStream inner stream to be processed.
		 */
		public UTF8BomReader(InputStream iStream) {
			mStream = new PushbackInputStream(iStream, BOM_SIZE);
		}
		/**
		 * Try to find and skip the BOM.
		 * Should be called once after stream creation.
		 * @return <code>true</code> if the Byte Order Marker has been found.
		 * @throws IOException
		 */
		public boolean hasUTF8ByteOrderMarker() throws IOException {
			byte lBuffer[] = new byte[BOM_SIZE];
			int lResult = mStream.read(lBuffer, 0, BOM_SIZE);
			if ((lResult < BOM_SIZE) || 
					!isUF8BOM(lBuffer[0], lBuffer[1], lBuffer[2])) {
				// not found, reset it
				mStream.unread(lBuffer, 0, lResult);
				return false;
			}
			return true;
		}
		
		/**
		 * @Override
		 */
		public int read() throws IOException {
			return mStream.read();
		}
		/**
		 * @Override
		 */
		public void close() throws IOException {
			mStream.close();
		}
		
	}
	
	/**
	 * Check if the 3 bytes sequence is the UTF8 MAgic Number.
	 * @param b1 first byte
	 * @param b2 second byte
	 * @param b3 third byte
	 * @return <code>true</code> if the 3 bytes represents the 
	 *  UTF8 BOM (ef bb bf)
	 */
	private static boolean isUF8BOM(byte b1, byte b2, byte b3) {
		return ((b1 == (byte)0xEF) &&
				(b2 == (byte)0xBB) &&
				(b3 == (byte)0xBF));
	}


	/**
	 * @return true if more lines to read, false otherwize.
	 */
	public boolean hasMoreLines() {
		String lCurrentLine = null;
		try {
			lCurrentLine = mBuffer.readLine();
		}
		catch ( IOException e ) {
			return false;
		}
		if( null == lCurrentLine ) {
			return false;
		}
		mRowCounter++;

		// PR 2110
		// if the line is empty
		// read next line
		while (lCurrentLine.equals("")) {
			try {
				lCurrentLine = mBuffer.readLine();
				if (lCurrentLine == null) {
					return false;
				}
			}
			catch ( IOException e ) {
				return false;
			}
		}

		if( null == mFields ) {
			initFields( lCurrentLine );
		}
		
		KxSmartTokenizer lSt = new KxSmartTokenizer(lCurrentLine, 
													mSeparator);
		int lFieldsCount = lSt.countTokens();
		mMissing = 0;
		for( int i=0; i<lFieldsCount; i++ ) {
			String lNextToken = lSt.nextToken();
			mFields[i] = lNextToken.trim();
		}
		return true;
	}

	private void initFields( String iLine ) {
		KxSmartTokenizer lSt = new KxSmartTokenizer(iLine, 
													mSeparator);
		int lFieldsCount = lSt.countTokens();
		mFields = new String[lFieldsCount];
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
				lValue = (float)0.0;
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
				lValue = 0.0;
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
