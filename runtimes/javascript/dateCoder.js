/**
 * dateCoder.js v1.0.0
 * Copyright (c) 2020 by SAP SE
 */

 /** 
 * 'define' is a function which implements the Asynchronous Module Definition API.
 * If it is not already here, use amdefine module that provide it's own
 * implementation to use in Node.js:
 * - Browser environment : define() implementation comes from require.js
 * - Node.js environment : define() implementation comes from amdefine
 * --> See readme.txt > Requirements
 */
if (typeof define !== 'function') { var define = require('amdefine')(module); }

define([], function() {

    "use strict";

    var DAYS_IN_MONTH = [
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    ];
    var NB_DAYS_BEFORE_MONTH = [
        [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
        [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
    ];

    /*
     * The first week of a given year is the first week which contains at least 4 days in this year
     * In the same way, the first week of a given month is the first week which contains at least 4 days in this month.
     * -> Considering the day of week (0-based index from 0 to 6) of the first day of a given month:
     *    -> if it is lower or equal than 3, then this week contains at least 4 days in the month,
     *       and it is considered as the first week of the month
     *    -> if it is greater than 3, then this week contains less than 4 days in the month,
     *       and it is considered as the last week of the previous month
     */
    var FOURTH_DAY_INDEX_FOR_FULL_WEEK = 3;

    function isLeapYear(year) {
        var isLeap = false;
        /*
         * a leap year could not be divided by 4000
         * a leap year could be divided by 400
         * a leap year could be divided by 4 and not by 100
         */
        if ((year % 4000) == 0) {
            isLeap = false;
        } else if ((year % 400) == 0) {
            isLeap = true;
        } else if (((year % 4) == 0) && ((year % 100) != 0)) {
            isLeap = true;
        }
        return isLeap;
    }

    function hasFiveWeeks(year, month) {
        var nbDaysInMonth = DAYS_IN_MONTH[isLeapYear(year) ? 1 : 0][month];
        var firstDayOfMonth = new Date(year, month, 1);
        var dayOfWeekForFirstDayOfMonth = getDayOfWeek(firstDayOfMonth);
        if ((31 == nbDaysInMonth) && (dayOfWeekForFirstDayOfMonth >= 1) && (dayOfWeekForFirstDayOfMonth <= 3))
            return true;
        else if ((30 == nbDaysInMonth) && ((2 == dayOfWeekForFirstDayOfMonth) || (3 == dayOfWeekForFirstDayOfMonth)))
            return true;
        else if ((29 == nbDaysInMonth) && (3 == dayOfWeekForFirstDayOfMonth))
            return true;
        else
            return false;
    }

    function getDayOfWeek(date) {
        // Sunday -> Saturday : 0 -> 6
        return date.getDay();
    }

    function getDayOfMonth(date) {
        return date.getDate();
    }

    function getDayOfYear(date) {
        // 1-based day of year
        var month = date.getMonth();
        var numberOfDaysBeforeMonth = NB_DAYS_BEFORE_MONTH[isLeapYear(date.getFullYear()) ? 1 : 0][month];
        return date.getDate() + numberOfDaysBeforeMonth;
    }

    function getWeekOfMonth(date) {

        // Create a new date for the first day of the month of the specified date
        var firstDayOfMonth = new Date(getYear(date), date.getMonth(), 1);

        // Get the day of week for the first day of month
        var dayOfWeekForFirstDayOfMonth = getDayOfWeek(firstDayOfMonth);
        // And check if the first wekk is a real week (at least 4 days)
        var firstWeekIsRealWeek = dayOfWeekForFirstDayOfMonth <= FOURTH_DAY_INDEX_FOR_FULL_WEEK;

        // Get the day of month for the first day of the first full week (7 days)
        var dayOfMonthForFirstFullWeek = dayOfWeekForFirstDayOfMonth != 0 ? 8 - dayOfWeekForFirstDayOfMonth : 1;

        // Get the day of month for the first day of the specified week (based on input date)
        var dayOfMonthForFirstDayOfSpecifiedWeek = getDayOfMonth(date) - getDayOfWeek(date);

        // Get the number of weeks before the week of the sepcified date
        var numberOfWeeksBefore = (dayOfMonthForFirstDayOfSpecifiedWeek - dayOfMonthForFirstFullWeek) / 7;

        // Get the week number of the sepcified date (1-based)
        var weekOfMonth = numberOfWeeksBefore;
        if (firstWeekIsRealWeek) weekOfMonth++;
        if (dayOfMonthForFirstFullWeek != 1) weekOfMonth++;

        // correct the index for the possible last week of the previous month.
        if (weekOfMonth == 0) {
            var currentMonth = date.getMonth(); // 0-based
            var previousMonth = currentMonth == 0 ? 11 : currentMonth - 1;
            var yearOfPreviousMonth = date.getFullYear();
            if (currentMonth == 0) {
                yearOfPreviousMonth--;
            }
            weekOfMonth = 4;
            if (hasFiveWeeks(yearOfPreviousMonth, previousMonth)) {
                weekOfMonth++;
            }
        }

        // correct the index for the possible first week of the next month.
        var nbDaysInMonth = DAYS_IN_MONTH[isLeapYear(getYear(date)) ? 1 : 0][date.getMonth()];
        var lastDayOfMonth = new Date(getYear(date), date.getMonth(), nbDaysInMonth);
        var dayOfWeekForLastDayOfMonth = getDayOfWeek(lastDayOfMonth);

        if (nbDaysInMonth - dayOfWeekForLastDayOfMonth <= getDayOfMonth(date) && dayOfWeekForLastDayOfMonth < FOURTH_DAY_INDEX_FOR_FULL_WEEK) {
            weekOfMonth = 1;
        }

        return weekOfMonth;
    }

    function getWeekOfYear(date) {

        var currentYear = getYear(date);
        var dayOfYear = getDayOfYear(date);
        // Get day of week for 1st of January
        var firstDayOfYear = new Date(currentYear, 0 /* index of january is 0 */ , 1 /* first day of month is 1 */ );
        var dayOfWeekForFirstDayOfYear = getDayOfWeek(firstDayOfYear);
        // Get the day of week for the current date
        var dayOfWeekForCurrentDate = getDayOfWeek(date);

        // check if the the current date falls in Y-1, WeekNumber 52 or 53
        if (dayOfYear <= (7 - dayOfWeekForFirstDayOfYear) && dayOfWeekForFirstDayOfYear > FOURTH_DAY_INDEX_FOR_FULL_WEEK) {
            // last week of the previous year
            var previousYearIsLeapYear = isLeapYear(currentYear - 1);
            if (dayOfWeekForFirstDayOfYear == 5 /* Friday */ || (dayOfWeekForFirstDayOfYear == 6 /* Saturday */ && previousYearIsLeapYear)) {
                return 53;
            } else {
                return 52;
            }
        }

        // check if the current date falls in Y+1
        var numberOfDaysInYear = isLeapYear(currentYear) ? 366 : 365;
        if ((numberOfDaysInYear - dayOfYear) < (FOURTH_DAY_INDEX_FOR_FULL_WEEK - dayOfWeekForCurrentDate)) {
            return 1;
        }

        // default WeekNumber, from 1 through 53
        var totalNumberOfDaysIncludingFullCurrentWeek = dayOfYear + (7 - dayOfWeekForCurrentDate) + (dayOfWeekForFirstDayOfYear - 1);
        var weekNumber = totalNumberOfDaysIncludingFullCurrentWeek / 7;
        if (dayOfWeekForFirstDayOfYear > FOURTH_DAY_INDEX_FOR_FULL_WEEK) {
            // Remove the first week since it does not contain 4 days...
            weekNumber--;
        }
        return weekNumber;
    }

    function getMonthOfQuarter(date) {
        // 1-based month index in the current quarter
        return (date.getMonth() % 3) + 1;
    }

    function getMonthOfYear(date) {
        // 1-based month index (January = 1);
        return date.getMonth() + 1;
    }

    function getYear(date) {
        return date.getFullYear();
    }

    function getQuarterOfYear(date) {
        // 1-based quarter index for the current month
        return Math.floor(date.getMonth() / 3) + 1;
    }

    function getHour(date) {
        return date.getHours();
    }

    function getMinute(date) {
        return date.getMinutes();
    }

    function getSecond(date) {
        return date.getSeconds();
    }

    function getMicroSecond(date) {
        return date.getMilliseconds() * 1000;
    }

    function applyTransformation(date, transformation) {
        switch (transformation) {
            case "DayOfWeek":
                return getDayOfWeek(date);
            case "DayOfMonth":
                return getDayOfMonth(date);
            case "DayOfYear":
                return getDayOfYear(date);
            case "WeekOfMonth":
                return getWeekOfMonth(date);
            case "WeekOfYear":
                return getWeekOfYear(date);
            case "MonthOfQuarter":
                return getMonthOfQuarter(date);
            case "MonthOfYear":
                return getMonthOfYear(date);
            case "Year":
                return getYear(date);
            case "QuarterOfYear":
                return getQuarterOfYear(date);
            case "Hour":
                return getHour(date);
            case "Minute":
                return getMinute(date);
            case "Second":
                return getSecond(date);
            case "MicroSecond":
                return getMicroSecond(date);
            default:
                throw "Invalid date transformation '" + transformation + "'!";
        }
    }

    function getTransformationSuffix(transformation) {
        switch (transformation) {
            case "DayOfWeek":
                return "_DoW";
            case "DayOfMonth":
                return "_DoM";
            case "DayOfYear":
                return "_DoY";
            case "WeekOfMonth":
                return "_WoM";
            case "WeekOfYear":
                return "_WoY";
            case "MonthOfQuarter":
                return "_MoQ";
            case "MonthOfYear":
                return "_M";
            case "Year":
                return "_Y";
            case "QuarterOfYear":
                return "_QoY";
            case "Hour":
                return "_H";
            case "Minute":
                return "_Mi";
            case "Second":
                return "_S";
            case "MicroSecond":
                return "_mu";
            default:
                throw "Invalid date transformation '" + transformation + "'!";
        }
    }

    /**
     * The dateCoder module povides two methods:
     * - applyTransformation applies a transformation to a date
     * - getTransformationSuffix returns the influencer suffix depending on a transformation type
     */
    return {
        "applyTransformation": applyTransformation,
        "getTransformationSuffix": getTransformationSuffix
    };
});