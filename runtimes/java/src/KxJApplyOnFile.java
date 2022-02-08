// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxJApplyOnFile.java
// Author.......: Benoit Rognier
// Created......: Thu Jan 09 12:29:15 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.io.*;
import java.lang.*;

/**
 * Applies a <a href="http://www.kxen.com">Automatic Analytics</a> Java model on a flat file
 * with variable names on the first line. 
 * @see KxJRT.KxFileReaderWithNames KxFileReaderWithNames
 * @see KxJRT.KxFileReader KxFileReader
 */
public class KxJApplyOnFile {
	
	private String 				mInFilePath = null;
	private String 				mOutFilePath = null;
	private String 				mModelClassName = null;
	private String 				mSeparator = null;
	private boolean 			mWithNames = true;

	private PrintStream 		mOutStream = null;
	private KxFileReader 		mInStream = null;
	private IKxJModelInput 		mKxJModelInput = null;
	
	private IKxJModel			mKxJModel = null;
	
	/**
	 * @param iInFilePath path to input file
	 * @param iOutFilePath path to output file
	 * @param iModelClassName name of model's class
	 * @param iSeparator string that separates two values
	 * @param iWithNames true (default) if variable names are to be found on 
	 * first line 
	 */
	public KxJApplyOnFile( String	iInFilePath,
						   String	iOutFilePath,
						   String	iModelClassName,
						   String	iSeparator,
						   boolean	iWithNames ) {
		mInFilePath = iInFilePath;
		mOutFilePath = iOutFilePath;
		mModelClassName = iModelClassName;
		mSeparator = iSeparator;
		mWithNames = iWithNames;
	
		initModel();
		initStreams();
		apply();
	}
	
	private void initModel() {
		mKxJModel = KxJModelFactory.getKxJModel( mModelClassName );
	}

	private void initStreams() {
		try {
			if( mWithNames ) {
				mInStream = 
					new KxFileReaderWithNames( mInFilePath, mSeparator );
				KxJModelInputMapper	lMapper = 
					new KxJModelInputMapper((KxFileReaderWithNames)mInStream, mKxJModel);
				mKxJModelInput = (IKxJModelInput) lMapper;
			}
			else {
				mInStream = new KxFileReader( mInFilePath, mSeparator );
				mKxJModelInput = (IKxJModelInput) mInStream;
			}
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
			KxLog.getInstance().print("cannot instantiate out stream:"
									  +e.getMessage());
			throw new RuntimeException("Error during the instantiation of the out stream");
		}
	}

	private void apply() {
		while( mInStream.hasMoreLines() ) {
			Object[] lResults = mKxJModel.apply( mKxJModelInput );
			for( int i=0; i<lResults.length; i++ ) {
				mOutStream.print( lResults[i].toString() );
				if( i+1<lResults.length ) mOutStream.print(mSeparator);
			}
			mOutStream.println();
		}
	}

	private static void printArgError( String iError, String iArg ) {
		String lErrorString = "error : " + iError + " argument";
		if( iArg.equals("") ) {
			lErrorString += "s.";
		}
		else {
			lErrorString += " " + iArg + ".";
		}
		System.err.println( lErrorString );
		System.err.println( "type -usage for info." );
		KxLog.getInstance().print( lErrorString +"\n");
		throw new RuntimeException("Error arg\n");
	}

	private static void usage() {
		System.err.println( "Usage : " +
							"[-nonames] " +
							"[-separator <sep>] " +
							"[-out <file>] " +
							"-model <model> " +
							"-var <variable> " +
							"-input <line> " +
							"-in <file> " );
		System.err.println("\nApply a Automatic Analytics Java model on a flat file.\n");
		System.err.println("  -nonames\t\tdon't look for variables names on "+
						   "first line." );
		System.err.println("  -separator\t\tset field separator ( default is "+
						   "',' )");
		System.err.println("  -out\t\t\tset output file ( default is "+
						   "standard output )");
		System.err.println("  -model\t\tset Automatic Analytics java model" );
		System.err.println("  -input\t\tset input line to score" );
		System.err.println("  -in\t\tset input file to score" );
		System.err.println("\nSetting 'nonames' implies the input file has"+
						   " the same structure\nas dataset used for "+
						   "training.\n");
		System.err.println("Example 1: to apply model mymodel.java on "+
						   "dataset.csv (ie comma separated values)\nand "+
						   "store results in results.csv:\n\t"+
						   "javac -classpath KxJRT.jar mymodel.java\n\t"+
						   "java -jar KxJRT.jar -model mymodel -in "+
						   "dataset.csv -out results.csv");
		System.err.println("Example 2: to apply model mymodel.java on "+
						   " input date (ie comma separated values)\nand "+
						   "store results in results.csv:\n\t"+
						   "javac -classpath KxJRT.jar mymodel.java\n\t"+
						   "java -jar KxJRT.jar -model mymodel -input \"12,husband\" "+
						   "dataset.csv -out results.csv");
		throw new RuntimeException("Error usage\n");
	}

	/**
	 * Called by KxJRT.jar when executed.
	 */
	public static void main( String[] iArgs ) {
		String lVarName = null;
		String lInFilePath = null;
		String lOutFilePath = null;
		String lModelClassName = null;
		String lSeparator = ",";
		boolean lWithNames = true;
		boolean lOnlyForFileApply = true;

		try {
			for( int i=0; i<iArgs.length; i++ ) {
				if( iArgs[i].equalsIgnoreCase("-nonames") ) {
					lWithNames = false;
				}
				else if( iArgs[i].equalsIgnoreCase("-model" ) ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "model");
					}
					lModelClassName = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-in") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "in");
					}
					lInFilePath = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-var") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "in");
					}
					lVarName = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-input") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "in");
					}
					lInFilePath = iArgs[i+1];
					i++;
					lOnlyForFileApply = false;
				}
				else if( iArgs[i].equalsIgnoreCase("-out") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "out");
					}
					lOutFilePath = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-separator") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "separator");
					}
					lSeparator = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-usage") ||
						 iArgs[i].equalsIgnoreCase("-help")) {
					usage();
				}
				else {
					printArgError( "unknown", iArgs[i] );
				}
			}
			if( null == lInFilePath || null == lModelClassName ) {
				printArgError( "missing", "" );
			}

			if (lOnlyForFileApply) {
			KxJApplyOnFile lKxJApply = new KxJApplyOnFile( lInFilePath,
														   lOutFilePath,
														   lModelClassName,
														   lSeparator,
														   lWithNames);
			}
			else {
				KxJApplyOnInput lKxJApply = new KxJApplyOnInput(lInFilePath,
																lVarName,
																lOutFilePath,
																lModelClassName,
																lSeparator);
			}
		}
		catch (Exception e) {
			KxLog.getInstance().print(e.getMessage() + "\n");
		}
		finally {
			KxLog.deleteInstance();
		}
	}
	
}
