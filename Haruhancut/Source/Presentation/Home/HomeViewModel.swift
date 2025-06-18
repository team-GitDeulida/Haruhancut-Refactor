//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxCocoa

protocol HomeViewModelType {
    
}

final class HomeViewModel: HomeViewModelType {
    let group = BehaviorRelay<HCGroup?>(value: nil)
}

final class StubHomeViewModel: HomeViewModelType {
    
}
