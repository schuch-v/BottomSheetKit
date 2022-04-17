//
//  BottomSheetPresentationController.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public final class BottomSheetPresentationController: UIPresentationController {
    private var minimumHeightRatio: CGFloat
    private var maximumHeightRatio: CGFloat

    lazy var fadeView: UIView = {
        let fadeView = UIView()
        fadeView.backgroundColor = .black.withAlphaComponent(0.3)
        fadeView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        fadeView.addGestureRecognizer(tapGesture)
        return fadeView
    }()

    override public var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        guard let presentedView = getPresentedView() else { return .zero }

        let containerBounds = containerView.bounds

        let fittingSize = CGSize(
            width: containerBounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        let targetHeight = presentedView
            .systemLayoutSizeFitting(
                fittingSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            .height

        let minimumHeight = containerBounds.height * minimumHeightRatio
        let maximumHeight = containerBounds.height * maximumHeightRatio - containerView.safeAreaInsets.top

        let finalSize = CGSize(
            width: containerBounds.width,
            height: min(maximumHeight, max(minimumHeight, targetHeight))
        )

        var frame = containerBounds
        frame.origin.y += containerBounds.height - finalSize.height
        frame.size = finalSize

        return frame
    }

    public init(
        minimumHeightRatio: CGFloat,
        maximumHeightRatio: CGFloat,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.minimumHeightRatio = minimumHeightRatio
        self.maximumHeightRatio = maximumHeightRatio
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override public func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        containerView.insertSubview(fadeView, at: 0)

        fadeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fadeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            fadeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            fadeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            fadeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 1.0
        })
    }

    override public func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 0.0
            return
        }

        if !coordinator.isInteractive {
            coordinator.animate(alongsideTransition: { _ in
                self.fadeView.alpha = 0.0
            })
        }
    }

    override public func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    @objc
    private func dismiss() {
        presentedViewController.dismiss(animated: true)
    }
    
    private func getPresentedView() -> UIView? {
        // systemLayoutSizeFitting(_:) when used on UINavigationController's view return the size of the navigationBar.
        // If we are presenting a UINavigationController we will compute the bottomSheet size using the topViewController's view
        guard let bottomSheetViewController = presentedViewController as? BottomSheetViewController else {
            return presentedView
        }
        guard let bottomSheetNavigationController = bottomSheetViewController.children.first as? BottomSheetNavigationController else {
            return presentedView
        }
        return bottomSheetNavigationController.topViewController?.view
    }
}
