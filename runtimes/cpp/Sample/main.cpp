// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: Test.cpp
// Author.......: 
// Created......: Mon Apr 10 14:28:19 2006
// Description..:
// ----------------------------------------------------------------------------

#include "KxCppRTUtilities.h"
#include "KxCppRTModelManager.h"
#include "SampleMappedCase.cpp"

// Skip the UTF8 magic number at the begining of a file.
bool
read_UTF8MagicNumber (FILE* opened)
{
	int c1 = 0, c2 = 0, c3 = 0;
	c1 = fgetc (opened);
	c2 = fgetc (opened);
	c3 = fgetc (opened);
	bool out = true;
	if (c1 != 0xEF || c2 != 0xBB || c3 != 0xBF)
	{
		fseek (opened, 0, SEEK_SET);
		out = false;
	}
	return out;
}

bool
isInputWithHeader(KxSTL::vector<KxSTL::string> const& iColumnName,
				  KxSTL::string const& iFirstInputName)
{
	for (unsigned int lIdx = 0; lIdx < iColumnName.size(); lIdx++)
	{
		if (iColumnName[lIdx] == iFirstInputName)
		{
			return true;
		}
	}
	return false;
}

int main( int argc, char ** argv )
{
	FILE*	lInFile		= NULL;
	FILE*	lOutFile	= stdout;
	int i;
	KxSTL::string lModelName;

	for( int i=1 ; (i < argc) ; i++ )
	{
		if (strcmp(argv[i], "-in") == 0)
		{
			i++;
			lInFile	= fopen(argv[i], "r");
			if (NULL == lInFile)
			{
				fprintf(stdout, "Impossible to open input file %s!\n",
						argv[i]);
				exit(0);
			}
			bool lIsUTF8InputFile = read_UTF8MagicNumber(lInFile);
			if (lIsUTF8InputFile)
			{
				fprintf(stdout, "your input file is with an utf-8 encoding!\n");
			}
		}
		if (strcmp(argv[i], "-model") == 0)
		{
			i++;
			if (i < argc)
				lModelName = argv[i];
			if (lModelName.empty())
			{
				fprintf(stdout, "The model name is empty!\n");
				exit(0);
			}
		}
		if (strcmp(argv[i], "-out") == 0)
		{
			i++;
			lOutFile	= fopen(argv[i], "w");
			if (NULL == lOutFile)
			{
				fprintf(stdout, "Impossible to open output file %s!\n",
						argv[i]);
				exit(0);
			}
		}
	}
	if (NULL == lInFile)
	{
		fprintf(stdout, "Please specify input file!!\n");
		exit(0);
	}
	if (lModelName.empty())
	{
		fprintf(stdout, "Use -model in order to define the model name!\n");
		exit(0);
	}

	try {
		// return model called <lModelName>
		const KxCppRTModel& lModel = KxCppRTModelManager::getKxModel(lModelName);
		// return the variable names used
		KxSTL::vector<KxSTL::string> lInputNames = lModel.getModelInputVariables();

		SampleMappedCase lInCase 	=  SampleMappedCase(lInputNames);
		SampleMappedCase lOutCase =
			SampleMappedCase(lModel.getModelOutputVariables());

		KxSTL::string lSTLLine;
		KxSTL::vector<KxSTL::string> lColumnName;

		i=0;
		while (KxGetStringSTL(lInFile, lSTLLine))
		{
			KxSTL::vector<KxSTL::string> lFieldName;
			if (lColumnName.size() == 0)
			{
				KxStringSplitNoDupSTL(lColumnName,
									  lSTLLine,
									  KX_FIELDSEPARATOR,
									  KX_TRIMEDCHAR);
				if (isInputWithHeader(lColumnName, lInputNames[0]))
				{
					int lStatus = KxGetStringSTL(lInFile, lSTLLine);
					if (lStatus == 0)
						break;
				}
				else
				{
					lColumnName.swap(lInputNames);
				}
			}

			KxStringSplitNoDupSTL(lFieldName,
								  lSTLLine,
								  KX_FIELDSEPARATOR,
								  KX_TRIMEDCHAR);

			// set the input case with the correct needed model values
			for (unsigned int lIdx = 0;
				 lIdx < lColumnName.size();
				 lIdx++)
			{	
				lInCase.setValue(lColumnName[lIdx],
								 KxCppRTValue(lFieldName[lIdx].c_str()));
			}
		
			// apply
			lModel.apply(lInCase, lOutCase);

			// write the index of the current line
			if (lOutFile)
				fprintf(lOutFile, "%d", i);

			// write all model outputs for the current line
			for (unsigned int lIdx = 0; lIdx < lOutCase.getSize(); lIdx++)
			{
				KxCppRTValue lScore =	lOutCase.getValue(lIdx);
				if (lOutFile)
					fprintf(lOutFile, ",%s", (lScore.getValue()).c_str());
			}

			// write a head line
			if (lOutFile)
				fprintf(lOutFile, "\n");
			fflush(lOutFile);

			// increment the index of the current line
			i++;
		}
	}
	catch(const char* i)
	{
		fprintf(stdout, "%s\n", i);
		exit(0);
	}
	fclose(lOutFile);
	fclose(lInFile);


	return 0;
}
