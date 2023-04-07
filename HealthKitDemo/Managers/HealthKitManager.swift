//
//  HealthKitManager.swift
//  HealthKitDemo
//
//  Created by Mahmoud Nasser on 06/04/2023.
//

import Foundation
import HealthKit

class HealthKitManager {

    let healthStore = HKHealthStore()
    
    private let heartRateUnit: HKUnit = HKUnit(from: "count/min")
    private let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    private var heartRateQuery: HKSampleQuery?
    
    private let oxygenSaturationType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!
    private var oxygenSaturationQuery: HKSampleQuery?
    
    private let systolicBloodPressure: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private let diastolicBloodPressure: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    private var systolicBloodPressureQuery: HKSampleQuery?
    private var diastolicBloodPressureQuery: HKSampleQuery?
    
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        // Request authorization to access health data
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            completion(success, error)
        }
    }
    
    func getHeight(completion: @escaping (Double?, Error?) -> Void) {
        let heightType = HKObjectType.quantityType(forIdentifier: .height)!
        
        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, results, error) in
            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil, error)
                return
            }
            
            let heightInMeters = sample.quantity.doubleValue(for: .meter())
            completion(heightInMeters, nil)
        }
        
        healthStore.execute(query)
    }
    
    func getWeight(completion: @escaping (Double?, Error?) -> Void) {
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, results, error) in
            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil, error)
                return
            }
            
            let weightInKilograms = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            completion(weightInKilograms, nil)
        }
        
        healthStore.execute(query)
    }
    
    func getStepCount(completion: @escaping (Int?, Error?) -> Void) {
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, statistics, error) in
            guard let statistics = statistics else {
                completion(nil, error)
                return
            }
            
            let stepCount = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            completion(stepCount, nil)
        }
        
        healthStore.execute(query)
    }
    
    func getTodayBloodOxygen(onSuccess: @escaping (([(value: Double, date: Date)]) -> Void), onFailure: @escaping ((Error) -> Void)) {
        //predicate
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)

        guard let startDate: NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent = DateComponents()
        dayComponent.day = 1

        let endDate: NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])

        //descriptor
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]
        
        oxygenSaturationQuery = HKSampleQuery(sampleType: oxygenSaturationType, predicate: predicate, limit: 10, sortDescriptors: sortDescriptors, resultsHandler: { (query, samples, error) in
            guard error == nil else {
                print("error")
                onFailure(error!)
                return
            }
            self.printOxygenSaturationPercentage(results: samples)
            let readings:[(Double, Date)]  = samples?.enumerated().map({ sample in
                let quantitySample = sample.element as! HKQuantitySample
                return (quantitySample.quantity.doubleValue(for: .percent()), quantitySample.endDate)
            }) ?? []
            
            onSuccess(readings)
        })

        healthStore.execute(oxygenSaturationQuery!)
    }
    
    func getTodaysHeartRates(onSuccess: @escaping (([(value: Double, date: Date)]) -> Void), onFailure: @escaping ((Error) -> Void)) {
        //predicate
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)

        guard let startDate: NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent = DateComponents()
        dayComponent.day = 1

        let endDate: NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])

        //descriptor
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]

        heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 10, sortDescriptors: sortDescriptors, resultsHandler: { (query, samples, error) in
            guard error == nil else {
                print("error")
                onFailure(error!)
                return
            }
            self.printHeartRateInfo(results: samples)
            let readings:[(Double, Date)]  = samples?.enumerated().map({ sample in
                let quantitySample = sample.element as! HKQuantitySample
                return (quantitySample.quantity.doubleValue(for: self.heartRateUnit), quantitySample.endDate)
            }) ?? []
            
            onSuccess(readings)
        })

        healthStore.execute(heartRateQuery!)
    }
    
    private func printHeartRateInfo(results:[HKSample]?) {
        for (_, sample) in results!.enumerated() {
            guard let currData: HKQuantitySample = sample as? HKQuantitySample else { return }
            print("[\(sample)]")
            print("Heart Rate: \(currData.quantity.doubleValue(for: heartRateUnit))")
            print("quantityType: \(currData.quantityType)")
            print("Start Date: \(currData.startDate)")
            print("End Date: \(currData.endDate)")
            print("Device: \(String(describing: currData.device))")
            print("---------------------------------\n")
        }
    }
    
    private func printOxygenSaturationPercentage(results: [HKSample]?) {
        for (_, sample) in results!.enumerated() {
            guard let currData: HKQuantitySample = sample as? HKQuantitySample else { return }
            print("[\(sample)]")
            print("oxygen Rate: \(currData.quantity.doubleValue(for: .percent()))")
            print("quantityType: \(currData.quantityType)")
            print("Start Date: \(currData.startDate)")
            print("End Date: \(currData.endDate)")
            print("Device: \(String(describing: currData.device))")
            print("---------------------------------\n")
        }
    }
    
    func getTodaySystolicBoldPressure(onSuccess: @escaping (([(value: Double, date: Date)]) -> Void), onFailure: @escaping ((Error) -> Void)) {
        //predicate
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)

        guard let startDate: NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent = DateComponents()
        dayComponent.day = 1

        let endDate: NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])
        
        //descriptor
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]
        
        systolicBloodPressureQuery = HKSampleQuery(sampleType: systolicBloodPressure, predicate: predicate, limit: 10, sortDescriptors: sortDescriptors, resultsHandler: { [weak self] query, samples, error in
            guard error == nil else {
                print("error")
                onFailure(error!)
                return
            }
            self?.printSysBloodPressureInfo(results: samples)
            let readings:[(Double, Date)]  = samples?.enumerated().map({ sample in
                let quantitySample = sample.element as! HKQuantitySample
                return (quantitySample.quantity.doubleValue(for: .millimeterOfMercury()), quantitySample.endDate)
            }) ?? []
            
            onSuccess(readings)
        })
        
        healthStore.execute(systolicBloodPressureQuery!)
    }
    
    func getTodayDiastolicBoldPressure(onSuccess: @escaping (([(value: Double, date: Date)]) -> Void), onFailure: @escaping ((Error) -> Void))  {
        //predicate
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)

        guard let startDate: NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent = DateComponents()
        dayComponent.day = 1

        let endDate: NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])
        
        //descriptor
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]
        
        diastolicBloodPressureQuery = HKSampleQuery(sampleType: diastolicBloodPressure, predicate: predicate, limit: 10, sortDescriptors: sortDescriptors, resultsHandler: { [weak self] query, samples, error in
            guard error == nil else {
                print("error")
                onFailure(error!)
                return
            }
            self?.printDiaBloodPressureInfo(results: samples)
            let readings:[(Double, Date)]  = samples?.enumerated().map({ sample in
                let quantitySample = sample.element as! HKQuantitySample
                return (quantitySample.quantity.doubleValue(for: .millimeterOfMercury()), quantitySample.endDate)
            }) ?? []
            
            onSuccess(readings)
        })
        
        healthStore.execute(diastolicBloodPressureQuery!)
        
    }
    
    private func printSysBloodPressureInfo(results: [HKSample]?) {
        for (_, sample) in results!.enumerated() {
            guard let currData:HKQuantitySample = sample as? HKQuantitySample else { return }

            print("[\(sample)]")
            print("SysBloodPres: \(currData.quantity.doubleValue(for: .millimeterOfMercury()))")
            print("quantityType: \(currData.quantityType)")
            print("Start Date: \(currData.startDate)")
            print("End Date: \(currData.endDate)")
            print("Device: \(String(describing: currData.device))")
            print("---------------------------------\n")
            
        }
    }
    
    private func printDiaBloodPressureInfo(results: [HKSample]?) {
        for (_, sample) in results!.enumerated() {
            guard let currData:HKQuantitySample = sample as? HKQuantitySample else { return }

            print("[\(sample)]")
            print("DiaBloodPres: \(currData.quantity.doubleValue(for: .millimeterOfMercury()))")
            print("quantityType: \(currData.quantityType)")
            print("Start Date: \(currData.startDate)")
            print("End Date: \(currData.endDate)")
            print("Device: \(String(describing: currData.device))")
            print("---------------------------------\n")
        }
    }
    
    
}


