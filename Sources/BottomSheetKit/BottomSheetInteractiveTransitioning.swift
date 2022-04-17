//
//  BottomSheetInteractiveTransitioning.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public final class BottomSheetInteractiveTransitioning: NSObject, UIViewControllerInteractiveTransitioning, UIGestureRecognizerDelegate {
    private enum Constants {
        static let animationDuration: TimeInterval = 0.5
        static let animationDampingRatio: CGFloat = 0.8
        static let closeRatio: CGFloat = 0.5
        static let stretchingProgressRatio: CGFloat = 0.2
        static let finishVelocity: CGFloat = 300
        static let cancelVelocity: CGFloat = -300
    }

    private weak var viewController: (UIViewController & BottomSheetTransitionable)!
    private weak var transitionContext: UIViewControllerContextTransitioning?

    private var interactionDistance: CGFloat = 0
    private var presentedFrame: CGRect?

    private(set) var interactionInProgress = false

    public init(viewController: UIViewController & BottomSheetTransitionable) {
        self.viewController = viewController
        super.init()
        setupDissmissGestureRecognizers(in: viewController)
    }

    func setupDissmissGestureRecognizers(in viewController: UIViewController & BottomSheetTransitionable) {
        if let dismissalView = viewController.dismissalView {
            setupViewDismissGestureRecognizer(in: dismissalView)
        }
        if let scrollView = viewController.dismissalScrollView {
            setupScrollViewDismissGestureRecognizer(in: scrollView)
        }
    }

    private func setupViewDismissGestureRecognizer(in view: UIView) {
        guard !view.containsDismissGestureRecognizer else { return }
        let dismissGesture = VerticalPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        dismissGesture.direction = .both
        dismissGesture.delegate = self
        view.addGestureRecognizer(dismissGesture)
    }

    private func setupScrollViewDismissGestureRecognizer(in scrollView: UIScrollView) {
        guard !scrollView.containsDismissGestureRecognizer else { return }
        let scrollViewDismissGesture = VerticalPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        scrollViewDismissGesture.direction = .down
        scrollViewDismissGesture.delegate = self
        scrollView.addGestureRecognizer(scrollViewDismissGesture)
        scrollView.panGestureRecognizer.require(toFail: scrollViewDismissGesture)
    }

    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !interactionInProgress else { return false }
        guard let scrollView = viewController.dismissalScrollView else { return true }
        return scrollView.contentOffset.y <= 0
    }

    // MARK: - Gesture handling
    @objc
    private func handleGesture(_ gestureRecognizer: VerticalPanGestureRecognizer) {
        guard let superview = gestureRecognizer.view?.superview else { return }
        let translation = gestureRecognizer.translation(in: superview).y
        let velocity = gestureRecognizer.velocity(in: superview).y

        switch gestureRecognizer.state {
        case .began:
            gestureBegan()
        case .changed:
            gestureChanged(translation: translation, velocity: velocity)
        case .cancelled:
            gestureCancelled(translation: translation, velocity: velocity)
        case .ended:
            gestureEnded(translation: translation, velocity: velocity)
        default:
            break
        }
    }

    private func gestureBegan() {
        if !interactionInProgress {
            interactionInProgress = true
            viewController.dismiss(animated: true)
        }
    }

    private func gestureChanged(translation: CGFloat, velocity: CGFloat) {
        var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
        if progress < 0 {
            // Limit the ability to expand the bottom sheet when swiping up
            progress *= Constants.stretchingProgressRatio
        }
        update(progress: progress)
    }

    private func gestureCancelled(translation: CGFloat, velocity: CGFloat) {
        cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
    }

    private func gestureEnded(translation: CGFloat, velocity: CGFloat) {
        let hasEnoughFinishVelocity = velocity > Constants.finishVelocity
        let hasEnoughCancelVelocity = velocity < Constants.cancelVelocity
        let hasTranslatedPastCloseRatio = translation > interactionDistance * Constants.closeRatio

        if hasEnoughFinishVelocity || hasTranslatedPastCloseRatio && hasEnoughCancelVelocity == false {
            finish(initialSpringVelocity: springVelocity(distanceToTravel: interactionDistance - translation, gestureVelocity: velocity))
        } else {
            cancel(initialSpringVelocity: springVelocity(distanceToTravel: -translation, gestureVelocity: velocity))
        }
    }

    // MARK: - Transition controlling
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let presentedViewController = transitionContext.viewController(forKey: .from)!
        presentedFrame = transitionContext.finalFrame(for: presentedViewController)
        self.transitionContext = transitionContext
        interactionDistance = transitionContext.containerView.bounds.height - presentedFrame!.minY
    }

    private func update(progress: CGFloat) {
        guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else { return }

        transitionContext.updateInteractiveTransition(progress)

        let presentedViewController = transitionContext.viewController(forKey: .from)!
        let offset = interactionDistance * progress

        presentedViewController.view.frame = CGRect(
            x: presentedFrame.minX,
            y: presentedFrame.minY + offset,
            width: presentedFrame.width,
            height: presentedFrame.height + (offset < 0 ? abs(offset) : 0)
        )

        presentedViewController.bottomSheetPresentationController?.fadeView.alpha = 1.0 - progress
    }

    private func cancel(initialSpringVelocity: CGFloat) {
        guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else { return }

        let presentedViewController = transitionContext.viewController(forKey: .from)!
        let initialVelocity = CGVector(dx: 0, dy: initialSpringVelocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: Constants.animationDampingRatio, initialVelocity: initialVelocity)
        let cancelAnimator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: timingParameters)

        cancelAnimator.addAnimations {
            presentedViewController.view.frame = presentedFrame
            presentedViewController.bottomSheetPresentationController?.fadeView.alpha = 1.0
        }
        cancelAnimator.addCompletion { _ in
            transitionContext.cancelInteractiveTransition()
            transitionContext.completeTransition(false)
            self.interactionInProgress = false
        }
        cancelAnimator.startAnimation()
    }

    private func finish(initialSpringVelocity: CGFloat) {
        guard let transitionContext = transitionContext, let presentedFrame = presentedFrame else { return }

        let presentedViewController = transitionContext.viewController(forKey: .from)!
        let dismissedFrame = CGRect(
            x: presentedFrame.minX,
            y: transitionContext.containerView.bounds.height,
            width: presentedFrame.width,
            height: presentedFrame.height
        )

        let initialVelocity = CGVector(dx: 0, dy: initialSpringVelocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: Constants.animationDampingRatio, initialVelocity: initialVelocity)
        let finishAnimator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: timingParameters)

        finishAnimator.addAnimations {
            presentedViewController.view.frame = dismissedFrame
            presentedViewController.bottomSheetPresentationController?.fadeView.alpha = 0
        }

        finishAnimator.addCompletion { _ in
            transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(true)
            self.interactionInProgress = false
        }

        finishAnimator.startAnimation()
    }

    // MARK: - Helpers
    private func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
        distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
    }
}

