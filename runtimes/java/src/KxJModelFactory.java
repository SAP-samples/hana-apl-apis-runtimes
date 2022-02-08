// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: KxJModelFactory.java
// Author.......: 	
// Created......: Wed Jan 08 14:57:28 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.lang.*;
import java.lang.reflect.Constructor;

/**
 * Provides instances of Automatic Analytics Java model.
 */
public class KxJModelFactory {

	public KxJModelFactory() {		
	}
	
	/**
	 * @param iModelName name of the Automatic Analytics Java model's class. It should be 
	 * the "fully-qualified class name" of the generated model.
	 * @return an instance of IKxJModel. 
	 */
	public static IKxJModel getKxJModel( String iModelName ) {
		try {
			Class lModelClass = Class.forName( iModelName );
			Constructor[] lConstructors = lModelClass.getConstructors();
			Constructor lDefaultConstructor = lConstructors[0];
			Object lModel = lDefaultConstructor.newInstance();
			return (IKxJModel) lModel;
		}
		catch ( ClassNotFoundException e ) {
			KxLog.getInstance().print(iModelName+" not found in classpath");
			throw new RuntimeException("Your classpath does not contain " + iModelName);
		}
		catch ( Exception e ) {
			throw new RuntimeException("Instance for current model name "+iModelName+" cannot be done");
		}
	}  
}
