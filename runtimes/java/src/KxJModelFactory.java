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
import java.net.*;
import java.io.*;
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
            Class lModelClass = null;
            File modelFilePath = new File(iModelName);
            String modelFileDirectory = modelFilePath.getParent();
            if (modelFileDirectory == null) {
                // If the model name is just a name, use Call.forName,
                // This means the model class file must be in the same folder as the Java Runtime
                // or in the CLASSPATH
                lModelClass = Class.forName( iModelName );
            } else {
                // If the model name is a full path, we use an URLClassLoader
                // that allows loading a class file from anywhere
                File classPath = new File(modelFileDirectory);
                URL[] classPathUrls = { classPath.toURI().toURL() };
                URLClassLoader urlClassLoader = new URLClassLoader(classPathUrls);
                String modelFileName = modelFilePath.getName();
                lModelClass = urlClassLoader.loadClass(modelFileName);
            }
			Constructor[] lConstructors = lModelClass.getConstructors();
			Constructor lDefaultConstructor = lConstructors[0];
			Object lModel = lDefaultConstructor.newInstance();
			return (IKxJModel) lModel;
		}
		catch ( ClassNotFoundException e ) {
			KxLog.getInstance().print(iModelName + " not found in classpath\n");
			throw new RuntimeException("Your classpath does not contain " + iModelName);
		}
		catch ( Exception e ) {
			throw new RuntimeException("Instance for current model name " + iModelName + " cannot be done");
		}
	}  
}
