// Automated Analytics 10.2203.0.0 - Copyright 2021 SAP SE or an SAP affiliate company. All rights reserved. - Model built in 10.2006.0.0 - Model Name is APLModel - Model Version is 1
#include "Config.h"
#include "KxCppRTModelManager.h"


class ExportedModelInCPP : public virtual KxCppRTModel 
{
 public:
	ExportedModelInCPP();

	ExportedModelInCPP (KxCppRTModelManager& iModelManager);

	~ExportedModelInCPP();

	virtual void  apply (const KxCppRTCase& iInput, KxCppRTCase &oOutput) const;

	virtual const cStringVector& getModelInputVariables() const;

	virtual const cStringVector& getModelOutputVariables() const;

	virtual const KxSTL::string& getModelName() const;

 private:
	int doublesegcmp(double iX, double iXStart,int iEqualStart, double iXEnd, int iEqualEnd) const;

	int doublecmp(double id1, double if2) const;

	int floatsegcmp(float iX, float iXStart,int iEqualStart, float iXEnd, int iEqualEnd) const;

	int floatcmp(float id1, float if2) const;

 private:
	cStringVector mInputVariables;
	cStringVector mOutputVariables;
	KxSTL::vector<cStringVector> mCategories;
	cStringVector mMissingStrings;
	KxSTL::string mModelName;

	double Kxen_RobustRegression_0_KxVar3(KxSTL::string const& iInput) const;
	double Kxen_RobustRegression_0_KxVar5(KxSTL::string const& iInput) const;
	double Kxen_RobustRegression_0_KxVar6(KxSTL::string const& iInput) const;
	double Kxen_RobustRegression_0_KxVar10(KxSTL::string const& iInput) const;
	double Kxen_RobustRegression_0_KxVar11(KxSTL::string const& iInput) const;
	void Kxen_RobustRegression_apply(const KxCppRTCase& iInput, KxCppRTCase& iOutput) const;
};


int
ExportedModelInCPP::doublesegcmp
(double iX,
 double iXStart,
 int iEqualStart,
 double iXEnd,
 int iEqualEnd) const
{
	if ((double)iX < (double)iXStart) return -2;
	else if ((double)iX == (double)iXStart)	{
		if (1 == iEqualStart) return 0;
		else return -1;
	}
	else {
		if ((double)iX < (double)iXEnd) return 0;
		else if ((double)iX == (double)iXEnd) {
			if (1 == iEqualEnd) return 0;
			else return 1;
		}
		else {
			return 2;
		}
	}
}

int
ExportedModelInCPP::doublecmp
(double id1,
 double if2) const
{
	return ((double)id1 == if2 )?0:1;
}

int
ExportedModelInCPP::floatsegcmp
(float iX,
 float iXStart,
 int iEqualStart,
 float iXEnd,
 int iEqualEnd) const
{
	if ((float)iX < (float)iXStart) return -2;
	else if ((float)iX == (float)iXStart)	{
		if (1 == iEqualStart) return 0;
		else return -1;
	}
	else {
		if ((float)iX < (float)iXEnd) return 0;
		else if ((float)iX == (float)iXEnd) {
			if (1 == iEqualEnd) return 0;
			else return 1;
		}
		else {
			return 2;
		}
	}
}

int
ExportedModelInCPP::floatcmp
(float id1,
 float if2) const
{
	return ((float)id1 == if2 )?0:1;
}

const cStringVector&
ExportedModelInCPP::getModelInputVariables
() const
{
	return mInputVariables;
}

const cStringVector&
ExportedModelInCPP::getModelOutputVariables
() const
{
	return mOutputVariables;
}

const KxSTL::string&
ExportedModelInCPP::getModelName
() const
{
	return mModelName;
}

ExportedModelInCPP::~ExportedModelInCPP()
{
	mInputVariables.clear();
	mOutputVariables.clear();
	mMissingStrings.clear();
	int i;
	for (i = 0 ; i < mCategories.size() ; i++)
	{
		mCategories[i].clear();
	}
	mCategories.clear();
}

ExportedModelInCPP::ExportedModelInCPP()
{
}

