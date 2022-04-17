//
//  BottomSheetTransitionDelegate.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public final class BottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let minimumHeightRatio: CGFloat
    private let maximumHeightRatio: CGFloat
    private let bottomSheetInteractiveTransitioning: BottomSheetInteractiveTransitioning?

    public init(minimumHeightRatio: CGFloat, maximumHeightRatio: CGFloat, bottomSheetInteractiveTransitioning: BottomSheetInteractiveTransitioning?) {
        self.minimumHeightRatio = minimumHeightRatio
        self.maximumHeightRatio = maximumHeightRatio
        self.bottomSheetInteractiveTransitioning = bottomSheetInteractiveTransitioning
    }

    func addDissmissGestures(to viewController: UIViewController & BottomSheetTransitionable) {
        bottomSheetInteractiveTransitioning?.setupDissmissGestureRecognizers(in: viewController)
    }

    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        BottomSheetPresentationController(
            minimumHeightRatio: minimumHeightRatio,
            maximumHeightRatio: maximumHeightRatio,
            presentedViewController: presented,
            presenting: presenting
        )
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetTransitionAnimator(presenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetTransitionAnimator(presenting: false)
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard bottomSheetInteractiveTransitioning?.interactionInProgress == true else { return nil }
        return bottomSheetInteractiveTransitioning
    }
}
