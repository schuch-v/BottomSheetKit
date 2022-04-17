//
//  BottomSheetTransitionAnimator.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public final class BottomSheetTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private enum Constants {
        static var animationDuration: TimeInterval = 0.5
        static var animationDampingRatio: CGFloat = 1
    }

    private let presenting: Bool

    public init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Constants.animationDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        let presentedViewController = transitionContext.viewController(forKey: .to)!

        transitionContext.containerView.addSubview(presentedViewController.view)

        let presentedFrame = transitionContext.finalFrame(for: presentedViewController)

        let dismissedFrame = CGRect(
            x: presentedFrame.minX,
            y: transitionContext.containerView.bounds.height,
            width: presentedFrame.width,
            height: presentedFrame.height
        )

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

        presentedViewController.view.frame = dismissedFrame
        presentedViewController.view.layoutIfNeeded()

        CATransaction.commit()

        let animator = UIViewPropertyAnimator(
            duration: transitionDuration(using: transitionContext),
            dampingRatio: Constants.animationDampingRatio,
            animations: {
                presentedViewController.view.frame = presentedFrame
                presentedViewController.view.layoutIfNeeded()
            }
        )

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let presentedViewController = transitionContext.viewController(forKey: .from)!
        let presentedFrame = transitionContext.finalFrame(for: presentedViewController)

        let dismissedFrame = CGRect(
            x: presentedFrame.minX,
            y: transitionContext.containerView.bounds.height,
            width: presentedFrame.width,
            height: presentedFrame.height
        )

        let animator = UIViewPropertyAnimator(
            duration: transitionDuration(using: transitionContext),
            dampingRatio: Constants.animationDampingRatio,
            animations: {
                presentedViewController.view.frame = dismissedFrame
                presentedViewController.view.layoutIfNeeded()
            }
        )

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }
}
