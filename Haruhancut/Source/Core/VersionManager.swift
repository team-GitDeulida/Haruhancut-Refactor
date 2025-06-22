//
//  VersionManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/20/25.
//

import UIKit

final class VersionManager {
    static let shared = VersionManager() // 싱글톤 인스턴스
    private init() {} // 외부에서 인스턴스 생성 방지
    
    /// 앱스토어의 최신 버전과 현재 버전을 비교하여 업데이트가 필요한지 판단
    /// - Parameters:
    ///   - bundleId: 앱의 번들 ID
    ///   - completion: 업데이트 필요 여부와 최신 버전 전달
    func checkForAppUpdates(bundleId: String, completion: @escaping (_ needsUpdate: Bool, _ currentVersion: String, _ latestVersion: String?) -> Void) {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        print("📱 현재 버전: \(currentVersion)")
        
        fetchLatestVersionFromAppStore(bundleId: bundleId) { latest in
            print("🛍️ 앱스토어 최신 버전: \(latest ?? "없음")")
            if let latest = latest, self.isUpdateRequired(currentVersion: currentVersion, latestVersion: latest) {
                completion(true, currentVersion, latest)
            } else {
                completion(false, currentVersion, latest)
            }
        }
    }

    
    /// 앱스토어에서 최신 버전 정보를 가져옴
    private func fetchLatestVersionFromAppStore(bundleId: String, completion: @escaping (String?) -> Void) {
        
        /*
        let fakeLatestVersion = "9.9.9"
        completion(fakeLatestVersion)
         */
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(bundleId)&country=KR") else {
            completion(nil)
            return
        }

        // 네트워크 요청 시작
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                // JSON 파싱 후, "results" 배열에서 첫 번째 결과의 "version" 추출
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let latestVersion = results.first?["version"] as? String {
                    completion(latestVersion)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    /// 현재 버전과 최신 버전을 비교하여 업데이트 필요 여부 반환
    private func isUpdateRequired(currentVersion: String, latestVersion: String) -> Bool {
        return currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
    }
}

