// Automated Analytics 10.2203.0.0 - Copyright 2021 SAP SE or an SAP affiliate company. All rights reserved. - Model built in 10.2006.0.0 - Model Name is APLModel - Model Version is 1 
//	Code compilation needs KxJRT.jar in the classpath as shown below:
//		javac -classpath "path-to-KxJRT.jar" model.java
//	where "model.java" is the generated java code.
//	This generates a file named "model.class" that contains java bytecode.

//	This runtime is available in the product directory in EXE/KCG/KxJavaRT.
//	In addition, in this directory, a small HOW TO is available (index.html).
//	Please refer to this file to compile and execute exported model in JAVA code.

import KxJRT.*;
import java.util.*;
import java.nio.charset.UnsupportedCharsetException;
import java.nio.charset.Charset;

public class ExportedModelInJava implements IKxJModel {


	private static Charset sCharset;
	private static String[] mInputVariables = new String[5];
	private static String[] mInputStorageVariables = new String[5];
	private static String[] mOutputStorageVariables = new String[1];
	private static String[] mOutputVariables = new String[1];
	private static String[][] mCategories = new String[5][0];
	private static String[] mMissingStrings = new String[5];
	static {
		try {
			sCharset = Charset.forName("UTF-8");
		} catch(UnsupportedCharsetException e) {
			throw new RuntimeException("UTF-8 Charset not supported, this should not occur");
		}
		initializeInputVariable0();
		initializeInputVariable1();
		initializeInputVariable2();
		initializeInputVariable3();
		initializeInputVariable4();
		initializeOutputVariable0();
	}
	public String[] getModelInputVariables() {
	return mInputVariables;
	}

	public String[] getModelOutputVariables() {
	return mOutputVariables;
	}

	public String[] getModelInputStorageVariables() {
	return mInputStorageVariables;
	}

	public String[] getModelOutputStorageVariables() {
	return mOutputStorageVariables;
	}

	private int doublesegcmp(double iX, double iXStart, int iEqualStart, double iXEnd, int iEqualEnd) {
	if ((double)iX < (double)iXStart) return -2;
	if ((double)iX == (double)iXStart)	{
		if (1 == iEqualStart) return 0;
		else return -1;
	}
	else {
		if ((double)iX < (double)iXEnd) return 0;
		if ((double)iX == (double)iXEnd) {
			if (1 == iEqualEnd) return 0;
			else return 1;
		}
		else {
			return 2;
		}
	}
	}

	private int doublecmp(double id1, double if2) {
	return ((double)id1 == if2 )?0:1;
	}

	private int strcmp( String iS1, String iS2 ) {
	return iS1.compareTo(iS2);
	}

