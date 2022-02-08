// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: Mapper.java
// Author.......: 
// Created......: Wed Jan 29 15:20:19 2003
// Description..:
// ----------------------------------------------------------------------------

package KxJRT;

import java.util.TreeMap;

/**
 * Mapper class performs an indirection between model indices and data source 
 * indices. This class is used by {@link KxJRT.KxJModelInputMapper
 *  KxJModelInputMapper}.<br/>
 * For example, let { 0:a1, 1:a2, 2:a3, 3:a4 } be the variables needed by the
 *  model to apply properly, and { 0:a2, 1:b1, 2:a4, 3:b2, 4:a3, 5:a1 } be the
 *  data source variables. This mapper then builds the following indirection :
 * <br/>
 * { 0:5, 1:0; 2:4, 3:2 }. <br/>
 * When the model asks for variable with index 1, ie a2, the mapper turns it
 * into 0, which is a2's index in data source reference.
 * @see KxJRT.IKxJModelInput IKxJModelInput
 * @see KxJRT.KxJModelInputMapper KxJModelInputMapper
 * @version 1.0
 */
public class Mapper {
	/**
	 *	mIndices is a the array of indirection between model indices and data 
	 * source indices.
	 */
	int[] mIndices = null;

	/**
	 * @param iDataSourceNames array of data source variables.
	 * @param iKxJModelNames array of output variables.
	 */
	public Mapper( String[] iDataSourceNames, String iKxJModelNames[] ) {
		if( null == iKxJModelNames ) {
			KxLog.getInstance().print("Mapper not found KxJModelName\n");
			throw new RuntimeException("Model variables not found");
		}
		if( null == iDataSourceNames ) {
			KxLog.getInstance().print("Mapper not found DataSourceName\n");
			throw new RuntimeException("Input variables not found");
		}
		mIndices = new int[ iKxJModelNames.length ];
		TreeMap lDataSourceNamesMap = new TreeMap();
		for( int i=0; i < iDataSourceNames.length ; i++ ) {
			lDataSourceNamesMap.put( iDataSourceNames[i], new Integer(i) );
		}
		for( int i=0; i<iKxJModelNames.length; i++ ) {
			if (iKxJModelNames[i] != null) {
				Integer lIndex=
					(Integer) lDataSourceNamesMap.get(iKxJModelNames[i]);
				if (lIndex == null ) {
					KxLog.getInstance().print("Unknown model variable " + iKxJModelNames[i] + " in mapper.\n");
					throw new RuntimeException("The mapper does not contain the variable " + iKxJModelNames[i]);
				}
				mIndices[i] = lIndex.intValue();
			}
			else
			{
				mIndices[i] = -1;
			}
		}
	}
	
	/**
	 * Performs the indirection.
	 * @param iModelIndex index of model variable.
	 * @return data source variable variable index.
	 */
	public int getIndex( int iModelIndex ) throws IndexOutOfBoundsException {
		if( iModelIndex >= mIndices.length ) {
			KxLog.getInstance().print("Out of bound index\n");
			throw new IndexOutOfBoundsException("Index " + iModelIndex + " is not defined in mapper.");
		}
		return mIndices[ iModelIndex ];
	}
}
