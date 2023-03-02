/* ----------------------------------------------------------------------------
 * Copyright....: (c) SAP 1999-2021
 * Project......: 
 * Library......: 
 * File.........: KxUtil.h
 * Author.......: 
 * Created......: Thu Jun 01 17:52:08 2006
 * Description..:
 * ----------------------------------------------------------------------------
 */

#ifndef _cKXDATEUTIL_H
#define _cKXDATEUTIL_H 1

#include "Config.h"

#define ISO_CAL 0

#define	CENTURIES_SINCE_1700(yr) \
	((yr)>1700 ? (yr)/100-17 : 0)

#define	QUAD_CENTURIES_SINCE_1700(yr) \
	((yr)>1600 ? ((yr)-1600)/400 : 0)

#define	LEAP_YEARS_AFTER_JC(yr) \
	(((yr)-1)/4-CENTURIES_SINCE_1700((yr)-1) + \
                  QUAD_CENTURIES_SINCE_1700((yr)-1))

#define	LEAP_YEARS_BEFORE_JC(yr) \
	((yr)/4-(yr)/100 + (yr)/400)

#define	DAY_COUNT_AROUND_JC(yr) \
	(((yr)>0) ? (365.0*((yr)-1)+LEAP_YEARS_AFTER_JC(yr)): \
		(365.0*(yr)+LEAP_YEARS_BEFORE_JC(yr)))

#define MONTHS_TO_DAYS(month)	\
	(((month) * 3057 - 3007) / 100)

#define YEARS_TO_DAYS(yr) \
	((yr) * 365L + (yr) / 4 - (yr) / 100 + (yr) / 400)

#if ISO_CAL
enum eWeekDay {
    DOW_IGNORE	= -1,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday
    sunday,
};
#else
enum eWeekDay {
    DOW_IGNORE	= -1,
    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday
};
#endif

static short nb_days_before_month[2][12] = {
	{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 },
	{0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 }
};

static short days_in_month[2][12] = {
	{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
	{31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
};

bool isLeapYear(int iYear)
{
	bool lIsLeap = false;

	if ((iYear % 4000) == 0)
	{
		lIsLeap = false;
	}
	else if ((iYear % 400) == 0)
	{
		lIsLeap = true;
	}
	else if (((iYear % 4) == 0) && ((iYear % 100) != 0))
	{
		lIsLeap = true;
	}

	return lIsLeap;
}

static int
ymdToScalar(int iYear, int iMonth, int iDay)
{
    int	lScalar;

    lScalar	= iDay + MONTHS_TO_DAYS(iMonth - 1 + 1);
    if (2 < iMonth)
		lScalar	-= isLeapYear(iYear) ? 1 : 2;
    iYear--;
    lScalar	+= YEARS_TO_DAYS(iYear);
    return lScalar;
}

int
getDOW(int iYear, int iMonth, int iDay)
{
#if (!ISO_CAL)
    return (eWeekDay)(ymdToScalar( iYear, iMonth, iDay ) % 7);
#else
    return (eWeekDay)((ymdToScalar( iYear, iMonth, iDay ) - 1) % 7);
#endif
}

bool hasFiveWeeks(int iYear, int iMonth)
{
	int lNbDays = days_in_month[isLeapYear(iYear)][iMonth - 1];
	int lFirstDay = (int)(getDOW( iYear, iMonth, 1 ));

	if ((31 == lNbDays) && (lFirstDay >= 1) && (lFirstDay <=3))
		return true;
	else if ((30 == lNbDays) && ((2 == lFirstDay) || (3 == lFirstDay)))
		return true;
	else if ((29 == lNbDays) && (3 == lFirstDay))
		return true;
	else
		return false;
}

int getDOY(int iYear, int iMonth, int iDay)
{
	int lIsLeap = isLeapYear(iYear);
	return (short)(iDay + nb_days_before_month[lIsLeap][iMonth - 1]);
}

int getWOY(int iYear, int iMonth, int iDay)
{
	int lYDay = getDOY(iYear, iMonth, iDay);
	int lJan1WDay = getDOW(iYear, 1, 1);
	int lWDay = getDOW(iYear, iMonth, iDay);

	//check if the the current date falls in Y-1, WeekNumber 52 or 53
	if( (lYDay <= (7 - lJan1WDay)) && (lJan1WDay < 3) )
	{
		//last week of the year iYear - 1
		bool lLeapYear = isLeapYear(iYear-1);
		if ((lJan1WDay == friday) || ((lJan1WDay == saturday) && lLeapYear))
			return 53;
		else
			return 52;
	}
	//check if the current date falls in Y+1, WeekNumber 1
	int lNbDaysInY = 365;
	if (isLeapYear(iYear)) lNbDaysInY++;
	if ((lNbDaysInY - lYDay) < (3 - lWDay))
		return 1;

	int lNbReadjustedDays = lYDay + (7 - lWDay) + (lJan1WDay - 1);
	int lWNumber = (int)(lNbReadjustedDays / 7);
	if( lJan1WDay > 3) 
		return lWNumber - 1;
	else
		return lWNumber;
}

int getWOM(int iYear, int iMonth, int iDay)
{
	int lFirstWDay = getDOW(iYear, iMonth, 1);
	int lIsFirstWeek = (lFirstWDay <= 3);
	int lFirstIntWDay = ( ((6 - lFirstWDay) != 6)? (8 - lFirstWDay) : 1 );
	int lLastIntWDay = iDay - getDOW(iYear,iMonth,iDay);
	int lNbIntWeekBefore = (int)((lLastIntWDay - lFirstIntWDay) / 7);

	int lWMonth0 = lNbIntWeekBefore + lIsFirstWeek + ((lFirstIntWDay!=1)? 1 : 0);

	int lWMonth1 = lWMonth0;
	if( 0 == lWMonth0 )
	{
		bool l5Weeks = (hasFiveWeeks(((iMonth-1) < 0) ? (iYear-1) : iYear,
	( ((iMonth-1) < 0)? 11 : (iMonth - 1) ) ));
		lWMonth1 = (short)(4 + (l5Weeks ? 1 : 0));
	}

	int lNbDaysInMonth = days_in_month[isLeapYear(iYear)][iMonth - 1];
	int lLastWDay = getDOW(iYear, iMonth, lNbDaysInMonth);

	int lWMonth2 = lWMonth1;
	if (((lNbDaysInMonth - lLastWDay) <= iDay) && (lLastWDay < 3))
		lWMonth2 = 1;

	return lWMonth2;
}	

int getQOY(int iMonth)
{
	if (iMonth <= 3)
	{
		return 1;
	}
	else if (iMonth <= 6)
	{
		return 2;
	}
	else if (iMonth <= 9)
	{
		return 3;
	}
	return 4;
}

int getMOQ(int iMonth)
{
	int lM = iMonth % 3;
	if (lM == 0) 
	{
		lM = 3;
	}
	return lM;
}
#endif