	public ExportedModelInJava() {}
	//education
	private static void initializeInputVariable0() {
		byte[] lInput = {101, 100, 117, 99, 97, 116, 105, 111, 110};
		mInputVariables[0] = new String(lInput, sCharset);
		byte[] lInputStorage = {115, 116, 114, 105, 110, 103};
		mInputStorageVariables[0] = new String(lInputStorage, sCharset);
		mCategories[0] = new String[15];
		byte[] lCategory3_0 = {72, 83, 45, 103, 114, 97, 100};
		mCategories[0][0] = new String(lCategory3_0, sCharset);
		byte[] lCategory3_1 = {83, 111, 109, 101, 45, 99, 111, 108, 108, 101, 103, 101};
		mCategories[0][1] = new String(lCategory3_1, sCharset);
		byte[] lCategory3_2 = {66, 97, 99, 104, 101, 108, 111, 114, 115};
		mCategories[0][2] = new String(lCategory3_2, sCharset);
		byte[] lCategory3_3 = {77, 97, 115, 116, 101, 114, 115};
		mCategories[0][3] = new String(lCategory3_3, sCharset);
		byte[] lCategory3_4 = {65, 115, 115, 111, 99, 45, 118, 111, 99};
		mCategories[0][4] = new String(lCategory3_4, sCharset);
		byte[] lCategory3_5 = {49, 49, 116, 104};
		mCategories[0][5] = new String(lCategory3_5, sCharset);
		byte[] lCategory3_6 = {65, 115, 115, 111, 99, 45, 97, 99, 100, 109};
		mCategories[0][6] = new String(lCategory3_6, sCharset);
		byte[] lCategory3_7 = {49, 48, 116, 104};
		mCategories[0][7] = new String(lCategory3_7, sCharset);
		byte[] lCategory3_8 = {55, 116, 104, 45, 56, 116, 104};
		mCategories[0][8] = new String(lCategory3_8, sCharset);
		byte[] lCategory3_9 = {80, 114, 111, 102, 45, 115, 99, 104, 111, 111, 108};
		mCategories[0][9] = new String(lCategory3_9, sCharset);
		byte[] lCategory3_10 = {57, 116, 104};
		mCategories[0][10] = new String(lCategory3_10, sCharset);
		byte[] lCategory3_11 = {49, 50, 116, 104};
		mCategories[0][11] = new String(lCategory3_11, sCharset);
		byte[] lCategory3_12 = {68, 111, 99, 116, 111, 114, 97, 116, 101};
		mCategories[0][12] = new String(lCategory3_12, sCharset);
		byte[] lCategory3_13 = {53, 116, 104, 45, 54, 116, 104};
		mCategories[0][13] = new String(lCategory3_13, sCharset);
		byte[] lCategory3_14 = {75, 120, 79, 116, 104, 101, 114};
		mCategories[0][14] = new String(lCategory3_14, sCharset);
	}
	//marital-status
	private static void initializeInputVariable1() {
		byte[] lInput = {109, 97, 114, 105, 116, 97, 108, 45, 115, 116, 97, 116, 117, 115};
		mInputVariables[1] = new String(lInput, sCharset);
		byte[] lInputStorage = {115, 116, 114, 105, 110, 103};
		mInputStorageVariables[1] = new String(lInputStorage, sCharset);
		mCategories[1] = new String[7];
		byte[] lCategory5_0 = {77, 97, 114, 114, 105, 101, 100, 45, 99, 105, 118, 45, 115, 112, 111, 117, 115, 101};
		mCategories[1][0] = new String(lCategory5_0, sCharset);
		byte[] lCategory5_1 = {78, 101, 118, 101, 114, 45, 109, 97, 114, 114, 105, 101, 100};
		mCategories[1][1] = new String(lCategory5_1, sCharset);
		byte[] lCategory5_2 = {68, 105, 118, 111, 114, 99, 101, 100};
		mCategories[1][2] = new String(lCategory5_2, sCharset);
		byte[] lCategory5_3 = {87, 105, 100, 111, 119, 101, 100};
		mCategories[1][3] = new String(lCategory5_3, sCharset);
		byte[] lCategory5_4 = {83, 101, 112, 97, 114, 97, 116, 101, 100};
		mCategories[1][4] = new String(lCategory5_4, sCharset);
		byte[] lCategory5_5 = {77, 97, 114, 114, 105, 101, 100, 45, 115, 112, 111, 117, 115, 101, 45, 97, 98, 115, 101, 110, 116};
		mCategories[1][5] = new String(lCategory5_5, sCharset);
		byte[] lCategory5_6 = {77, 97, 114, 114, 105, 101, 100, 45, 65, 70, 45, 115, 112, 111, 117, 115, 101};
		mCategories[1][6] = new String(lCategory5_6, sCharset);
	}
	//occupation
	private static void initializeInputVariable2() {
		byte[] lInput = {111, 99, 99, 117, 112, 97, 116, 105, 111, 110};
		mInputVariables[2] = new String(lInput, sCharset);
		byte[] lInputStorage = {115, 116, 114, 105, 110, 103};
		mInputStorageVariables[2] = new String(lInputStorage, sCharset);
		mCategories[2] = new String[14];
		byte[] lCategory6_0 = {80, 114, 111, 102, 45, 115, 112, 101, 99, 105, 97, 108, 116, 121};
		mCategories[2][0] = new String(lCategory6_0, sCharset);
		byte[] lCategory6_1 = {69, 120, 101, 99, 45, 109, 97, 110, 97, 103, 101, 114, 105, 97, 108};
		mCategories[2][1] = new String(lCategory6_1, sCharset);
		byte[] lCategory6_2 = {67, 114, 97, 102, 116, 45, 114, 101, 112, 97, 105, 114};
		mCategories[2][2] = new String(lCategory6_2, sCharset);
		byte[] lCategory6_3 = {65, 100, 109, 45, 99, 108, 101, 114, 105, 99, 97, 108};
		mCategories[2][3] = new String(lCategory6_3, sCharset);
		byte[] lCategory6_4 = {83, 97, 108, 101, 115};
		mCategories[2][4] = new String(lCategory6_4, sCharset);
		byte[] lCategory6_5 = {79, 116, 104, 101, 114, 45, 115, 101, 114, 118, 105, 99, 101};
		mCategories[2][5] = new String(lCategory6_5, sCharset);
		byte[] lCategory6_6 = {77, 97, 99, 104, 105, 110, 101, 45, 111, 112, 45, 105, 110, 115, 112, 99, 116};
		mCategories[2][6] = new String(lCategory6_6, sCharset);
		byte[] lCategory6_7 = {63};
		mCategories[2][7] = new String(lCategory6_7, sCharset);
		byte[] lCategory6_8 = {84, 114, 97, 110, 115, 112, 111, 114, 116, 45, 109, 111, 118, 105, 110, 103};
		mCategories[2][8] = new String(lCategory6_8, sCharset);
		byte[] lCategory6_9 = {72, 97, 110, 100, 108, 101, 114, 115, 45, 99, 108, 101, 97, 110, 101, 114, 115};
		mCategories[2][9] = new String(lCategory6_9, sCharset);
		byte[] lCategory6_10 = {70, 97, 114, 109, 105, 110, 103, 45, 102, 105, 115, 104, 105, 110, 103};
		mCategories[2][10] = new String(lCategory6_10, sCharset);
		byte[] lCategory6_11 = {84, 101, 99, 104, 45, 115, 117, 112, 112, 111, 114, 116};
		mCategories[2][11] = new String(lCategory6_11, sCharset);
		byte[] lCategory6_12 = {80, 114, 111, 116, 101, 99, 116, 105, 118, 101, 45, 115, 101, 114, 118};
		mCategories[2][12] = new String(lCategory6_12, sCharset);
		byte[] lCategory6_13 = {75, 120, 79, 116, 104, 101, 114};
		mCategories[2][13] = new String(lCategory6_13, sCharset);
	}
	//capital-gain
	private static void initializeInputVariable3() {
		byte[] lInput = {99, 97, 112, 105, 116, 97, 108, 45, 103, 97, 105, 110};
		mInputVariables[3] = new String(lInput, sCharset);
		byte[] lInputStorage = {105, 110, 116, 101, 103, 101, 114};
		mInputStorageVariables[3] = new String(lInputStorage, sCharset);
	}
	//capital-loss
	private static void initializeInputVariable4() {
		byte[] lInput = {99, 97, 112, 105, 116, 97, 108, 45, 108, 111, 115, 115};
		mInputVariables[4] = new String(lInput, sCharset);
		byte[] lInputStorage = {105, 110, 116, 101, 103, 101, 114};
		mInputStorageVariables[4] = new String(lInputStorage, sCharset);
		mCategories[4] = new String[15];
		byte[] lCategory11_0 = {48};
		mCategories[4][0] = new String(lCategory11_0, sCharset);
		byte[] lCategory11_1 = {75, 120, 79, 116, 104, 101, 114};
		mCategories[4][1] = new String(lCategory11_1, sCharset);
		byte[] lCategory11_2 = {49, 57, 48, 50};
		mCategories[4][2] = new String(lCategory11_2, sCharset);
		byte[] lCategory11_3 = {49, 57, 55, 55};
		mCategories[4][3] = new String(lCategory11_3, sCharset);
		byte[] lCategory11_4 = {49, 56, 56, 55};
		mCategories[4][4] = new String(lCategory11_4, sCharset);
		byte[] lCategory11_5 = {49, 52, 56, 53};
		mCategories[4][5] = new String(lCategory11_5, sCharset);
		byte[] lCategory11_6 = {50, 52, 49, 53};
		mCategories[4][6] = new String(lCategory11_6, sCharset);
		byte[] lCategory11_7 = {49, 56, 52, 56};
		mCategories[4][7] = new String(lCategory11_7, sCharset);
		byte[] lCategory11_8 = {49, 54, 48, 50};
		mCategories[4][8] = new String(lCategory11_8, sCharset);
		byte[] lCategory11_9 = {49, 55, 52, 48};
		mCategories[4][9] = new String(lCategory11_9, sCharset);
		byte[] lCategory11_10 = {49, 53, 57, 48};
		mCategories[4][10] = new String(lCategory11_10, sCharset);
		byte[] lCategory11_11 = {49, 56, 55, 54};
		mCategories[4][11] = new String(lCategory11_11, sCharset);
		byte[] lCategory11_12 = {49, 54, 55, 50};
		mCategories[4][12] = new String(lCategory11_12, sCharset);
		byte[] lCategory11_13 = {49, 55, 52, 49};
		mCategories[4][13] = new String(lCategory11_13, sCharset);
		byte[] lCategory11_14 = {49, 53, 54, 52};
		mCategories[4][14] = new String(lCategory11_14, sCharset);
	}
	private static void initializeOutputVariable0() {
		byte[] lOutput = {114, 114, 95, 99, 108, 97, 115, 115};
		mOutputVariables[0] = new String(lOutput, sCharset);
		byte[] lOutputStorage = {110, 117, 109, 98, 101, 114};
		mOutputStorageVariables[0] = new String(lOutputStorage, sCharset);
	}

