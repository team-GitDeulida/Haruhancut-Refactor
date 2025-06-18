//
//  ObservableType+.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import RxSwift

// true → false, false → true로 바꾸는 RxSwift용 map 헬퍼 함수
extension ObservableType where Element == Bool {
    func inverted() -> Observable<Bool> {
        return self.map { !$0 }
    }
}