ExportedModelInCPP::ExportedModelInCPP(KxCppRTModelManager& iModelManager)
{
	mModelName = KxSTL::string("ExportedModelInCPP");
	iModelManager.registerModel(mModelName, this);


	char lInput3[10] = {101, 100, 117, 99, 97, 116, 105, 111, 110, 0};
	mInputVariables.push_back(lInput3);
	cStringVector lCategories3;

	char lCategory3_0[8] = {72, 83, 45, 103, 114, 97, 100, 0};
	lCategories3.push_back(lCategory3_0);
	char lCategory3_1[13] = {83, 111, 109, 101, 45, 99, 111, 108, 108, 101, 103, 101, 0};
	lCategories3.push_back(lCategory3_1);
	char lCategory3_2[10] = {66, 97, 99, 104, 101, 108, 111, 114, 115, 0};
	lCategories3.push_back(lCategory3_2);
	char lCategory3_3[8] = {77, 97, 115, 116, 101, 114, 115, 0};
	lCategories3.push_back(lCategory3_3);
	char lCategory3_4[10] = {65, 115, 115, 111, 99, 45, 118, 111, 99, 0};
	lCategories3.push_back(lCategory3_4);
	char lCategory3_5[5] = {49, 49, 116, 104, 0};
	lCategories3.push_back(lCategory3_5);
	char lCategory3_6[11] = {65, 115, 115, 111, 99, 45, 97, 99, 100, 109, 0};
	lCategories3.push_back(lCategory3_6);
	char lCategory3_7[5] = {49, 48, 116, 104, 0};
	lCategories3.push_back(lCategory3_7);
	char lCategory3_8[8] = {55, 116, 104, 45, 56, 116, 104, 0};
	lCategories3.push_back(lCategory3_8);
	char lCategory3_9[12] = {80, 114, 111, 102, 45, 115, 99, 104, 111, 111, 108, 0};
	lCategories3.push_back(lCategory3_9);
	char lCategory3_10[4] = {57, 116, 104, 0};
	lCategories3.push_back(lCategory3_10);
	char lCategory3_11[5] = {49, 50, 116, 104, 0};
	lCategories3.push_back(lCategory3_11);
	char lCategory3_12[10] = {68, 111, 99, 116, 111, 114, 97, 116, 101, 0};
	lCategories3.push_back(lCategory3_12);
	char lCategory3_13[8] = {53, 116, 104, 45, 54, 116, 104, 0};
	lCategories3.push_back(lCategory3_13);
	char lCategory3_14[8] = {75, 120, 79, 116, 104, 101, 114, 0};
	lCategories3.push_back(lCategory3_14);
	mCategories.push_back(lCategories3);

	char lInput5[15] = {109, 97, 114, 105, 116, 97, 108, 45, 115, 116, 97, 116, 117, 115, 0};
	mInputVariables.push_back(lInput5);
	cStringVector lCategories5;

	char lCategory5_0[19] = {77, 97, 114, 114, 105, 101, 100, 45, 99, 105, 118, 45, 115, 112, 111, 117, 115, 101, 0};
	lCategories5.push_back(lCategory5_0);
	char lCategory5_1[14] = {78, 101, 118, 101, 114, 45, 109, 97, 114, 114, 105, 101, 100, 0};
	lCategories5.push_back(lCategory5_1);
	char lCategory5_2[9] = {68, 105, 118, 111, 114, 99, 101, 100, 0};
	lCategories5.push_back(lCategory5_2);
	char lCategory5_3[8] = {87, 105, 100, 111, 119, 101, 100, 0};
	lCategories5.push_back(lCategory5_3);
	char lCategory5_4[10] = {83, 101, 112, 97, 114, 97, 116, 101, 100, 0};
	lCategories5.push_back(lCategory5_4);
	char lCategory5_5[22] = {77, 97, 114, 114, 105, 101, 100, 45, 115, 112, 111, 117, 115, 101, 45, 97, 98, 115, 101, 110, 116, 0};
	lCategories5.push_back(lCategory5_5);
	char lCategory5_6[18] = {77, 97, 114, 114, 105, 101, 100, 45, 65, 70, 45, 115, 112, 111, 117, 115, 101, 0};
	lCategories5.push_back(lCategory5_6);
	mCategories.push_back(lCategories5);

	char lInput6[11] = {111, 99, 99, 117, 112, 97, 116, 105, 111, 110, 0};
	mInputVariables.push_back(lInput6);
	cStringVector lCategories6;

	char lCategory6_0[15] = {80, 114, 111, 102, 45, 115, 112, 101, 99, 105, 97, 108, 116, 121, 0};
	lCategories6.push_back(lCategory6_0);
	char lCategory6_1[16] = {69, 120, 101, 99, 45, 109, 97, 110, 97, 103, 101, 114, 105, 97, 108, 0};
	lCategories6.push_back(lCategory6_1);
	char lCategory6_2[13] = {67, 114, 97, 102, 116, 45, 114, 101, 112, 97, 105, 114, 0};
	lCategories6.push_back(lCategory6_2);
	char lCategory6_3[13] = {65, 100, 109, 45, 99, 108, 101, 114, 105, 99, 97, 108, 0};
	lCategories6.push_back(lCategory6_3);
	char lCategory6_4[6] = {83, 97, 108, 101, 115, 0};
	lCategories6.push_back(lCategory6_4);
	char lCategory6_5[14] = {79, 116, 104, 101, 114, 45, 115, 101, 114, 118, 105, 99, 101, 0};
	lCategories6.push_back(lCategory6_5);
	char lCategory6_6[18] = {77, 97, 99, 104, 105, 110, 101, 45, 111, 112, 45, 105, 110, 115, 112, 99, 116, 0};
	lCategories6.push_back(lCategory6_6);
	char lCategory6_7[2] = {63, 0};
	lCategories6.push_back(lCategory6_7);
	char lCategory6_8[17] = {84, 114, 97, 110, 115, 112, 111, 114, 116, 45, 109, 111, 118, 105, 110, 103, 0};
	lCategories6.push_back(lCategory6_8);
	char lCategory6_9[18] = {72, 97, 110, 100, 108, 101, 114, 115, 45, 99, 108, 101, 97, 110, 101, 114, 115, 0};
	lCategories6.push_back(lCategory6_9);
	char lCategory6_10[16] = {70, 97, 114, 109, 105, 110, 103, 45, 102, 105, 115, 104, 105, 110, 103, 0};
	lCategories6.push_back(lCategory6_10);
	char lCategory6_11[13] = {84, 101, 99, 104, 45, 115, 117, 112, 112, 111, 114, 116, 0};
	lCategories6.push_back(lCategory6_11);
	char lCategory6_12[16] = {80, 114, 111, 116, 101, 99, 116, 105, 118, 101, 45, 115, 101, 114, 118, 0};
	lCategories6.push_back(lCategory6_12);
	char lCategory6_13[8] = {75, 120, 79, 116, 104, 101, 114, 0};
	lCategories6.push_back(lCategory6_13);
	mCategories.push_back(lCategories6);

	char lInput10[13] = {99, 97, 112, 105, 116, 97, 108, 45, 103, 97, 105, 110, 0};
	mInputVariables.push_back(lInput10);
	cStringVector lCategories10;


	char lInput11[13] = {99, 97, 112, 105, 116, 97, 108, 45, 108, 111, 115, 115, 0};
	mInputVariables.push_back(lInput11);
	cStringVector lCategories11;

	char lCategory11_0[2] = {48, 0};
	lCategories11.push_back(lCategory11_0);
	char lCategory11_1[8] = {75, 120, 79, 116, 104, 101, 114, 0};
	lCategories11.push_back(lCategory11_1);
	char lCategory11_2[5] = {49, 57, 48, 50, 0};
	lCategories11.push_back(lCategory11_2);
	char lCategory11_3[5] = {49, 57, 55, 55, 0};
	lCategories11.push_back(lCategory11_3);
	char lCategory11_4[5] = {49, 56, 56, 55, 0};
	lCategories11.push_back(lCategory11_4);
	char lCategory11_5[5] = {49, 52, 56, 53, 0};
	lCategories11.push_back(lCategory11_5);
	char lCategory11_6[5] = {50, 52, 49, 53, 0};
	lCategories11.push_back(lCategory11_6);
	char lCategory11_7[5] = {49, 56, 52, 56, 0};
	lCategories11.push_back(lCategory11_7);
	char lCategory11_8[5] = {49, 54, 48, 50, 0};
	lCategories11.push_back(lCategory11_8);
	char lCategory11_9[5] = {49, 55, 52, 48, 0};
	lCategories11.push_back(lCategory11_9);
	char lCategory11_10[5] = {49, 53, 57, 48, 0};
	lCategories11.push_back(lCategory11_10);
	char lCategory11_11[5] = {49, 56, 55, 54, 0};
	lCategories11.push_back(lCategory11_11);
	char lCategory11_12[5] = {49, 54, 55, 50, 0};
	lCategories11.push_back(lCategory11_12);
	char lCategory11_13[5] = {49, 55, 52, 49, 0};
	lCategories11.push_back(lCategory11_13);
	char lCategory11_14[5] = {49, 53, 54, 52, 0};
	lCategories11.push_back(lCategory11_14);
	mCategories.push_back(lCategories11);
	mOutputVariables.push_back("rr_class");
}

