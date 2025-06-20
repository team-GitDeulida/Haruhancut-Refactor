//
//  SettingCell.swift
//  Haruhancut
//
//  Created by 김동현 on 6/20/25.
//

import UIKit

struct SettingSection {
    let header: String?
    var options: [SettingOption]
}

enum SettingOption {
    case toggle(title: String, isOn: Bool)        // 알림 설정 같은 토글
    case version(title: String, detail: String)   // 버전 정보
    case privacyPolicy(title: String)             // 개인정보처리방침
    case announce(title: String)                  // 공지사항
    case logout(title: String)                    // 로그아웃
    case withdraw(title: String)                  // 회원 탈퇴

    // MARK: – 표시할 왼쪽 텍스트
    var title: String {
        switch self {
        case let .toggle(title, _),
             let .version(title, _),
             let .privacyPolicy(title),
             let .announce(title),
             let .logout(title),
             let .withdraw(title):
            return title
        }
    }

    // MARK: – 상세 텍스트: version 케이스에서만 사용
    var detailText: String? {
        switch self {
        case let .version(_, detail):
            return detail
        default:
            return nil
        }
    }

    // MARK: – 토글 값: toggle 케이스에서만 사용
    var toggleValue: Bool? {
        switch self {
        case let .toggle(_, isOn):
            return isOn
        default:
            return nil
        }
    }
}

final class SettingCell: UITableViewCell {
    
    // MARK: - UI
    private let leftLabel: UILabel = {
        let label = UILabel()
        label.text = "왼쪽"
        label.textColor = .mainWhite
        label.numberOfLines = 1
        label.font = .hcFont(.semiBold, size: 18)
        return label
    }()
    
    private let rightLabel: UILabel = {
        let label = UILabel()
        label.text = "오른쪽"
        label.textColor = .mainWhite
        label.numberOfLines = 1
        label.font = .hcFont(.extraBold, size: 16)
        return label
    }()
    
    let toggleSwitch: UISwitch = {
        let sw = UISwitch()
        sw.tintColor = .systemBlue
        return sw
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        makeUI()
        constraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindeCell(option: SettingOption) {
        self.leftLabel.text = option.title
        
        // detailText가 있으면 rightLabel 표시
        if let detail = option.detailText {
            rightLabel.text = detail
            rightLabel.isHidden = false
        } else {
            rightLabel.isHidden = true
        }
        
        if let isOn = option.toggleValue {
            toggleSwitch.isHidden = false
            toggleSwitch.isOn = isOn
        } else {
            toggleSwitch.isHidden = true
        }
        
        // 2) '회원 탈퇴'만 빨간색, 나머지 기본 색
        if case .withdraw = option {
            leftLabel.textColor = .systemRed
        } else {
            leftLabel.textColor = .mainWhite
        }
    }
    
    private func makeUI() {
        self.backgroundColor = .clear
        [leftLabel, toggleSwitch, rightLabel].forEach {
            self.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            leftLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            rightLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
    }
}
