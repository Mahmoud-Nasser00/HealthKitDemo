//
//  ViewController.swift
//  HealthKitDemo
//
//  Created by Mahmoud Nasser on 06/04/2023.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet private weak var contentView: MainView!
    
    // MARK:- Props
    private let vm = HealthKitVM(hKManager: HealthKitManager())
    private var cancellables: [AnyCancellable] = []
    
    // MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView?.heightLabel.text = "102030"
        bind()
    }
}

extension ViewController {
    private func bind() {
        bindUI()
    }
    
    private func bindUI() {
        vm.height
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.contentView?.heightLabel.text = height
            }.store(in: &cancellables)
        
        vm.weight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weight in
                self?.contentView?.weightLabel.text = weight
            }.store(in: &cancellables)
        
        vm.stepCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stepsCount in
                self?.contentView?.stepCountLabel.text = stepsCount
            }.store(in: &cancellables)
        
        vm.lastHeartRateReading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.contentView?.heartRateLabel.text = heartRate
            }.store(in: &cancellables)
        
        vm.lastBPReading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bloodPressure in
                self?.contentView?.bloodPressureLabel.text = bloodPressure
            }.store(in: &cancellables)
    }
}

