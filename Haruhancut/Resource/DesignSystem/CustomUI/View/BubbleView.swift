//
//  BubbleView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit

final class BubbleView: UIView {
    
    private let cornerRadius: CGFloat = 20
    private let tipWidth: CGFloat = 20
    private let tipHeight: CGFloat = 10
    private lazy var textLabel: HCLabel = {
        let label = HCLabel(type: .custom(text: text,
                                          font: .hcFont(.bold, size: 16),
                                          color: .mainWhite))
        label.textAlignment = .center
        return label
    }()
    
    var text: String {
        didSet {
            textLabel.text = text
            setNeedsDisplay() // 말풍선 다시 그리기 (tip 중앙 유지용)
        }
    }
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        self.backgroundColor = .clear
        makeUI()
        constraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 말풍선 모양
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height - tipHeight // 말풍선 높이
        
        // 시작저미 왼쪽 위 모서리
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // 상단 라인
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: cornerRadius),
                          controlPoint: CGPoint(x: width, y: 0))
        
        // 우측 라인
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height),
                          controlPoint: CGPoint(x: width, y: height))
        
        // 아래쪽 중앙에 tip 삼각형 추가
        let tipStartX = (width - tipWidth) / 2
        path.addLine(to: CGPoint(x: tipStartX + tipWidth, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height + tipHeight))
        path.addLine(to: CGPoint(x: tipStartX, y: height))

        // 좌측 라인
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius),
                          controlPoint: CGPoint(x: 0, y: height))

        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                          controlPoint: CGPoint(x: 0, y: 0))
        
        // ✅ 색상 채우기
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.Gray500.cgColor

        layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        layer.insertSublayer(shapeLayer, at: 0)
    }
    
    private func makeUI() {
        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -tipHeight - 12),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}

/// 버블 박스
final class TooltipBubbleView: UIView {
    private let cornerRadius: CGFloat = 20
    private let tipWidth: CGFloat = 20
    private let tipHeight: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // 배경은 투명하게
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // ✅ 여기서 실제 말풍선 모양을 그림
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height - tipHeight // 말풍선 본체 높이

        // 시작점: 왼쪽 위 모서리
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // 상단 라인
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: cornerRadius),
                          controlPoint: CGPoint(x: width, y: 0))

        // 우측 라인
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height),
                          controlPoint: CGPoint(x: width, y: height))

        // ✅ 아래쪽 중앙에 tip 삼각형 추가
        let tipStartX = (width - tipWidth) / 2
        path.addLine(to: CGPoint(x: tipStartX + tipWidth, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height + tipHeight))
        path.addLine(to: CGPoint(x: tipStartX, y: height))

        // 좌측 라인
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius),
                          controlPoint: CGPoint(x: 0, y: height))

        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                          controlPoint: CGPoint(x: 0, y: 0))

        // ✅ 색상 채우기
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.gray.cgColor

        layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        layer.insertSublayer(shapeLayer, at: 0)
    }
}


