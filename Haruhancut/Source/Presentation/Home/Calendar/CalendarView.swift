//  CalendarViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class CalendarView: UIView {
    
    // MARK: - UI Component

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background

    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([

        ])
    }
}


#Preview {
    CalendarViewController(homeViewModel: StubHomeViewModel())
}
