//
//  PahtoWidgetManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/20/25.
//

import UIKit

// 1) DateFormatter 확장: 파일명용 (날짜+시간)
extension DateFormatter {
    /// "yyyy-MM-dd-HH-mm-ss" 포맷의 타임스탬프
    static let widgetFilenameFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
}

// 2) PhotoWidgetManager 수정
final class PhotoWidgetManager {
    static let shared = PhotoWidgetManager()
    let appGroupID = "group.com.indextrown.Haruhancut.WidgetExtension"

    /// 오늘 사진을 "yyyy-MM-dd-HH-mm-ss-<UUID>.jpg" 로 저장
    func saveTodayImage(_ image: UIImage, identifier: String) {
        let dateKey    = Date().toDateKey()  // "2025-06-10"
        let timestamp  = DateFormatter.widgetFilenameFormatter
                            .string(from: Date()) // "2025-06-10-14-23-08"
        let fileName   = "\(timestamp)-\(identifier).jpg"
        
        guard let data = image.jpegData(compressionQuality: 0.8),
              let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateKey, isDirectory: true)
        else {
            print("❌ 컨테이너 URL 생성 실패")
            return
        }
        
        // 디렉토리 생성
        do {
            try FileManager.default.createDirectory(at: containerURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("❌ 폴더 생성 실패:", error)
        }
        
        // 파일 저장
        let fileURL = containerURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            print("▶️ 오늘 사진 저장:", fileURL.lastPathComponent)
        } catch {
            print("❌ 사진 저장 실패:", error)
        }
    }
    
    /// dateKey 폴더 안에서 identifier(=postId)가 포함된 파일을 모두 삭제
    func deleteImage(dateKey: String, identifier: String) {
        let appGroupID = self.appGroupID
        guard let folder = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateKey, isDirectory: true)
        else { return }

        if let files = try? FileManager.default.contentsOfDirectory(at: folder,
                                                                    includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains(identifier) {
                do {
                    try FileManager.default.removeItem(at: file)
                    print("▶️ 위젯 컨테이너에서 삭제:", file.lastPathComponent)
                } catch {
                    print("❌ 위젯 컨테이너 삭제 실패:", error)
                }
            }
        }
    }
}
