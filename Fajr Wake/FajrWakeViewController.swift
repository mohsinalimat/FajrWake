//
//  FajrWakeViewController.swift
//  Fajr Wake
//
//  Created by Abidi on 6/14/16.
//  Copyright © 2016 Fajr Wake. All rights reserved.
//


import UIKit
import CoreLocation
import AddressBookUI
import AVFoundation
import AudioToolbox
import MediaPlayer

class FajrWakeViewController: UITableViewController, CLLocationManagerDelegate {
    var manager: OneShotLocationManager?
    var prayerTimes: [String: String] = [:]
    var locationNameDisplay: String?
    var alarms = [AlarmClockType]()
    var noAlarmsLabel = UILabel()
    var alarmSoundPlayer: AVAudioPlayer!
    var alarmAlertController: UIAlertController?
    var timerToStall = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure local notifications
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        configureNotificationObservers()
        noAlarmsLabelConfig()
        setupPrayerTimes()
        loadAlarms()
        
        // hide "edit" button when no alarm
        if alarms.count > 0 {
            navigationItem.leftBarButtonItem = editButtonItem()
        } else {
            self.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.setEditing(false, animated: false)
    }
    
    func configureNotificationObservers() {
        // will terminate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.checkApplicationState), name: UIApplicationWillTerminateNotification, object: nil)
        // will resign active
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.checkApplicationState), name: UIApplicationWillResignActiveNotification, object: nil)
        // did become active
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.setupNotificationsReference), name: UIApplicationDidBecomeActiveNotification, object: nil)

    }
    
    func loadAlarms() {
        // load saved alarms
        if let savedAlarms = getSavedAlarms() {
            alarms += savedAlarms
        }
    }
    
    // Dirty solution: When phone is locked, local notification should not play sound...
    func checkApplicationState() {
        if UIApplication.sharedApplication().applicationState == .Active {
            if timerToStall.valid {
                timerToStall.invalidate()
            }
            timerToStall = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(self.setupNotificationsWithoutSound), userInfo: nil, repeats: false)
        }
    }
    
    func setupNotificationsWithoutSound() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        setupLocalNotifications(true)
    }
    
    func setupNotificationsReference() {
        if timerToStall.valid {
            timerToStall.invalidate()
        }
        setupLocalNotifications()
    }

    func setupLocalNotifications(noSound: Bool? = false) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        if self.alarms.count > 0 {
            for (index, _) in self.alarms.enumerate() {
                if self.alarms[index].alarmOn {
                    let alarmDate = self.alarms[index].savedAlarmDate!
                    if alarmDate.timeIntervalSinceNow >= 0  {
                        if noSound == true {
                            self.alarms[index].scheduleLocalNotification(noSound: true)
                        } else {
                            self.alarms[index].scheduleLocalNotification()
                        }
                    }
                }
            }
        }
    }
    
    func noAlarmsLabelConfig() {
        noAlarmsLabel = UILabel(frame: CGRectZero)
        noAlarmsLabel.text = "No Alarms"
        noAlarmsLabel.baselineAdjustment = .AlignBaselines
        noAlarmsLabel.backgroundColor = UIColor.clearColor()
        noAlarmsLabel.textColor = UIColor.lightGrayColor()
        noAlarmsLabel.textAlignment = .Center
        noAlarmsLabel.font = UIFont(name: "Helvetica", size: 25.0)
        noAlarmsLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view!.addSubview(noAlarmsLabel)
        let xConstraint = NSLayoutConstraint(item: noAlarmsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self.tableView, attribute: .CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: noAlarmsLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.tableView, attribute: .CenterY, multiplier: 1, constant: -30.0)
        NSLayoutConstraint.activateConstraints([xConstraint, yConstraint])
    }
    
    func displaySettingsTableView() {
        if alarms.count == 0 {
            self.tableView.scrollEnabled = false
            self.noAlarmsLabel.hidden = false
        } else {
            self.tableView.scrollEnabled = true
            self.noAlarmsLabel.hidden = true
        }
    }
}

