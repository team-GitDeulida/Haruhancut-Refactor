//
//  User.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import Foundation

// MARK: - Model
struct User: Encodable { /// Swift객체 -> Json(서버로 보낼때)
    var uid: String
    let registerDate: Date
    let loginPlatform: LoginPlatform
    var nickname: String
    var profileImageURL: String?
    var fcmToken: String?
    var birthdayDate: Date
    var gender: Gender
    var isPushEnabled: Bool
    var groupId: String?
    
    // 성별
    enum Gender: String, Codable {
        case male = "남자"
        case female = "여자"
        case other = "비공개"
    }

    // 로그인 플랫폼
    enum LoginPlatform: String, Codable {
        case kakao = "kakao"
        case apple = "apple"
    }
}

// MARK: - toDTO
extension User {
    func toDTO() -> UserDTO {
        
        let formatter = ISO8601DateFormatter()
        return UserDTO(
            uid: uid,
            registerDate: formatter.string(from: registerDate),
            loginPlatform: loginPlatform.rawValue,
            nickname: nickname,
            profileImageURL: profileImageURL,
            fcmToken: fcmToken,
            birthdayDate: formatter.string(from: birthdayDate),
            gender: gender.rawValue,
            isPushEnabled: isPushEnabled,
            groupId: groupId)
    }
}

// MARK: - UserDefaults전용 User < - > Data 인코딩/디코딩
extension User {
    