double
ExportedModelInCPP::Kxen_RobustRegression_0_KxVar3(KxSTL::string const& iInput) const {
	if( iInput.empty())
{
		return (double)7.476280483725e-3;
	}
	if ( 0 == iInput.compare(mCategories[0][0].c_str()) ) {
		return (double)-2.971965283987e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][1].c_str()) ) {
		return (double)-1.198249406966e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][2].c_str()) ) {
		return (double)8.466462950968e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][3].c_str()) ) {
		return (double)1.312985299278e-1;
	}
	if ( 0 == iInput.compare(mCategories[0][5].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][7].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][8].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][9].c_str()) ) {
		return (double)1.962705330767e-1;
	}
	if ( 0 == iInput.compare(mCategories[0][10].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][11].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	if ( 0 == iInput.compare(mCategories[0][12].c_str()) ) {
		return (double)1.962705330767e-1;
	}
	if ( 0 == iInput.compare(mCategories[0][13].c_str()) ) {
		return (double)-7.782923849167e-2;
	}
	return (double)7.476280483725e-3;
}

double
ExportedModelInCPP::Kxen_RobustRegression_0_KxVar5(KxSTL::string const& iInput) const {
	if( iInput.empty())
{
		return (double)1.369884076752e-1;
	}
	if ( 0 == iInput.compare(mCategories[1][1].c_str()) ) {
		return (double)-1.274492103096e-1;
	}
	if ( 0 == iInput.compare(mCategories[1][2].c_str()) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == iInput.compare(mCategories[1][3].c_str()) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == iInput.compare(mCategories[1][4].c_str()) ) {
		return (double)-1.274492103096e-1;
	}
	if ( 0 == iInput.compare(mCategories[1][5].c_str()) ) {
		return (double)-8.951928704536e-2;
	}
	if ( 0 == iInput.compare(mCategories[1][6].c_str()) ) {
		return (double)-8.951928704536e-2;
	}
	return (double)1.369884076752e-1;
}