fileprivate extension UIViewController {
    var bottomSheetPresentationController: BottomSheetPresentationController? {
        presentationController as? BottomSheetPresentationController
    }
}

fileprivate extension UIView {
    var containsDismissGestureRecognizer: Bool {
        gestureRecognizers?.contains(where: { $0 is VerticalPanGestureRecognizer }) ?? false
    }
}

fileprivate final class VerticalPanGestureRecognizer: UIPanGestureRecognizer {
    enum Direction {
        case up
        case down
        case both
    }

    private var isDragging = false
    private var moveX = 0
    private var moveY = 0

    var direction: Direction = .down

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard state != .failed else { return }

        let touch: UITouch = touches.first! as UITouch
        let nowPoint: CGPoint = touch.location(in: view)
        let prevPoint: CGPoint = touch.previousLocation(in: view)
        moveX += Int(prevPoint.x - nowPoint.x)
        moveY += Int(prevPoint.y - nowPoint.y)

        guard moveY != 0 else { return }

        if isDragging == false {
            isDragging = true
            
            guard abs(moveX) < abs(moveY) else {
                state = .failed
                return
            }
            
            switch direction {
            case .up:
                if moveY < 0 {
                    state = .failed
                }
            case .down:
                if moveY > 0 {
                    state = .failed
                }
            case .both:
                break
            }
        }
    }

    override func reset() {
        super.reset()
        isDragging = false
        moveX = 0
        moveY = 0
    }
}
