// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......:
// Library......:
// File.........: KxCppRTUtilities.cpp
// Author.......:
// Created......: Tue Mar 09 18:00:29 2010
// Description..:
// ----------------------------------------------------------------------------

#include "KxCppRTUtilities.h"
#include <limits>

void KxStringTrim (const char* iWord, size_t iLeft, size_t iLength, const char* iSeparators,
                   size_t* oLeft, size_t* oLength)
{
    size_t lIndex = iLeft;

    if (iLength > 0)
    {
        *(oLength) = 0;
        while ((NULL != (void*)strchr (iSeparators, iWord[lIndex])) && (lIndex < iLeft + iLength))
        {
            lIndex++;
        }
        *(oLeft) = lIndex;
        lIndex = iLeft + iLength - 1;
        while ((NULL != (void*)strrchr (iSeparators, iWord[lIndex])) && (lIndex > *(oLeft)))
        {
            lIndex--;
        }
        *(oLength) = lIndex - *(oLeft) + 1;
    }
    else
    { /* iLength is <= 0 */
        *(oLeft) = iLeft;
        *(oLength) = 0;
    }
}

long KxStringTokenSTL (const char* iLine, size_t iLeft, const char* iSeparators, size_t* oLength)
{
    size_t lLength = strlen (iLine + iLeft);

    if (0 <= lLength)
    {
        /* I want to stop at the first char in separator list */
        *(oLength) = strcspn (iLine + iLeft, iSeparators);
        if (*(oLength) < lLength)
            return (KXEN_S_OK);
        else
            return (KXEN_S_FALSE);
    }
    else
    {
        return (KXEN_E_INVALIDARG);
    }
}

long KxStringSplitNoDupSTL (KxSTL::vector<KxSTL::string>& oWords, KxSTL::string iLine,
                            const char* iSeparators, const char* iTrimedChars)
{
    long lResult = 0;
    size_t lNextWord = 0;
    size_t lLeftBefore = 0;
    size_t lTokenLength;
    size_t lFirst;
    size_t lLength;

    if (iLine.empty ()) /* Empty string */
        return 0;


    lResult = KxStringTokenSTL (iLine.c_str (), lLeftBefore, iSeparators, &lTokenLength);

    while (0 <= lResult)
    {
        KxStringTrim (iLine.c_str (), lLeftBefore, lTokenLength, iTrimedChars, &lFirst, &lLength);
        /* While there are tokens in "string" */
        if ((lFirst + lLength) < iLine.size ())
        {
            iLine[lFirst + lLength] = 0;
        }

        oWords.push_back (iLine.c_str () + lFirst);
        /* Prepare to get the next token: */
        /* we've found a separator, just skip it */
        lLeftBefore += lTokenLength + 1;
        if (KXEN_S_FALSE == lResult)
        {
            lResult = KXEN_E_INVALIDARG;
        }
        else
        {
            lResult = KxStringTokenSTL (iLine.c_str (), lLeftBefore, iSeparators, &lTokenLength);
        }
    }
    return lNextWord;
}

int KxGetStringSTL (FILE* iFile, KxSTL::string& oString)
{
    int ch, /*  Character read from file         */
      cnbr; /*  Index into returned string       */

    oString.erase (); /* erase 0 to npos */

    if (NULL == iFile)
        return 0; /** false */

    cnbr = 0; /* Start at the beginning.	 */
    for (;;)
    {
#if defined(_WIN32)
        ch = getc (iFile);
#else
        ch = getc_unlocked (iFile);
#endif
        if (ch == '\r') /* Found carriage-return     */
            ch = '\r';  /* ignore CR				 */
        else
        {
            if ((ch == '\n')   /*  Have end of line         */
                || (ch == EOF) /*    or end of file         */
                || (ch == 26)) /*    or MS-DOS Ctrl-Z       */
            {
                return (ch == '\n' || cnbr); /*  and return TRUE/FALSE    */
            }
            else
            {
                oString += ch; /*  Else add char to string  */
            }
        }
    }
}

double KxConvertToDouble(const char* iValue, bool& oMissing)
{
    char* pEnd;
    double value = std::strtod(iValue, &pEnd);
    if (pEnd == iValue)
    {
        oMissing = true;
        return std::numeric_limits<double>::quiet_NaN();
    }
    return value;
}
