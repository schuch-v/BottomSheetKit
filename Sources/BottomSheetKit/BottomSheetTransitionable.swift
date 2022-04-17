//
//  BottomSheetTransitionable.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public protocol BottomSheetTransitionable: AnyObject {
    var dismissalView: UIView? { get }
    var dismissalScrollView: UIScrollView? { get }
}

public extension BottomSheetTransitionable {
    var dismissalScrollView: UIScrollView? {
        nil
    }
}

public extension BottomSheetTransitionable where Self: UIViewController {
    var dismissalView: UIView? {
        view
    }
    
    func updateBottomSheetPresentationLayout(animated: Bool = false, completion: (() -> Void)? = nil) {
        let parent = self.parent as? BottomSheetViewController
        let navigationController = self.navigationController as? BottomSheetNavigationController
        let navigationControllerParent = navigationController?.parent as? BottomSheetViewController
        let bottomSheetViewController = parent ?? navigationControllerParent
        let bottomSheetPresentationController = bottomSheetViewController?.presentationController as? BottomSheetPresentationController
        guard let containerView = bottomSheetPresentationController?.containerView else { return }
        
        containerView.setNeedsLayout()
        
        guard animated else {
            containerView.layoutIfNeeded()
            return
        }
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: .curveEaseInOut,
            animations: { containerView.layoutIfNeeded() },
            completion: { _ in completion?() }
        )
    }
    
}
