//
//  FajrWake.swift
//  Fajr Wake
//
//  Created by Abidi on 5/13/16.
//  Copyright © 2016 FajrWake. All rights reserved.
//

import Foundation

// MARK: - Protocols

// MARK: - Error Types


// MARK: - Helper Methods

// local GMT
class LocalGMT {
    class func getLocalGMT() -> Double {
        let localTimeZone = NSTimeZone.localTimeZone().abbreviation!
        let notCorrectedGMTFormat = localTimeZone.componentsSeparatedByString("GMT")
        let correctedGMTFormat: String = notCorrectedGMTFormat[1]
        let gmtArr = correctedGMTFormat.characters.split { $0 == ":" } .map {
            (x) -> Int in return Int(String(x))!
        }
        var gmt: Double = Double(gmtArr[0])
        
        if gmtArr[0] > 0 && gmtArr[1] == 30 {
            gmt += 0.5
        }
        if gmtArr[0] < 0 && gmtArr[1] == 30 {
            gmt -= 0.5
        }
        return gmt
    }
}

class DaysToRepeatLabel {
    class func getTextToRepeatDaysLabel(days: [Days]) -> String {
        var daysInString: [String] = []
        var daysForLabel: String = ""
        
        let weekends = [Days.Saturday, Days.Sunday]
        let weekdays = [Days.Monday, Days.Tuesday, Days.Wednesday, Days.Thursday, Days.Friday]
        
        let daysSet = Set(days)
        let findWeekendsListSet = Set(weekends)
        let findWeekdaysListSet = Set(weekdays)
        
        let containsWeekends = findWeekendsListSet.isSubsetOf(daysSet)
        let containsWeekdays = findWeekdaysListSet.isSubsetOf(daysSet)
        
        if days.count == 7 {
            daysForLabel += "Everyday"
            return daysForLabel
        }
        
        if days.count == 1 {
            daysForLabel += "\(days[0].rawValue)"
            return daysForLabel
        }
        
        // storing enum raw values in array to check if array contains (for array.contains method)
        for day in days {
            daysInString.append(day.rawValue)
        }
        
        if days.count == 2 {
            if containsWeekends {
                daysForLabel += "Weekends"
                return daysForLabel
            }
        }
        
        if days.count == 5 {
            if containsWeekdays {
                daysForLabel += "Weekdays"
                return daysForLabel
            }
        }
        
        for day in days {
            let str = day.rawValue
            daysForLabel += str[str.startIndex.advancedBy(0)...str.startIndex.advancedBy(2)] + " "
        }
        
        return daysForLabel
    }
}

// MARK: - Concrete Types

enum SalatsAndQadhas: Int {
    case Fajr
    case Sunrise
    case Dhuhr
    case Asr
    case Sunset
    case Maghrib
    case Isha
    
    var getString: String {
        switch self {
        case Fajr: return "Fajr"
        case Sunrise: return "Sunrise"
        case Dhuhr: return "Dhuhr"
        case Asr: return "Asr"
        case Sunset: return "Sunset"
        case Maghrib: return "Maghrib"
        case Isha: return "Isha"
        }
    }
}

enum WakeOptions: String {
    case AtFajr = "At Fajr"
    case BeforeFajr = "Before Fajr"
    case BeforeSunrise = "Before Sunrise"
}

enum Days: String  {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
}

class FajrWake {
    var whenToAlarm: WakeOptions
    var minsToChange: Int
    var daysToRepeat: [Days]
    var snooze: Bool
    var alarmOn: Bool
    var alarmLabel: String
    var daysToRepeatLabel: String
    
    init(whenToAlarm: WakeOptions = .AtFajr, minsToChange: Int = 0, daysToRepeat: [Days] = [.Monday, .Tuesday, .Wednesday, .Thursday, .Friday, .Saturday, .Sunday], snooze: Bool = true, alarmOn: Bool = true, alarmLabelLabel: String = "Alarm") {
        self.whenToAlarm = whenToAlarm
        self.minsToChange = minsToChange
        self.daysToRepeat = daysToRepeat
        self.snooze = snooze
        self.alarmOn = alarmOn
        self.alarmLabel = alarmLabelLabel
        daysToRepeatLabel = DaysToRepeatLabel.getTextToRepeatDaysLabel(daysToRepeat)
    }
    func setAlarm() {
        
    }
}


/*
 Reference from PrayerTimes.swift
 CalculationMethods:
 case Jafari = 0  // Ithna Ashari
 case Karachi // University of Islamic Sciences, Karachi
 case Isna  // Islamic Society of North America (ISNA)
 case Mwl // Muslim World League (MWL)
 case Makkah // Umm al-Qura, Makkah
 case Egypt // Egyptian General Authority of Survey
 case Custom  // Custom Setting
 case Tehran  // Institute of Geophysics, University of Tehran

 AsrJuristicMethods:
 case Shafii // Shafii (standard)
 case Hanafi // Hanafi

AdjustingMethods:
    case None // No adjustment
    case MidNight  // middle of night
    case OneSeventh // 1/7th of night
    case AngleBased // floating point number

 TimeForamts:
 case Time24 // 24-hour format
 case Time12 // 12-hour format
 case Time12NS // 12-hour format with no suffix
 case Floating // angle/60th of night
 */

enum PrayerTimeSettingsReference: String {
    case CalculationMethod, AsrJuristic, AdjustHighLats, TimeFormat
}

func getCalculationMethodString(method: Int) -> String {
    switch method {
    case 0: return "Ithna Ashari"
    case 1: return "University of Islamic Sciences, Karachi"
    case 2: return "Islamic Society of North America (ISNA)"
    case 3: return "Muslim World League (MWL)"
    case 4: return "Umm al-Qura, Makkah"
    case 5: return "Egyptian General Authority of Survey"
    case 6: return "Custom Setting"
    case 7: return "Institute of Geophysics, University of Tehran"
    default: return ""
    }
}

struct UserSettingsPrayerOptions {
    static func getUserSettings() -> PrayerTimes {
        let settings = NSUserDefaults.standardUserDefaults()
        let calculationMethod: Int = settings.integerForKey(PrayerTimeSettingsReference.CalculationMethod.rawValue)
        let asrJuristic: Int = settings.integerForKey(PrayerTimeSettingsReference.AsrJuristic.rawValue)
        let adjustHighLats: Int = settings.integerForKey(PrayerTimeSettingsReference.AdjustHighLats.rawValue)
        let timeFormat: Int = settings.integerForKey(PrayerTimeSettingsReference.TimeFormat.rawValue)
        
        return PrayerTimes(caculationmethod: PrayerTimes.CalculationMethods(rawValue: calculationMethod)!, asrJuristic: PrayerTimes.AsrJuristicMethods(rawValue: asrJuristic)!, adjustHighLats: PrayerTimes.AdjustingMethods(rawValue: adjustHighLats)!, timeFormat: PrayerTimes.TimeForamts(rawValue: timeFormat)!)
    }
}