	private double Kxen_RobustRegression_0_KxVar3( IKxJModelInput iInput ) {
	String lValue3 = iInput.stringValue(0);
	if (iInput.isEmpty(0, mMissingStrings[0]))
	{
		return (double)7.476280483725e-3;
	}
	if ( 0 == strcmp( mCategories[0][0], lValue3) ) {
		return (double)-2.971965283987e-2;
	}
	if ( 0 == strcmp( mCategories[0][1], lValue3) ) {
		return (double)-1.198249406966e-2;
	}
	if ( 0 == strcmp( mCategories[0][2], lValue3) ) {
		return (double)8.466462950968e-2;
	}
	if ( 0 == strcmp( mCategories[0][3], lValue3) ) {
		return (double)1.312985299278e-1;
	}
	if ( 0 == strcmp( mCategories[0][5], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == strcmp( mCategories[0][7], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == strcmp( mCategories[0][8], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == strcmp( mCategories[0][9], lValue3) ) {
		return (double)1.962705330767e-1;
	}
	if ( 0 == strcmp( mCategories[0][10], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == strcmp( mCategories[0][11], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == strcmp( mCategories[0][12], lValue3) ) {
		return (double)1.962705330767e-1;
	}
	if ( 0 == strcmp( mCategories[0][13], lValue3) ) {
		return (double)-7.782923849167e-2;
	}
	return (double)7.476280483725e-3;
}

	private double Kxen_RobustRegression_0_KxVar5( IKxJModelInput iInput ) {
	String lValue5 = iInput.stringValue(1);
	if (iInput.isEmpty(1, mMissingStrings[1]))
	{
		return (double)1.369884076752e-1;
	}
	if ( 0 == strcmp( mCategories[1][1], lValue5) ) {
		return (double)-1.274492103096e-1;
	}
	if ( 0 == strcmp( mCategories[1][2], lValue5) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == strcmp( mCategories[1][3], lValue5) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == strcmp( mCategories[1][4], lValue5) ) {
		return (double)-1.274492103096e-1;
	}
	if ( 0 == strcmp( mCategories[1][5], lValue5) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == strcmp( mCategories[1][6], lValue5) ) {
		return (double)-8.951928704536e-2;
	}
	return (double)1.369884076752e-1;
}

	private double Kxen_RobustRegression_0_KxVar6( IKxJModelInput iInput ) {
	String lValue6 = iInput.stringValue(2);
	if (iInput.isEmpty(2, mMissingStrings[2]))
	{
		return (double)-7.196725171655e-2;
	}
	if ( 0 == strcmp( mCategories[2][0], lValue6) ) {
		return (double)8.314166470599e-2;
	}
	if ( 0 == strcmp( mCategories[2][1], lValue6) ) {
		return (double)9.35996019906e-2;
	}
	if ( 0 == strcmp( mCategories[2][2], lValue6) ) {
		return (double)1.753792369402e-3;
	}
	if ( 0 == strcmp( mCategories[2][3], lValue6) ) {
		return (double)-3.404467022914e-2;
	}
	if ( 0 == strcmp( mCategories[2][4], lValue6) ) {
		return (double)1.911905073134e-2;
	}
	if ( 0 == strcmp( mCategories[2][6], lValue6) ) {
		return (double)-3.404467022914e-2;
	}
	if ( 0 == strcmp( mCategories[2][7], lValue6) ) {
		return (double)-4.648364837538e-2;
	}
	if ( 0 == strcmp( mCategories[2][8], lValue6) ) {
		return (double)1.753792369402e-3;
	}
	if ( 0 == strcmp( mCategories[2][9], lValue6) ) {
		return (double)-6.082938671308e-2;
	}
	if ( 0 == strcmp( mCategories[2][10], lValue6) ) {
		return (double)-4.648364837538e-2;
	}
	if ( 0 == strcmp( mCategories[2][11], lValue6) ) {
		return (double)3.089945350411e-2;
	}
	if ( 0 == strcmp( mCategories[2][12], lValue6) ) {
		return (double)3.089945350411e-2;
	}
	return (double)-7.196725171655e-2;
}

	private double Kxen_RobustRegression_0_KxVar10( IKxJModelInput iInput ) {
	double lValue10 = iInput.doubleValue(3);
	if (iInput.isEmpty(3, mMissingStrings[3]))
	{
		return (double)-1.588211585317e-1;
	}
	if ( lValue10 > 99999 ) {
		lValue10 = (double)99999;
	}
	else if ( lValue10 < 0 ) {
		lValue10 = (double)0;
	}
	if( 0 == doublesegcmp( lValue10, 0.0e0, 1, 0.0e0, 1) ) { 
		return (double)-1.133466382516e-2;
	}
	if( 0 == doublesegcmp( lValue10, 0.0e0, 0, 7.08e2, 1) ) { 
		return (double)(-1.767629805377e-4 * lValue10 + -1.133466383769e-2);
	}
	if( 0 == doublesegcmp( lValue10, 7.09e2, 1, 1.96e3, 1) ) { 
		return (double)(-5.638759897392e-5 * lValue10 + -9.662563686829e-2);
	}
	if( 0 == doublesegcmp( lValue10, 1.961e3, 1, 2.433e3, 1) ) { 
		return (double)(1.504977772729e-4 * lValue10 + -5.021247820112e-1);
	}
	if( 0 == doublesegcmp( lValue10, 2.434e3, 1, 2.907e3, 1) ) { 
		return (double)(1.504977772729e-4 * lValue10 + -5.021247820041e-1);
	}
	if( 0 == doublesegcmp( lValue10, 2.907e3, 0, 3.466e3, 1) ) { 
		return (double)(1.275230549543e-4 * lValue10 + -4.353372642168e-1);
	}
	if( 0 == doublesegcmp( lValue10, 3.467e3, 1, 4.101e3, 1) ) { 
		return (double)(9.895756683492e-5 * lValue10 + -3.363274384876e-1);
	}
	if( 0 == doublesegcmp( lValue10, 4.101e3, 0, 4.865e3, 1) ) { 
		return (double)(8.222991783137e-5 * lValue10 + -2.677273499177e-1);
	}
	if( 0 == doublesegcmp( lValue10, 4.866e3, 1, 5.455e3, 1) ) { 
		return (double)(1.38215577108e-4 * lValue10 + -5.401384635483e-1);
	}
	if( 0 == doublesegcmp( lValue10, 5.455e3, 0, 5.876e3, 1) ) { 
		return (double)(1.931836112582e-4 * lValue10 + -8.399890898292e-1);
	}
	if( 0 == doublesegcmp( lValue10, 5.877e3, 1, 7.298e3, 1) ) { 
		return (double)(1.732500742842e-5 * lValue10 + 1.934003122196e-1);
	}
	if( 0 == doublesegcmp( lValue10, 7.298e3, 0, 7.39e3, 1) ) { 
		return (double)(2.599646382024e-4 * lValue10 + -1.577383713166e0);
	}
	if( 0 == doublesegcmp( lValue10, 7.391e3, 1, 9.9999e4, 1) ) { 
		return (double)(4.009025790664e-7 * lValue10 + 3.409742484152e-1);
	}
	if( lValue10 > 9.9999e4 ) {
		return (double)(4.009025790664e-7 * lValue10 + 3.409742484152e-1);
	}
	return (double)-1.588211585317e-1;
}

	private double Kxen_RobustRegression_0_KxVar11( IKxJModelInput iInput ) {
double lValue11 = iInput.doubleValue(4);
	if (iInput.isEmpty(4, mMissingStrings[4]))
	{
		return (double)-2.744876380279e-2;
	}
	if ( 0 == doublecmp( 0.0, lValue11) ) {
		return (double)2.28719791289e-3;
	}
	if ( 0 == doublecmp( 1902.0, lValue11) ) {
		return (double)2.993149969606e-1;
	}
	if ( 0 == doublecmp( 1977.0, lValue11) ) {
		return (double)3.127898560595e-1;
	}
	if ( 0 == doublecmp( 1887.0, lValue11) ) {
		return (double)3.127898560595e-1;
	}
	if ( 0 == doublecmp( 1485.0, lValue11) ) {
		return (double)1.755824852913e-1;
	}
	if ( 0 == doublecmp( 2415.0, lValue11) ) {
		return (double)3.127898560595e-1;
	}
	if ( 0 == doublecmp( 1848.0, lValue11) ) {
		return (double)2.993149969606e-1;
	}
	if ( 0 == doublecmp( 1602.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1740.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1590.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1876.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1672.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1741.0, lValue11) ) {
		return (double)-1.215219871355e-1;
	}
	if ( 0 == doublecmp( 1564.0, lValue11) ) {
		return (double)2.993149969606e-1;
	}
	return (double)-2.744876380279e-2;
}

private Vector Kxen_RobustRegressionclass_apply(IKxJModelInput iInput) {
	double[] lInputs = new double[5];
	double[] lAllInputs = new double[5];

	lAllInputs[0] = (double)1.0;
	double lScore = (double)0.0e0;

	lScore += Kxen_RobustRegression_0_KxVar3(iInput);
	lScore += Kxen_RobustRegression_0_KxVar5(iInput);
	lScore += Kxen_RobustRegression_0_KxVar6(iInput);
	lScore += Kxen_RobustRegression_0_KxVar10(iInput);
	lScore += Kxen_RobustRegression_0_KxVar11(iInput);
	Vector lResults = new Vector(mOutputVariables.length);
	lResults.add( new Double(lScore) );
	return lResults;
}

public Object[] apply(IKxJModelInput iInput) {
	Vector lResults = Kxen_RobustRegressionclass_apply( iInput);
	return lResults.toArray();
}

}
