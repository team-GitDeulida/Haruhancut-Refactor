//
//  Date+.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import Foundation

extension Date {
    // MARK: - instance 함수 -> 날짜 포맷팅할 때
    /// Date -> String 포매팅
    /// - Returns: String
    func toKoreanDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: self)
    }
    
    /// Date -> String 포매팅
    /// - Returns: String
    func toDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 그룹만들때 사용됨
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
}
