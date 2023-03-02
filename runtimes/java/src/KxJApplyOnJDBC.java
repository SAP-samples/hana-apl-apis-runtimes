package KxJRT;

import java.io.*;
import java.lang.*;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;


public class KxJApplyOnJDBC {

	private IKxJModel mScorerModel;
	
	/**
	 * @param iUrl a database url of the form jdbc:subprotocol:subname
	 * @param iUser the database user on whose behalf the connection is being made
	 * @param iPwd the user's password
	 * @return a connection to the specified database
	 * @throws SQLException
	 */
	public static Connection newConnection(String iUrl, String iUser, String iPwd) throws SQLException {
		Connection connection = DriverManager.getConnection(iUrl, iUser, iPwd);
		return connection;
	}
	
	/**
	 * @param iDriver the fully qualified name of the desired driver.
	 * @throws ClassNotFoundException, InstantiationException, IllegalAccessException
	 */
	public static void loadDriver(String iDriver) throws ClassNotFoundException, InstantiationException, IllegalAccessException {
		Class.forName(iDriver).newInstance();
	}
	
	public KxJApplyOnJDBC(String iClassName) throws ClassNotFoundException, InstantiationException, IllegalAccessException {

		Class lModelClass = Class.forName(iClassName);
		this.mScorerModel = (IKxJModel)lModelClass.newInstance();
	}

	public void apply(ResultSet iResult, String iOut) throws SQLException {

		PrintStream lOut = null;
		try {
			FileOutputStream lFileOut = new FileOutputStream(iOut);
			lOut = new PrintStream(lFileOut);
		} catch ( Exception e ) {
			throw new RuntimeException("Error in instantiation of output");
		}

		KxJDBCInput lModelInput =
			new KxJDBCInput(mScorerModel.getModelInputVariables(), iResult);

		while (lModelInput.next())
		{
			Object[] lResults = mScorerModel.apply(lModelInput);
			for( int i=0; i<lResults.length; i++ ) {
				lOut.print( lResults[i].toString() );
				if( i+1<lResults.length ) lOut.print(",");
			}
			lOut.println();
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
							"-driver <dbdriver> " +
							"-database <dbname> " +
							"-user <dbuser> " +
							"-pwd <dbpassword> " +
							"[-out <file>] " +
							"-model <model> " +
							"-query <statement> " );
		System.err.println("\nApply a Automatic Analytics Java model on a JDBC source.\n");
		System.err.println("  -driver\t\t\tset database driver");
		System.err.println("  -database\t\t\tset database name");
		System.err.println("  -user\t\t\tset database username");
		System.err.println("  -pwd\t\t\tset database password");
		System.err.println("  -out\t\t\tset output file ( default is "+
						   "standard output )");
		System.err.println("  -model\t\tset Automatic Analytics java model" );
		System.err.println("  -quer\t\tset input SQL statement to score" );
		System.err.println("Example: to apply model mymodel.java on "+
						   "\"select * from census\" from an odbc source dbtest\nand "+
						   "store results in results.csv :\n\t"+
						   "javac -classpath KxJRT.jar mymodel.java\n\t"+
						   "java -classpath KxJRT.jar KxJRT.KxJApplyONJDBC -model mymodel -driver \"sun.jdbc.odbc.JdbcOdbcDriver\""+
						   "-database \"jdbc:odbc:dbtest\" -user \"\" -pwd \"\" -query \"select * from census\""+
						   " -out results.csv");
		throw new RuntimeException("Error usage\n");
	}

	public static void main( String[] iArgs ) {
		String lDriver = null;
		String lDatabase = null;
		String lUser = null;
		String lPwd = null;
		String lModel = null;
		String lQuery = null;
		String lOut = null;
		KxJApplyOnJDBC lApplyScore = null;
		try {
			for( int i=0; i<iArgs.length; i++ ) {
				if( iArgs[i].equalsIgnoreCase("-driver") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "driver");
					}
					lDriver = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-database" ) ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "database");
					}
					lDatabase = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-user" ) ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "user");
					}
					lUser = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-pwd" ) ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "pwd");
					}
					lPwd = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-model" ) ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "model");
					}
					lModel = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-query") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "query");
					}
					lQuery = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-out") ) {
					if( i+1 >= iArgs.length ) {
						printArgError("missing", "out");
					}
					lOut = iArgs[i+1];
					i++;
				}
				else if( iArgs[i].equalsIgnoreCase("-usage") ||
						 iArgs[i].equalsIgnoreCase("-help")) {
					usage();
				}
				else {
					printArgError("unknown", iArgs[i] );
				}
			}
			lApplyScore = new KxJApplyOnJDBC(lModel);

			loadDriver(lDriver);

			try(Connection lConnection = newConnection(lDatabase, lUser, lPwd);
				Statement lStatement = lConnection.createStatement())
			{

				ResultSet lResult = lStatement.executeQuery(lQuery);

				lApplyScore.apply(lResult, lOut);
			}

		} catch(Exception e )
		{
			KxLog.getInstance().print(e.getMessage() + "\n");
			e.printStackTrace();
		}
		finally {
			KxLog.deleteInstance();
		}
		
	}

	
}