    /// User 객체 → JSON 데이터 (Data)로 직렬화 (저장용)
    func toData() -> Data? {
        do {
            let data = try JSONEncoder().encode(self)
            return data
        } catch {
            print("❌ User toData() 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// JSON Data → UserDTO → User 객체로 역직렬화 (복원용)
    static func from(data: Data) -> User? {
        do {
            let dto = try JSONDecoder().decode(UserDTO.self, from: data)
            return dto.toModel()
        } catch {
            print("❌ User from(data:) 실패: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Empty Object 패턴 생성자
extension User {
    static func empty(loginPlatform: LoginPlatform) -> User {
        return User(
            uid: "stub-uid",
            registerDate: Date(),                 // 현재 시간
            loginPlatform: loginPlatform,
            nickname: "stub-nickname",                     // 아직 입력 안 됨
            profileImageURL: nil,
            birthdayDate: Date.distantPast,       // 의미 없는 과거 값
            gender: .other,                       // 기본값 (비공개)
            isPushEnabled: true,                  // 기본값
            groupId: nil
        )
    }
}

// MARK: ---------------------------------------------------------------------------
struct HCGroup: Encodable {
    let groupId: String
    let groupName: String
    let createdAt: Date
    let hostUserId: String
    let inviteCode: String
    var members: [String: String] // [uid: joinedAt]
    var postsByDate: [String: [Post]]
}

extension HCGroup {
    func toDTO() -> HCGroupDTO {
        let formatter = ISO8601DateFormatter()
        let postsDTO: [String: [String: PostDTO]] = postsByDate.mapValues { postList in
            Dictionary(uniqueKeysWithValues: postList.map { ($0.postId, $0.toDTO()) })
        }
        
        return HCGroupDTO(
            groupId: groupId,
            groupName: groupName,
            createdAt: formatter.string(from: createdAt),
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            postsByDate: postsDTO
        )
    }
}


// MARK: ---------------------------------------------------------------------------
struct Post: Encodable {
    let postId: String
    let userId: String           // 작성자 ID
    let nickname: String         // 작성자 닉네임
    let profileImageURL: String? // 작성자 프로필 사진
    let imageURL: String
    let createdAt: Date
    let likeCount: Int
    var comments: [String: Comment]
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
}

extension Post {
    func toDTO() -> PostDTO {
        let formatter = ISO8601DateFormatter()
        let commentDTOs = Dictionary(uniqueKeysWithValues: comments.map { key, comment in
                    (key, comment.toDTO())
                })
        
        return PostDTO(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: formatter.string(from: createdAt),
            likeCount: likeCount,
            comments: commentDTOs
        )
    }
}

extension Array where Element == Post {
    /*
     [
       "2025.06.17": [Post1, Post2],
       "2025.06.16": [Post3]
     ]
     */
    func groupedByDate() -> [String: [Post]] {
        return Dictionary(grouping: self) { post in
            post.createdAt.toDateKey()
        }
    }
}


// MARK: ---------------------------------------------------------------------------
struct Comment: Encodable {
    let commentId: String
    let userId: String
    let nickname: String
    var profileImageURL: String?
    let text: String
    let createdAt: Date
}

extension Comment {
    func toDTO() -> CommentDTO {
        let formatter = ISO8601DateFormatter()
        return CommentDTO(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: formatter.string(from: createdAt))
    }
}





// MARK: ---------------------------------------------------------------------------

// MARK: - DTO
struct UserDTO: Codable { /// Json -> Swift 객체(서버 응답용)
    let uid: String?
    let registerDate: String?
    let loginPlatform: String?
    let nickname: String?
    let profileImageURL: String?
    let fcmToken: String?
    let birthdayDate: String?
    let gender: String?
    let isPushEnabled: Bool?
    let groupId: String?
}

extension UserDTO {
    func toModel() -> User? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let uid = uid,
            let registerDateStr = registerDate,
            let registerDate = formatter.date(from: registerDateStr),
            let loginPlatformStr = loginPlatform,
            let loginPlatform = User.LoginPlatform(rawValue: loginPlatformStr),
            let nickname = nickname,
            let birthdayDateStr = birthdayDate,
            let birthdayDate = formatter.date(from: birthdayDateStr),
            let genderStr = gender,
            let gender = User.Gender(rawValue: genderStr),
            let isPushEnabled = isPushEnabled
        else {
            return nil
        }
        
        return User(
            uid: uid,
            registerDate: registerDate,
            loginPlatform: loginPlatform,
            nickname: nickname,
            profileImageURL: profileImageURL,
            fcmToken: fcmToken,
            birthdayDate: birthdayDate,
            gender: gender,
            isPushEnabled: isPushEnabled,
            groupId: groupId
        )
    }
}

struct CommentDTO: Codable {
    let commentId: String?
    let userId: String?
    let nickname: String?
    let profileImageURL: String?
    let text: String?
    let createdAt: String?
}

extension CommentDTO {
    func toModel() -> Comment? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let commentId = commentId,
            let userId = userId,
            let nickname = nickname,
            let text = text,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr)
        else {
            return nil
        }
        
        return Comment(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: createdAt
        )
    }
}

struct PostDTO: Codable {
    let postId: String?
    let userId: String?
    let nickname: String?
    let profileImageURL: String?
    let imageURL: String?
    let createdAt: String?
    let likeCount: Int?
    let comments: [String: CommentDTO]?
}

extension PostDTO {
    func toModel() -> Post? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let postId = postId,
            let userId = userId,
            let nickname = nickname,
            let imageURL = imageURL,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let likeCount = likeCount
        else {
            return nil
        }
        
        // let comments = self.comments?.compactMap { $0.toModel() } ?? []
        let commentList = self.comments?.compactMapValues { $0.toModel() } ?? [:]

        return Post(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: createdAt,
            likeCount: likeCount,
            comments: commentList
        )
    }
}

struct HCGroupDTO: Codable {
    let groupId: String?
    let groupName: String?
    let createdAt: String?
    let hostUserId: String?
    let inviteCode: String?
    let members: [String: String]?
    var postsByDate: [String: [String: PostDTO]]? // postId가 key인 딕셔너리
}

extension HCGroupDTO {
    func toModel() -> HCGroup? {
        let formatter = ISO8601DateFormatter()
                
        guard
            let groupId = groupId,
            let groupName = groupName,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let hostUserId = hostUserId,
            let inviteCode = inviteCode
        else {
            return nil
        }
        
        let memberDict = members ?? [:]
        
        
        var postsByDate: [String: [Post]] = [:]
        postsByDate = postsByDate.merging(
            self.postsByDate?.compactMapValues { dict in
                dict.compactMap { $0.value.toModel() }
            } ?? [:],
            uniquingKeysWith: { $1 }
        )
        
        return HCGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: memberDict,
            postsByDate: postsByDate
        )
    }
}


// MARK: - Sample
extension User {
    static var sampleUser1: User {
        User(uid: "stub-uid",
             registerDate: Date(),
             loginPlatform: .apple,
             nickname: "stub-nickname-apple",
             birthdayDate: Date.toKoreanDate(year: 2000, month: 1, day: 29),
             gender: .male,
             isPushEnabled: true
        )
    }
    
    static var sampleUser2: User {
        User(uid: "stub-uid",
             registerDate: Date(),
             loginPlatform: .kakao,
             nickname: "stub-nickname-kakao",
             birthdayDate: Date.toKoreanDate(year: 2000, month: 1, day: 29),
             gender: .male,
             isPushEnabled: true
        )
    }
}

// MARK: - Sample
extension Post {
    static var samplePosts = [
        Post(postId: "postId1",
             userId: "index",
             nickname: "동현",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c1": Comment(
                     commentId: "c1",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "귀여운 사진이네요!",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId2",
             userId: "anotherUser",
             nickname: "동현1",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c2": Comment(
                     commentId: "c2",
                     userId: "index",
                     nickname: "동현",
                     profileImageURL: nil,
                     text: "고양이 너무 사랑스럽다!",
                     createdAt: .now),
                 "c3": Comment(
                     commentId: "c3",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "진짜 귀엽다 ㅠㅠ",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId3",
             userId: "index",
             nickname: "동현2",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c4": Comment(
                     commentId: "c4",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "사진 너무 잘 나왔어요!",
                     createdAt: .now)
             ])
    ]
    
    static var samplePosts2 = [
        Post(postId: "postId1",
             userId: "index",
             nickname: "동현",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c1": Comment(
                     commentId: "c1",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "귀여운 사진이네요!",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId2",
             userId: "anotherUser",
             nickname: "동현1",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c2": Comment(
                     commentId: "c2",
                     userId: "index",
                     nickname: "동현",
                     profileImageURL: nil,
                     text: "고양이 너무 사랑스럽다!",
                     createdAt: .now),
                 "c3": Comment(
                     commentId: "c3",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "진짜 귀엽다 ㅠㅠ",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId3",
             userId: "index",
             nickname: "동현2",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .toKoreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c4": Comment(
                     commentId: "c4",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "사진 너무 잘 나왔어요!",
                     createdAt: .now)
             ])
    ]
}
