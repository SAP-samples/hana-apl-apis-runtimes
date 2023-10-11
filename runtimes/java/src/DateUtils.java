// ----------------------------------------------------------------------------
// Copyright....: (c) SAP 1999-2021
// Project......: 
// Library......: 
// File.........: DateUtils.java
// Author.......: 
// Created......: Thu Nov 08 11:04:31 2007
// Description..:
// ----------------------------------------------------------------------------


package KxJRT;


import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParseException;

public class DateUtils {

	static short days_in_month[][] = {
		{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
		{31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
	};
	// -- cumulative
	static short nb_days_before_month[][] = {
		{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334},
		{0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335}
	 };
	  
	/**
	 * ISO T Format getter
	 * @return the ISO format with a T separator
	 */
	private static SimpleDateFormat getISODateTimeFormat() {
		return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	}
	/**
	 * ISO Format getter
	 * @return the ISO format with a space separator
	 */
	private static SimpleDateFormat getISODateTimeFormatT() {
		return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
	}
	/**
	 * ISO Format getter
	 * @return the ISO format with a space separator
	 */
	private static SimpleDateFormat getISODateFormat() {
		return new SimpleDateFormat("yyyy-MM-dd");
	}
	/**
	 * Select best format among those defined.
	 * @param iDate String to Parse
	 * @return the Date
	 * @throws ParseException if String is not well Parsed
	 */
	public static Date getISODateFromString(String iDate) throws ParseException {
		try {
			return getISODateTimeFormat().parse(iDate);
		} catch (ParseException e) {
			try {
				return getISODateTimeFormatT().parse(iDate);
			} catch (ParseException lException) {
				return getISODateFormat().parse(iDate);
			}
		}
	}

	public static boolean isLeapYear(int iYear) {
		boolean lIsLeap = false;
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
	public static int ymdToScalar(int iYear, int iMonth, int iDay) {
		int	lScalar;
		lScalar	= iDay + ((iMonth*3057-3007)/100);
		if (2 < iMonth)
			lScalar	-= isLeapYear(iYear) ? 1 : 2;
		iYear--;
		lScalar	+= (iYear * 365 + iYear / 4 - iYear / 100 + iYear / 400);
		return lScalar;
	}
	public static int getDaysInMonth(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		int lMonthDay = 31;
		if (lCalendar.get(Calendar.MONTH) == Calendar.FEBRUARY) {
			if (isLeapYear(lCalendar.get(Calendar.YEAR))) {
				lMonthDay = 29;
			}
			else {
				lMonthDay = 28;
			}
		}
		else if ((lCalendar.get(Calendar.MONTH) == Calendar.APRIL) ||
				 (lCalendar.get(Calendar.MONTH) == Calendar.JUNE) ||
				 (lCalendar.get(Calendar.MONTH) == Calendar.SEPTEMBER) ||
				 (lCalendar.get(Calendar.MONTH) == Calendar.NOVEMBER)) {
			lMonthDay = 30;
		}
		return lMonthDay;
	}
	public static int getDayOfWeek(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return (ymdToScalar(lCalendar.get(Calendar.YEAR),
							lCalendar.get(Calendar.MONTH) - Calendar.JANUARY + 1,
							lCalendar.get(Calendar.DAY_OF_MONTH)) % 7);
	}	
	public static int getDayOfMonth(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.DAY_OF_MONTH);
	}
	public static int getDayOfYear(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		
		boolean lIsLeap = isLeapYear(lCalendar.get(Calendar.YEAR));
		int lDay =  lCalendar.get(Calendar.DAY_OF_MONTH);
		
		return (lDay + nb_days_before_month[lIsLeap ? 1 : 0][lCalendar.get(Calendar.MONTH)]);
	}

	public static boolean hasFiveWeeks(Date iDate) {
		int lNbDays = getDaysInMonth(iDate);
		int lFirstDay = getDayOfWeek(iDate);

		if ((31 == lNbDays) && (lFirstDay >= 1) && (lFirstDay <=3))
		return true;
		else if ((30 == lNbDays) && ((2 == lFirstDay) || (3 == lFirstDay)))
			return true;
		else if ((29 == lNbDays) && (3 == lFirstDay))
			return true;
		else
			return false;
	}

	public static int getWeekOfMonth(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		Calendar lTempCalendar = Calendar.getInstance();
		lTempCalendar.set(lCalendar.get(Calendar.YEAR),
						  lCalendar.get(Calendar.MONTH),
						  1);
		int lFirstWDay = getDayOfWeek(lTempCalendar.getTime());
		int lIsFirstWeek = 0;

		if (lFirstWDay <= 3) {
			lIsFirstWeek = 1;
		}

		int lFirstIntWDay = (((6 - lFirstWDay) != 6) ? (8 - lFirstWDay) : 1);
		int lLastIntWDay =
			lCalendar.get(Calendar.DAY_OF_MONTH) - getDayOfWeek(iDate);
		int lNbIntWeekBefore = ((lLastIntWDay - lFirstIntWDay) / 7);
		int lWMonth0 =
			lNbIntWeekBefore + lIsFirstWeek + ((lFirstIntWDay!=1)? 1 : 0);

		int lWMonth1 = lWMonth0;
		if( 0 == lWMonth0 )
		{
			Calendar lPseudoCalendar = Calendar.getInstance();
			if ((lCalendar.get(Calendar.MONTH) - 1) < 0) {
				lPseudoCalendar.set(lCalendar.get(Calendar.YEAR) - 1, 11, 1);
			}
			else {
				lPseudoCalendar.set(lCalendar.get(Calendar.YEAR) ,
									lCalendar.get(Calendar.MONTH) - 1,
									1);
			}
			boolean l5Weeks = hasFiveWeeks(lPseudoCalendar.getTime());
			lWMonth1 = 4 + (l5Weeks ? 1 : 0);
		}

		int lNbDaysInMonth = getDaysInMonth(iDate);

		Calendar lNewDate = Calendar.getInstance();
		lNewDate.set(lCalendar.get(Calendar.YEAR),
					 lCalendar.get(Calendar.MONTH),
					 lNbDaysInMonth);
		int lLastWDay = getDayOfWeek(lNewDate.getTime());

		int lWMonth2 = lWMonth1;
		if (((lNbDaysInMonth - lLastWDay) <= lCalendar.get(Calendar.DAY_OF_MONTH))
			&& (lLastWDay < 3))
			lWMonth2 = 1;
		return lWMonth2;
	}

	public static int getWeekOfYear(Date iDate) {
		int lYDay = getDayOfYear(iDate);
		int lWDay = getDayOfWeek(iDate);

		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);

		Calendar lTempCalendar = Calendar.getInstance();
		lTempCalendar.set(lCalendar.get(Calendar.YEAR),
						  Calendar.JANUARY,
						  1);
		int lJan1WDay = getDayOfWeek(lTempCalendar.getTime());

		boolean lIsLeap = isLeapYear(lCalendar.YEAR);
		if ((lYDay <= (7 - lJan1WDay)) && (lJan1WDay < 3))
		{
			//last week of the year iYear - 1
			boolean lLeapYear = isLeapYear(lCalendar.YEAR - 1);
			if ((lJan1WDay == Calendar.FRIDAY) ||
				((lJan1WDay == Calendar.SATURDAY) && lLeapYear))
				return 53;
			else
				return 52;
		}
		int lNbDaysInY = 365;
		if (lIsLeap) {
			lNbDaysInY++;
		}
		if ((lNbDaysInY - lYDay) < (3 - lWDay))
			return 1;

		int lNbReadjustedDays = lYDay + (7 - lWDay) + (lJan1WDay - 1);
		int lWNumber = (lNbReadjustedDays / 7);
		if( lJan1WDay > 3) 
			return lWNumber - 1;
		else
			return lWNumber;
	}
	public static int getMonthOfQuarter(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);

		int lMonth = lCalendar.get(Calendar.MONTH) - Calendar.JANUARY + 1;
		lMonth = lMonth  % 3;
		int lTest = 3 % 3;
		if (lMonth == lTest) {
			return 3;
		}
		return lMonth;
	}
	public static int getMonthOfYear(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return (lCalendar.get(Calendar.MONTH) - Calendar.JANUARY + 1);
	}
	public static int getYear(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.YEAR);
	}
	public static int getQuarter(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		int lMonth = lCalendar.get(Calendar.MONTH);
		int lQuarter = 4;
		if (lMonth <= Calendar.MARCH) {
			lQuarter = 1;
		}
		else if (lMonth <= Calendar.JUNE) {
			lQuarter = 2;
		}
		else if (lMonth <= Calendar.SEPTEMBER) {
			lQuarter = 3;
		}
		return lQuarter;
	}
	public static int getHour(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.HOUR_OF_DAY);
	}
	public static int getMinute(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.MINUTE);
	}
	public static int getSecond(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.SECOND);
	}
	public static int getMicrosecond(Date iDate) {
		Calendar lCalendar = Calendar.getInstance();
		lCalendar.setTime(iDate);
		return lCalendar.get(Calendar.MILLISECOND);
	}

	
}
