import Foundation
import UIKit

public class SlidingLabel: UIView {
    public var label = UILabel()
    public var spacing = 30.0
    
    public private(set) var isSliding = false
    // keep reference to the copy labels to make sliding circular
    private var cpLabels = [UILabel]()
    private var velocity = 0.0
    private var delay = 0.0
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        super.init(frame: .zero)
        clipsToBounds = true
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: self.leftAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func stopAnimation() {
        resetLayout()
        isSliding = false
        velocity = 0.0
        delay = 0.0
    }
    
    
    public func startAnimation(_ velocity: Double = 100.0, delay: Double = 1.0) {
        if isSliding { return }
        self.velocity = velocity
        self.delay = delay
        
        DispatchQueue.main.async {
            self.startSlidingIfNeed()
        }
    }
    
    private func startSlidingIfNeed() {
        let desiredWidth = computeDesiredSize(view: label).width
        if label.text?.isEmpty != true,
           velocity > 0,
           desiredWidth > bounds.width {
            self.isSliding = true
            self.slide(delay,
                       velocity,
                       bounds.width,
                       desiredWidth)
        }
    }
    
    private func computeDesiredSize(view: UIView) -> CGSize {
        let maximumLabelSize = CGSize(width: CGFloat.greatestFiniteMagnitude,
                                      height: CGFloat.greatestFiniteMagnitude)
        var expectedLabelSize = view.sizeThatFits(maximumLabelSize)
        expectedLabelSize.height = view.bounds.size.height
        return expectedLabelSize
    }
    
    private func slide(_ delay: Double,
                       _ velocity: CGFloat,
                       _ displayWidth: Double,
                       _ desiredWidth: Double) {
        let copy1 = label.deepCopy()
        copy1.translatesAutoresizingMaskIntoConstraints = false
        addSubview(copy1)
        NSLayoutConstraint.activate([
            copy1.leftAnchor.constraint(equalTo: self.leftAnchor),
            copy1.topAnchor.constraint(equalTo: self.topAnchor),
            copy1.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        let copy2 = label.deepCopy()
        copy2.translatesAutoresizingMaskIntoConstraints = false
        addSubview(copy2)
        NSLayoutConstraint.activate([
            copy2.leftAnchor.constraint(equalTo: self.leftAnchor),
            copy2.topAnchor.constraint(equalTo: self.topAnchor),
            copy2.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        cpLabels.append(contentsOf: [copy1, copy2])
    
        let gap = (displayWidth - spacing) / velocity
        let slideFromEdgeDuration = (displayWidth + desiredWidth) / velocity
        let loopDuration = (slideFromEdgeDuration - gap) * 2
        
        let _1stDuration = desiredWidth / velocity
        let _2ndDelay = delay + _1stDuration - gap
        let _3rdDelay = _2ndDelay + slideFromEdgeDuration - gap
        
        let linearOption = KeyframeAnimationOptions(rawValue: AnimationOptions.curveLinear.rawValue)
        UIView.animate(withDuration: _1stDuration,
                       delay: delay,
                       options: [.curveLinear],
                       animations: { [weak self] in
            self?.label.transform = CGAffineTransform(translationX: -desiredWidth, y: 0)
        })
        
        copy1.transform = CGAffineTransform(translationX: displayWidth, y: 0)
        UIView.animateKeyframes(withDuration: loopDuration,
                                delay: _2ndDelay,
                                options: [.repeat, linearOption]) {
            UIView.addKeyframe(withRelativeStartTime: 0.0,
                               relativeDuration: slideFromEdgeDuration / loopDuration) { [weak copy1] in
                copy1?.transform = CGAffineTransform(translationX: -desiredWidth, y: 0)
            }
        }
        
        copy2.transform = CGAffineTransform(translationX: displayWidth, y: 0)
        UIView.animateKeyframes(withDuration: loopDuration,
                                delay: _3rdDelay,
                                options: [.repeat, linearOption]) {
            UIView.addKeyframe(withRelativeStartTime: 0.0,
                               relativeDuration: slideFromEdgeDuration / loopDuration) { [weak copy2] in
                copy2?.transform = CGAffineTransform(translationX: -desiredWidth, y: 0)
            }
        }
    }
    
    @objc private func willEnterForeground() {
        if self.isSliding {
            resetLayout()
            startSlidingIfNeed()
        }
    }
    
    private func resetLayout() {
        label.layer.removeAllAnimations()
        cpLabels.forEach { $0.removeFromSuperview() }
        label.transform = .identity
    }
}

fileprivate extension UILabel {
    func deepCopy() -> UILabel {
        let copy = UILabel()
        copy.text = self.text
        copy.font = self.font
        copy.textColor = self.textColor
        copy.textAlignment = self.textAlignment
        copy.lineBreakMode = self.lineBreakMode
        copy.numberOfLines = self.numberOfLines
        copy.backgroundColor = self.backgroundColor
        copy.isEnabled = self.isEnabled
        copy.isHidden = self.isHidden
        copy.isHighlighted = self.isHighlighted
        copy.shadowColor = self.shadowColor
        copy.shadowOffset = self.shadowOffset
        copy.attributedText = self.attributedText
        copy.adjustsFontSizeToFitWidth = self.adjustsFontSizeToFitWidth
        copy.minimumScaleFactor = self.minimumScaleFactor
        copy.allowsDefaultTighteningForTruncation = self.allowsDefaultTighteningForTruncation
        
        // Frame-related properties
        copy.frame = self.frame
        copy.bounds = self.bounds
        copy.center = self.center
        copy.transform = self.transform
        
        // Layer properties
        copy.layer.cornerRadius = self.layer.cornerRadius
        copy.layer.borderWidth = self.layer.borderWidth
        copy.layer.borderColor = self.layer.borderColor
        copy.layer.shadowColor = self.layer.shadowColor
        copy.layer.shadowOpacity = self.layer.shadowOpacity
        copy.layer.shadowOffset = self.layer.shadowOffset
        copy.layer.shadowRadius = self.layer.shadowRadius
        copy.layer.masksToBounds = self.layer.masksToBounds
        return copy
    }
}

