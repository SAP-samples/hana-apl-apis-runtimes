package KxJRT;

import java.io.*;
import java.lang.*;
import java.util.*;

/**
 * KxLog class creates a log file where all errors and trace will be stored
 */
public class KxLog extends PrintWriter {

	private static KxLog sInstance;

	private KxLog( FileOutputStream iFileName ) {
		super( iFileName );
	}

	public static KxLog getInstance() {
		try {
			if (null == sInstance) {
				sInstance = new KxLog(new FileOutputStream("KxJRTLog"));
			}
		}
		catch (FileNotFoundException e) {
			throw new RuntimeException("The file KxJRTLog can not be opened.");
		}
		return sInstance;
	}

	public static void deleteInstance() {
		if (null != sInstance) {
			sInstance.close();
		}
		sInstance = null;
	}
}
