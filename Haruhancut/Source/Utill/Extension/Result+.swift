//
//  Result.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import Foundation

public extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
