//
//  Extensions.swift
//  physics-engine
//
//  Created by Fatih Balsoy on 11/24/22.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
