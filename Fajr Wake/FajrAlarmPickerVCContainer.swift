//
//  FajrAlarmPickerVCContainer.swift
//  Fajr Wake
//
//  Created by Ali Mir on 6/26/16.
//  Copyright © 2016 Fajr Wake. All rights reserved.
//

import UIKit

class FajrAlarmPickerVCContainer: UIViewController {
    @IBOutlet weak var prayerTimesPicker: UIPickerView!
    
    var AddAlarmMasterVCReference: AddAlarmMasterViewController?
    
    var whenToAlarm: WakeOptions? {
        didSet {
            AddAlarmMasterVCReference?.whenToWake = whenToAlarm
        }
    }
    var salatToAlarm: SalatsAndQadhas? {
        didSet {
            AddAlarmMasterVCReference?.whatSalatToWake = salatToAlarm
        }
    }
    var minsToAdjustAlarm: Int? {
        didSet {
            AddAlarmMasterVCReference?.minsToAdjust = minsToAdjustAlarm
        }
    }
    
    let maxElements = 10000
    var locOfZero = (10000/2) - 20
    var pickerData: [[String]] = [[], ["On time", "Before", "After"], [SalatsAndQadhas.fajr.getString.capitalized, SalatsAndQadhas.sunrise.getString.capitalized]]
    let minsToAdjustComponent: Int = 0
    let whenToAlarmComponent: Int = 1
    let whatSalatToAlarmComponent: Int = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prayerTimesPicker.delegate = self
        self.prayerTimesPicker.dataSource = self
        
        if let minAdj = AddAlarmMasterVCReference!.minsToAdjust, let whenAlarm = AddAlarmMasterVCReference!.whenToWake, let salatAlarm = AddAlarmMasterVCReference!.whatSalatToWake {
            setupFajrAlarm(minsToAdjust: minAdj, whenToAlarm: whenAlarm.rawValue, whatSalatToAlarm: salatAlarm.rawValue)
        } else {
            print("oh dear... something went wrong in viewDidLoad() of FajrAlarmPickerVCContainer")
        }
        whenToAlarm = WakeOptions(rawValue: prayerTimesPicker.selectedRow(inComponent: whenToAlarmComponent))!
        salatToAlarm = SalatsAndQadhas(rawValue: prayerTimesPicker.selectedRow(inComponent: whatSalatToAlarmComponent))!
        minsToAdjustAlarm = Int(self.pickerView(prayerTimesPicker, titleForRow: prayerTimesPicker.selectedRow(inComponent: minsToAdjustComponent), forComponent: minsToAdjustComponent)!)!
        
        // "min" label ::: NEEDS FIX TO ADJUST DIFFERENT SCREENS
        let hourLabel = UILabel(frame: CGRect(x: 84, y: prayerTimesPicker.frame.size.height / 2 - 12, width: 75, height: 30))
        hourLabel.text = "min"
        hourLabel.font = UIFont.boldSystemFont(ofSize: 14)
        prayerTimesPicker.addSubview(hourLabel)
    }
}

// MARK: - UIPickerView
extension FajrAlarmPickerVCContainer: UIPickerViewDelegate, UIPickerViewDataSource {
    // setup alarm
    func setupFajrAlarm(minsToAdjust: Int = 10, whenToAlarm: Int = 1, whatSalatToAlarm: Int = 2) {
        // populate first components with minutes
        for index in 0...59 {
            pickerData[minsToAdjustComponent].append("\(index)")
        }
        prayerTimesPicker.selectRow(locOfZero+minsToAdjust, inComponent: minsToAdjustComponent, animated: true)
        prayerTimesPicker.selectRow(whenToAlarm, inComponent: whenToAlarmComponent, animated: true)
        prayerTimesPicker.selectRow(whatSalatToAlarm, inComponent: whatSalatToAlarmComponent, animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == minsToAdjustComponent {
            return maxElements // to create illusion of infinite scrolling for minutes
        } else {
            return pickerData[component].count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == minsToAdjustComponent {
            let myRow = row % pickerData[minsToAdjustComponent].count
            let numbers = pickerData[minsToAdjustComponent][myRow]
            return numbers
        } else {
            return pickerData[component][row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedWhenToAlarm = prayerTimesPicker.selectedRow(inComponent: whenToAlarmComponent)
        var selectedMinsToAdjust = Int(self.pickerView(prayerTimesPicker, titleForRow: prayerTimesPicker.selectedRow(inComponent: minsToAdjustComponent), forComponent: minsToAdjustComponent)!)!
        let selectedSalatAndQadha = prayerTimesPicker.selectedRow(inComponent: whatSalatToAlarmComponent)
        
        // Adjust the picker if user makes invalid selections
        if (selectedWhenToAlarm == 1 || selectedWhenToAlarm == 2){
            if selectedMinsToAdjust == 0 {
                prayerTimesPicker.selectRow(locOfZero+1, inComponent: minsToAdjustComponent, animated: true)
                selectedMinsToAdjust = 1
            }
        } else if (selectedWhenToAlarm == 0 && selectedMinsToAdjust != 0) {
            prayerTimesPicker.selectRow(locOfZero, inComponent: minsToAdjustComponent, animated: true)
            selectedMinsToAdjust = 0
        }
        
        whenToAlarm = WakeOptions(rawValue: selectedWhenToAlarm)!
        salatToAlarm = SalatsAndQadhas(rawValue: selectedSalatAndQadha)
        minsToAdjustAlarm = selectedMinsToAdjust
    }
}





