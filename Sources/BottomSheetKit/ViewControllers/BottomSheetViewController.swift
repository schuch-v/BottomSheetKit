//
//  BottomSheetViewController.swift
//  BottomSheetKit
//
//  Created by Victor Schuchmann on 05/04/2022.
//

import UIKit

public final class BottomSheetViewController: UIViewController, BottomSheetTransitionable {
    private enum Constants {
        static var cornerRadius: CGFloat = 10
        static var shadowOpacity: Float = 0.1
        static var panIndicatorWidth: CGFloat = 63
        static var panIndicatorHeight: CGFloat = 5
        static var panIndicatorMargin: CGFloat = 8
    }

    private let childViewController: UIViewController & BottomSheetTransitionable
    private(set) var bottomSheetTransitionDelegate: BottomSheetTransitionDelegate?

    public var dismissalView: UIView? {
        childViewController.dismissalView
    }

    public var dismissalScrollView: UIScrollView? {
        childViewController.dismissalScrollView
    }

    override public var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            bottomSheetTransitionDelegate
        }
        set {
            /* Should not be changed */
        }
    }

    override public var modalPresentationStyle: UIModalPresentationStyle {
        get {
            .custom
        }
        set {
            /* Should not be changed */
        }
    }

    public init(embed viewController: UIViewController & BottomSheetTransitionable, minimumHeightRatio: CGFloat = 0, maximumHeightRatio: CGFloat = 1) {
        self.childViewController = viewController
        super.init(nibName: nil, bundle: nil)
        let bottomSheetInteractiveTransitioning = BottomSheetInteractiveTransitioning(viewController: self)
        self.bottomSheetTransitionDelegate = BottomSheetTransitionDelegate(
            minimumHeightRatio: minimumHeightRatio,
            maximumHeightRatio: maximumHeightRatio,
            bottomSheetInteractiveTransitioning: bottomSheetInteractiveTransitioning
        )
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
    
    private func setup() {
        setupView()
        setupChild()
        setupPanIndicator()
    }

    private func setupView() {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = Constants.cornerRadius
        view.layer.shadowOpacity = Constants.shadowOpacity
    }

    private func setupChild() {
        view.addSubview(childViewController.view)
        addChild(childViewController)
        childViewController.didMove(toParent: self)
        childViewController.additionalSafeAreaInsets.top = Constants.panIndicatorMargin * 2 + Constants.panIndicatorHeight
        childViewController.view.layer.masksToBounds = true
        childViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        childViewController.view.layer.cornerRadius = Constants.cornerRadius
        if #available(iOS 13.0, *) { childViewController.view.layer.cornerCurve = .continuous }
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupPanIndicator() {
        let panIndicatorView = UIView()
        panIndicatorView.backgroundColor = .black
        panIndicatorView.layer.cornerRadius = Constants.panIndicatorHeight / 2
        panIndicatorView.clipsToBounds = true
        panIndicatorView.isUserInteractionEnabled = false
        panIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panIndicatorView)
        NSLayoutConstraint.activate([
            panIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.panIndicatorMargin),
            panIndicatorView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.panIndicatorMargin),
            panIndicatorView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.panIndicatorMargin),
            panIndicatorView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.panIndicatorMargin),
            panIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            panIndicatorView.heightAnchor.constraint(equalToConstant: Constants.panIndicatorHeight),
            panIndicatorView.widthAnchor.constraint(equalToConstant: Constants.panIndicatorWidth)
        ])
    }
}
