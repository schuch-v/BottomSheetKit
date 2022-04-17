//
//  BottomSheetNavigationController.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 14/04/2022.
//

import UIKit

public final class BottomSheetNavigationController: UINavigationController, BottomSheetTransitionable {
    private var bottomSheetTransitionDelegate: BottomSheetTransitionDelegate? {
        (parent as? BottomSheetViewController)?.bottomSheetTransitionDelegate
    }

    public var dismissalScrollView: UIScrollView? {
        (topViewController as? BottomSheetTransitionable)?.dismissalScrollView
    }
    
    private let bottomSheetNavigationControllerDelegate = BottomSheetNavigationControllerDelegate()
    
    public override var delegate: UINavigationControllerDelegate? {
        get {
            bottomSheetNavigationControllerDelegate
        }
        set {
            bottomSheetNavigationControllerDelegate.decorated = newValue
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = bottomSheetNavigationControllerDelegate
        interactivePopGestureRecognizer?.delegate = nil
    }
    
    override public func pushViewController(_ viewController: UIViewController, animated: Bool = true) {
        addDissmissGestures(to: viewController)
        super.pushViewController(viewController, animated: animated)
    }

    override public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool = true) {
        viewControllers.forEach(addDissmissGestures(to:))
        super.setViewControllers(viewControllers, animated: animated)
    }

    private func addDissmissGestures(to viewController: UIViewController?) {
        if let bottomSheetTransitionableViewController = viewController as? (UIViewController & BottomSheetTransitionable) {
            bottomSheetTransitionDelegate?.addDissmissGestures(to: bottomSheetTransitionableViewController)
        }
    }
}

fileprivate final class BottomSheetNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    weak var decorated: UINavigationControllerDelegate?
    
    private var didShowInitialViewController = false
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        decorated?.navigationController?(navigationController, willShow: viewController, animated: animated)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if didShowInitialViewController {
            (navigationController as? UIViewController & BottomSheetTransitionable)?.updateBottomSheetPresentationLayout(animated: animated)
        } else {
            didShowInitialViewController = true
        }
        decorated?.navigationController?(navigationController, didShow: viewController, animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        decorated?.navigationController?(navigationController, interactionControllerFor: animationController)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        decorated?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
    }
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        decorated?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .all
    }
    
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        decorated?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
    }
}
