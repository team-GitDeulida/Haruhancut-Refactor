//
//  Cell+.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

protocol ReuseIdentifiable {
    // 프로토콜에서 로직을 정의할 수 없어서 가져올 수 있도록 설정
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
    // 로직에 대한 정의는 Extension에서 간능
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension UITableViewCell: ReuseIdentifiable {}
extension UICollectionViewCell: ReuseIdentifiable {}
