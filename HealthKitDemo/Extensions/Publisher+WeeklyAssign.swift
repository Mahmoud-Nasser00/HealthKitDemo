//
//  UILabel+Publisher.swift
//  HealthKitDemo
//
//  Created by Mahmoud Nasser on 07/04/2023.
//

import Foundation
import Combine

extension Publisher where Failure == Never {
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
       sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
