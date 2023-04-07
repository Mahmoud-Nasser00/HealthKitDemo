//
//  HealthKitVM.swift
//  HealthKitDemo
//
//  Created by Mahmoud Nasser on 07/04/2023.
//

import Foundation
import HealthKit

class HealthKitVM {
    
    @Published private var isLoadingVal: Bool = false
    var isLoading: Published<Bool>.Publisher { $isLoadingVal }

    @Published private var errorMessageVal: String?
    var errorMessage: Published<String?>.Publisher { $errorMessageVal }
    
    @Published private var heightVal: String?
    var height: Published<String?>.Publisher { $heightVal }
    
    @Published private var weightVal: String?
    var weight: Published<String?>.Publisher { $weightVal }
    
    @Published private var stepCountVal: String?
    var stepCount: Published<String?>.Publisher { $stepCountVal }
    
    @Published private var lastHeartRateReadingVal: String?
    var lastHeartRateReading: Published<String?>.Publisher { $lastHeartRateReadingVal }
    
    @Published private var lastBloodPressureReadingVal: String?
    var lastBPReading: Published<String?>.Publisher { $lastBloodPressureReadingVal }
    
    private var healthKitManager: HealthKitManager!
    
    init(hKManager: HealthKitManager) {
        healthKitManager = hKManager
        getHealthKitdata()
    }
    
    func getHealthKitdata() {
        isLoadingVal = true
        healthKitManager.authorizeHealthKit { [weak self] (success, error) in
            guard let self = self else { return }
            isLoadingVal = false
            if success {
                self.getHeight()
                self.getWeight()
                self.getStepCount()
                self.getHeartRate()
                self.getBloodPressure()
            }
            
            if error != nil {
                errorMessageVal = error!.localizedDescription
            }
        }
    }
}

extension HealthKitVM {
    private func getHeight() {
        healthKitManager.getHeight { [weak self] (height, error) in
            guard let self = self else { return }
            if let height = height {
                print("Height: \(height) meters")
                self.heightVal = "\(String(height.rounded())) meters"
            } else if let error = error {
                errorMessageVal = error.localizedDescription
            }
        }
    }
    
    private func getWeight() {
        self.healthKitManager.getWeight { [weak self] (weight, error) in
            guard let self = self else { return }
            if let weight = weight {
                print("weight: \(weight) kiloGrams")
                self.weightVal = "\(String(weight.rounded())) kiloGrams"
            } else if let error = error {
                self.errorMessageVal = error.localizedDescription
            }
        }
    }
    
    private func getStepCount() {
        healthKitManager.getStepCount{ [weak self] (stepCount, error) in
            guard let self = self else { return }
            if let stepCount = stepCount {
                print("stepCount: \(stepCount) steps")
                self.stepCountVal = "\(String(stepCount)) steps"
            } else if let error = error {
                self.errorMessageVal = error.localizedDescription
            }
        }
    }
    
    private func getHeartRate() {
        healthKitManager.getTodaysHeartRates { [weak self] values in
            guard let self = self else { return }
            if values.isEmpty {
                self.lastHeartRateReadingVal = "No Readings"
            } else {
                self.lastHeartRateReadingVal = "\(String(values.first!.value))"
            }
        } onFailure: { error in
            self.errorMessageVal = error.localizedDescription
        }
    }
    
    private func getBloodPressure() {
        healthKitManager.getTodayDiastolicBoldPressure { [weak self]  diastolicvValues in
            guard let self = self else { return }
            healthKitManager.getTodaySystolicBoldPressure { systolicValues in
                if systolicValues.isEmpty || diastolicvValues.isEmpty {
                    self.lastBloodPressureReadingVal = "No Readings"
                } else {
                    self.lastBloodPressureReadingVal = "\(String(systolicValues.first!.value))/\(String(diastolicvValues.first!.value))"
                }
            } onFailure: { error in
                self.errorMessageVal = error.localizedDescription
            }

        } onFailure: { error in
            self.errorMessageVal = error.localizedDescription
        }

    }
}