double
ExportedModelInCPP::Kxen_RobustRegression_0_KxVar6(KxSTL::string const& iInput) const {
	if( iInput.empty())
{
		return (double)-7.196725171655e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][0].c_str()) ) {
		return (double)8.314166470599e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][1].c_str()) ) {
		return (double)9.35996019906e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][2].c_str()) ) {
		return (double)1.753792369402e-3;
	}
	if ( 0 == iInput.compare(mCategories[2][3].c_str()) ) {
		return (double)-3.404467022914e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][4].c_str()) ) {
		return (double)1.911905073134e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][6].c_str()) ) {
		return (double)-3.404467022914e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][7].c_str()) ) {
		return (double)-4.648364837538e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][8].c_str()) ) {
		return (double)1.753792369402e-3;
	}
	if ( 0 == iInput.compare(mCategories[2][9].c_str()) ) {
		return (double)-6.082938671308e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][10].c_str()) ) {
		return (double)-4.648364837538e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][11].c_str()) ) {
		return (double)3.089945350411e-2;
	}
	if ( 0 == iInput.compare(mCategories[2][12].c_str()) ) {
		return (double)3.089945350411e-2;
	}
	return (double)-7.196725171655e-2;
}

double
ExportedModelInCPP::Kxen_RobustRegression_0_KxVar10(KxSTL::string const& iInput) const {
	double lValue10 = atof(iInput.c_str());
	if( iInput.empty())
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

double
ExportedModelInCPP::Kxen_RobustRegression_0_KxVar11(KxSTL::string const& iInput) const {
	double lValue11 = atof(iInput.c_str());
	if( iInput.empty())
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

void ExportedModelInCPP::Kxen_RobustRegression_apply(const KxCppRTCase& iInput, KxCppRTCase& oOutput) const {
		double lScore = (double)0.0e0;

	KxCppRTValue lValue;
	lScore +=Kxen_RobustRegression_0_KxVar3(iInput.getValue(0).getValue());
	lScore +=Kxen_RobustRegression_0_KxVar5(iInput.getValue(1).getValue());
	lScore +=Kxen_RobustRegression_0_KxVar6(iInput.getValue(2).getValue());
	lScore +=Kxen_RobustRegression_0_KxVar10(iInput.getValue(3).getValue());
	lScore +=Kxen_RobustRegression_0_KxVar11(iInput.getValue(4).getValue());
	char lBuffer [50];
	sprintf (lBuffer, "%.15f",lScore);
	oOutput.setValue(mOutputVariables[0].c_str(), KxSTL::string(lBuffer));
}

void
ExportedModelInCPP::apply(const KxCppRTCase& iInput, KxCppRTCase &oOutput) const {
	Kxen_RobustRegression_apply( iInput, oOutput);
}

static ExportedModelInCPP gExportedModelInCPP(KxCppRTModelManager::instance());
