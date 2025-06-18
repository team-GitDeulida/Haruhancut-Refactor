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
    
    /// 상대적인 시간
    /// - Returns: "5분 전", "2시간 전", "3일 전"
    func toRelativeString() -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = Locale(identifier: "ko_KR")
        relativeFormatter.unitsStyle = .short // → "5분 전", "2시간 전", "3일 전"
        return relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - static 함수 -> 날짜를 만들 때
    /// 한국 시간 기준 특정 날짜 생성 (00:00:00)
    /// - Parameters:
    ///   - year: 연
    ///   - month: 월
    ///   - day: 일
    /// - Returns: Date
    static func toKoreanDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date()
    }
}