// MARK: - TableView
extension FajrWakeViewController {
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // hide "edit" button when no alarm
        if alarms.count > 0 {
            navigationItem.leftBarButtonItem = editButtonItem()
        } else {
            self.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
        
        return alarms.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.displaySettingsTableView()
        
        let settings = NSUserDefaults.standardUserDefaults()
        let calcMethodRawValue = settings.integerForKey(PrayerTimeSettingsReference.CalculationMethod.rawValue)
        let calculationMethod = CalculationMethods(rawValue: calcMethodRawValue)!.getString()
        
        var toDisplay = ""
        if let locName = locationNameDisplay {
            toDisplay = "\(locName)\n\(calculationMethod)"
        }

        return toDisplay
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let fajr = prayerTimes[SalatsAndQadhas.Fajr.getString]
        let sunrise = prayerTimes[SalatsAndQadhas.Sunrise.getString]
        let tomorrowPrayerTimes = getPrayerTimes(NSDate().dateByAddingTimeInterval(60*60*24))
        let fajrTomorrow = tomorrowPrayerTimes[SalatsAndQadhas.Fajr.getString]!
        let sunriseTomorrow = tomorrowPrayerTimes[SalatsAndQadhas.Sunrise.getString]!
        var toDisplay = ""
        
        if let fajrTime = fajr, let sunriseTime = sunrise {
            toDisplay = "Today: Fajr: \(fajrTime), Sunrise: \(sunriseTime)\nTomorrow: Fajr: \(fajrTomorrow), Sunrise: \(sunriseTomorrow)"
        }
        
        return toDisplay
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textAlignment = .Center
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .Center
            headerView.textLabel?.text = headerView.textLabel?.text!.capitalizedString
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "FajrWakeCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! FajrWakeCell
        var alarm = alarms[indexPath.row]
        
        cell.alarmLabel.attributedText = alarm.attributedTitle
        cell.alarmLabel.textColor = UIColor.blackColor()
        cell.editingAccessoryType = .DisclosureIndicator

        if alarm.alarmOn == true {
            cell.backgroundColor = UIColor.whiteColor()
        } else {
            cell.backgroundColor = UIColor.groupTableViewBackgroundColor()
            cell.alarmLabel.textColor = UIColor.grayColor()
        }
        
        let alarmSwitch = UISwitch(frame: CGRectZero)
        alarmSwitch.onTintColor = UIColor(red: 0.9294, green: 0.298, blue: 0.2588, alpha: 1.0) /* #ed4c42 */
        alarmSwitch.on = alarm.alarmOn
        cell.accessoryView = alarmSwitch
        alarmSwitch.addTarget(self, action: #selector(self.switchChanged), forControlEvents: .ValueChanged)

        return cell
    }
    
    func setupAlarmsAndUpdate(indexPath: NSIndexPath) {
        var alarm = alarms[indexPath.row]
        if alarm.alarmOn == true {
            if let url = alarm.sound.alarmSound.URL {
                alarm.startAlarm(self, selector: #selector(self.alarmAction), date: alarm.timeToAlarm(nil), userInfo: [indexPath : url])
            } else {
                alarm.startAlarm(self, selector: #selector(self.alarmAction), date: alarm.timeToAlarm(nil), userInfo: indexPath)
            }
            // schedule local notifications
            setupLocalNotifications()
        } else {
            alarm.stopAlarm()
            alarm.deleteLocalNotifications()
        }
        saveAlarms()
    }
    
    // Target-Action for AlarmClock switch (on/off)
    func switchChanged(switchControl: UISwitch) {
        let switchOriginInTableView = switchControl.convertPoint(CGPointZero, toView: tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(switchOriginInTableView) {
            alarms[indexPath.row].alarmOn = switchControl.on
            setupAlarmsAndUpdate(indexPath)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            print("ERROR: Cell doesn't exist!")
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // remove NSTimer and delete the row from the data source
            alarms[indexPath.row].stopAlarm()
            alarms[indexPath.row].deleteLocalNotifications()
            alarms.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
            saveAlarms()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView.editing == true {
            tableView.allowsSelectionDuringEditing = true
        } else {
            self.tableView.allowsSelection = false
        }
        return true
    }
}

// MARK: - Navigation
extension FajrWakeViewController {
    @IBAction func unwindToAlarms(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? AddAlarmMasterViewController, let alarm = sourceViewController.alarmClock {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // edit alarm
                // turn off the previous alarm and replace alarm clock with edited alarm
                alarms[selectedIndexPath.row].stopAlarm()
                alarms[selectedIndexPath.row].deleteLocalNotifications()
                alarms[selectedIndexPath.row] = alarm
                setupAlarmsAndUpdate(selectedIndexPath)
            } else {
                // add new alarm
                let newIndexPath = NSIndexPath(forRow: alarms.count, inSection: 0)
                alarms.append(alarm)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
                setupAlarmsAndUpdate(newIndexPath)
            }
        }
        sortAlarms()
        self.tableView.reloadData()
    }
    
    ///////////////////////////////Firing Alarm////////////////////////////////////////////////////
    func alarmAction(timer: NSTimer) {
        var url: NSURL?
        var indexPath: NSIndexPath?
        var vibrationTimer = NSTimer()
        
        if let userInfo = timer.userInfo as? [NSIndexPath : NSURL] {
            indexPath = userInfo.first!.0
            url = userInfo.first!.1
        } else if let userInfo = timer.userInfo as? NSIndexPath {
            indexPath = userInfo
        }

        if url != nil {
            playSound(url!)
            // vibrate every 2 seconds
            self.vibrate()
            vibrationTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(self.vibrate), userInfo: nil, repeats: true)
        }
        
        ///// Alarm Alert View
        alarmAlertController = UIAlertController(title: "\(alarms[indexPath!.row].alarmLabel)", message: nil, preferredStyle: .Alert)
        if alarms[indexPath!.row].snooze == true {
            // Snooze Button
            alarmAlertController!.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.Default) {
                action -> Void in
                
                // stop alarm sound
                if self.alarmSoundPlayer != nil {
                    self.alarmSoundPlayer.stop()
                    self.alarmSoundPlayer = nil
                }
                
                // stop vibration
                if vibrationTimer.valid {
                    vibrationTimer.invalidate()
                }
                // snooze for 8 mins
                let snoozeTime = NSDate().dateByAddingTimeInterval(60 * 8)
                if url != nil {
                    self.alarms[indexPath!.row].startAlarm(self, selector: #selector(self.alarmAction), date: snoozeTime, userInfo: [indexPath! : url!])
                } else {
                    self.alarms[indexPath!.row].startAlarm(self, selector: #selector(self.alarmAction), date: snoozeTime, userInfo: indexPath!)
                }
                self.alarms[indexPath!.row].savedAlarmDate = snoozeTime
                self.setupAlarmsAndUpdate(indexPath!)
                })
        }
        // Stop Button
        alarmAlertController!.addAction(UIAlertAction(title: "Stop", style: .Default) {
            action -> Void in
            // stop alarm sound
            if self.alarmSoundPlayer != nil {
                self.alarmSoundPlayer.stop()
                self.alarmSoundPlayer = nil
            }
            
            // stop vibration
            if vibrationTimer.valid {
                vibrationTimer.invalidate()
            }
            
            self.setupAlarmsAndUpdate(indexPath!)
            })
        
        alarmAlertController!.show()
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func playSound(url: NSURL) {
        do {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) // play audio even in silent mode
            } catch {
                print("could not play in silent mode")
            }
            alarmSoundPlayer = try AVAudioPlayer(contentsOfURL: url)
            alarmSoundPlayer.play()
            alarmSoundPlayer.numberOfLoops = -1 // "infinite" loop
            // adjust volume to highest
            (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(1.0, animated: false)
        } catch {
            print("could not play sound")
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    
    @IBAction func unwindToAlarmsDelete(sender: UIStoryboardSegue) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // remove alarms and delete cell
            alarms[selectedIndexPath.row].stopAlarm()
            alarms[selectedIndexPath.row].deleteLocalNotifications()
            alarms.removeAtIndex(selectedIndexPath.row)
            tableView.deleteRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            saveAlarms()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let addAlarmMasterVC = (segue.destinationViewController as! UINavigationController).topViewController as! AddAlarmMasterViewController
            if let selectedAlarmCell = sender as? FajrWakeCell {
                let indexPath = tableView.indexPathForCell(selectedAlarmCell)!
                let selectedAlarm = alarms[indexPath.row]
                
                addAlarmMasterVC.navigationItem.title = "Edit Alarm"
                addAlarmMasterVC.alarmClock = selectedAlarm
            }
        } else if segue.identifier == "addItem" {
            // new alarm
        } else if segue.identifier == "settingsSegue" {
            let settingsVC = segue.destinationViewController as! SettingsViewController
            settingsVC.fajrWakeVCReference = self
        }
    }
}

// MARK: - Setups and Settings
extension FajrWakeViewController {
    // calls appropriate methods to perform specific tasks in order to populate prayertime dictionary
    func setupPrayerTimes() {
        if NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore") == true {
            if let displayAddress = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String {
                self.locationNameDisplay = displayAddress
            } else {
                self.locationNameDisplay = "Could not get your city name"
            }
            updatePrayerTimes(NSDate())
        } else {
            startLocationDelegation()
            // once the app launched for first time, set "launchedBefore" to true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
        }
    }
    
    // location settings for prayer time
    func locationSettingsForPrayerTimes (lat lat: Double, lon: Double, gmt: Double) {
        let settings = NSUserDefaults.standardUserDefaults()
        settings.setDouble(lat, forKey: "latitude")
        settings.setDouble(lon, forKey: "longitude")
        settings.setDouble(gmt, forKey: "gmt")
    }
    
    // update prayer time dictionary
    func updatePrayerTimes(date: NSDate) {
        dispatch_async(dispatch_get_main_queue()) {
            self.prayerTimes = self.getPrayerTimes(date)
            for i in 0 ..< self.alarms.count {
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                self.alarms[indexPath.row].stopAlarm()
                self.alarms[indexPath.row].deleteLocalNotifications()
                self.setupAlarmsAndUpdate(indexPath)
            }
            self.sortAlarms()
            self.tableView.reloadData()
        }
    }
    
    // Helper method to get prayer times
    func getPrayerTimes(date: NSDate) -> [String: String] {
        let settings = NSUserDefaults.standardUserDefaults()
        let lon = settings.doubleForKey("longitude")
        let lat = settings.doubleForKey("latitude")
        let gmt = settings.doubleForKey("gmt")
        let userPrayerTime = UserSettingsPrayertimes()
        
        return userPrayerTime.getUserSettings().getPrayerTimes(NSCalendar.currentCalendar(), date: date, latitude: lat, longitude: lon, tZone: gmt)
    }
    
    // Sort alarms based on alarm times
    func sortAlarms() {
        alarms.sortInPlace({ $0.timeToAlarm(nil).timeIntervalSinceNow < $1.timeToAlarm(nil).timeIntervalSinceNow })
    }
}

// MARK: - Get location
// Get coordinates and call functinos to get prayer times
extension FajrWakeViewController {
    func startLocationDelegation() {
        // Activity Indicator
        EZLoadingActivity.show("Getting your location...", disableUI: true)
        
        manager = OneShotLocationManager()
        manager!.fetchWithCompletion {location, error in
            
            // fetch location or an error
            if let loc = location {
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                let gmt = LocalGMT.getLocalGMT()
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
                // stop showing activity indicator (success)
                EZLoadingActivity.hide(success: true, animated: true)
            } else if let err = error {
                print(err.localizedDescription)
                // setting defaults to San Jose, CA, USA's time if error in getting user location
                let lat = 37.279518
                let lon = -121.867905
                let gmt = -7.0
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
                
                if err.code == 0 {
                    let alertController = UIAlertController(
                        title: "Location Access Disabled",
                        message: "In order to setup your alarm, the app needs access to your location so that your local prayer times are determined. The app will use San Jose, CA, USA's prayer timing if you disable location access.",
                        preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                    alertController.addAction(openAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    let alertController = UIAlertController(title: "Could not get your location!", message: "Prayer times are now based on San Jose, CA, USA.", preferredStyle: .Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(OKAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                // stop showing activity indicator (not successful)
                EZLoadingActivity.hide(success: false, animated: true)
            }
            self.manager = nil
        }
    }
    
    func setupLocationForPrayerTimes(lat: Double, lon: Double, gmt: Double) {
        // location settings for prayer times
        self.locationSettingsForPrayerTimes(lat: lat, lon: lon, gmt: gmt)
        // call "reverseGeocoding" to get city, state, and country of the given coordinates
        //   then update prayer times
        self.reverseGeocoding(lat, longitude: lon)
        self.updatePrayerTimes(NSDate())
    }
}

// MARK: - Geocoding
// to get coordinates and names of cities, states, and countries
extension FajrWakeViewController {
    // reverse geocoding to get address of user location for display
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print(error)
                NSUserDefaults.standardUserDefaults().setObject("Network Error", forKey: "userAddressForDisplay")
                self.locationNameDisplay = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String
                self.tableView.reloadData()
                return
            }
            else if placemarks?.count > 0 {
                self.setLocationAddress(placemarks!)
            }
        })
    }
    
    // sets locationNameDisplay variable appropriately
    func setLocationAddress(placemarks: [CLPlacemark]) {
        let pm = placemarks[0]
        var saveAddress = ""
        if let address = pm.addressDictionary as? [String: AnyObject] {
            if let city = address["City"], let state = address["State"], let country = address["Country"] {
                saveAddress = "\(String(city)), \(String(state)), \(String(country))"
            } else if let state = address["State"], let country = address["Country"] {
                saveAddress = "\(String(state)), \(String(country))"
            } else {
                if let country = address["Country"] {
                    saveAddress = "\(String(country))"
                }
            }
        } else {
            saveAddress = "Can't Find Your City Name"
        }
        NSUserDefaults.standardUserDefaults().setObject(saveAddress, forKey: "userAddressForDisplay")
        self.locationNameDisplay = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String
        self.tableView.reloadData()
    }
}


// MARK: - Persisting Data (NSCoding and loading alarms)
extension FajrWakeViewController {
    func saveAlarms() {
        var fajrAlarmIsSuccessfulSave = false
        var customAlarmIsSuccessfulSave = false
        
        var fajrAlarms: [FajrWakeAlarm] = []
        var customAlarms: [CustomAlarm] = []
        
        for alarm in self.alarms {
            if alarm.alarmType == AlarmType.FajrWakeAlarm {
                fajrAlarms.append(alarm as! FajrWakeAlarm)
            } else if alarm.alarmType == AlarmType.CustomAlarm {
                customAlarms.append(alarm as! CustomAlarm)
            }
        }
        
        // Save FajrWakeAlarm's
        fajrAlarmIsSuccessfulSave = NSKeyedArchiver.archiveRootObject(fajrAlarms, toFile: FajrWakeAlarm.ArchiveURL.path!)
        if !fajrAlarmIsSuccessfulSave {
            print("unable to save FajrWake alarms")
        }
        
        // Save CustomAlarm's
        customAlarmIsSuccessfulSave = NSKeyedArchiver.archiveRootObject(customAlarms, toFile: CustomAlarm.ArchiveURL.path!)
        if !customAlarmIsSuccessfulSave {
            print("unable to save CustomAlarms alarms")
        }
    }
    
    func getSavedAlarms() -> [AlarmClockType]? {
        let savedFajrAlarms = NSKeyedUnarchiver.unarchiveObjectWithFile(FajrWakeAlarm.ArchiveURL.path!) as? [FajrWakeAlarm]
        let savedCustomAlarms = NSKeyedUnarchiver.unarchiveObjectWithFile(CustomAlarm.ArchiveURL.path!) as? [CustomAlarm]
        var savedAlarms: [AlarmClockType] = []
        
        if let customAlarms = savedCustomAlarms {
            for alarm in customAlarms {
                savedAlarms.append(alarm)
            }
        }
        
        if let fajrAlarms = savedFajrAlarms {
            for alarm in fajrAlarms {
                savedAlarms.append(alarm)
            }
        }

        if savedAlarms.count > 0 {
            savedAlarms.sortInPlace({$0.timeToAlarm(nil).timeIntervalSinceNow < $1.timeToAlarm(nil).timeIntervalSinceNow})
            return savedAlarms
        } else {
            return nil
        }
    }
}

extension UIAlertController {
    func show() {
        present(true, completion: nil)
    }
    
    func present(animated: Bool, completion: (() -> Void)?) {
        if let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController {
            presentFromController(rootVC, animated: animated, completion: completion)
        }
    }
    
    private func presentFromController(controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if  let navVC = controller as? UINavigationController,
            let visibleVC = navVC.visibleViewController {
            presentFromController(visibleVC, animated: animated, completion: completion)
        } else {
            if  let tabVC = controller as? UITabBarController,
                let selectedVC = tabVC.selectedViewController {
                presentFromController(selectedVC, animated: animated, completion: completion)
            } else {
                controller.presentViewController(self, animated: animated, completion: completion)
            }
        }
    }
}