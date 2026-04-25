import UIKit

/// Presents a view controller as a centered "floating card" with a dimmed backdrop.
final class CenteredCardTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let cornerRadius: CGFloat
    private let maxWidth: CGFloat
    private let horizontalInset: CGFloat
    private let verticalInset: CGFloat

    init(
        cornerRadius: CGFloat = 18,
        maxWidth: CGFloat = 460,
        horizontalInset: CGFloat = 16,
        verticalInset: CGFloat = 24
    ) {
        self.cornerRadius = cornerRadius
        self.maxWidth = maxWidth
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        super.init()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        CenteredCardPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            cornerRadius: cornerRadius,
            maxWidth: maxWidth,
            horizontalInset: horizontalInset,
            verticalInset: verticalInset
        )
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        CenteredCardAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        CenteredCardAnimator(isPresenting: false)
    }
}

private final class CenteredCardPresentationController: UIPresentationController {
    private let cornerRadius: CGFloat
    private let maxWidth: CGFloat
    private let horizontalInset: CGFloat
    private let verticalInset: CGFloat
    private let shadowView = UIView()

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView)))
        return view
    }()

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        cornerRadius: CGFloat,
        maxWidth: CGFloat,
        horizontalInset: CGFloat,
        verticalInset: CGFloat
    ) {
        self.cornerRadius = cornerRadius
        self.maxWidth = maxWidth
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else { return }
        dimmingView.frame = containerView.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.insertSubview(dimmingView, at: 0)

        shadowView.backgroundColor = .clear
        shadowView.isUserInteractionEnabled = false
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.18
        shadowView.layer.shadowRadius = 16
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.insertSubview(shadowView, aboveSubview: dimmingView)

        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        } else {
            dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { _ in
                self.dimmingView.alpha = 0
            }
        } else {
            dimmingView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
            shadowView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        shadowView.frame = presentedView?.frame ?? .zero
        applyCardStyling()
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }

        let bounds = containerView.bounds.insetBy(dx: horizontalInset, dy: verticalInset)
        let width = min(bounds.width, maxWidth)

        // Use preferredContentSize when available; otherwise use a reasonable fraction of height.
        let preferredHeight = presentedViewController.preferredContentSize.height
        let height = min(
            bounds.height,
            (preferredHeight > 0 ? preferredHeight : bounds.height * 0.72)
        )

        let originX = bounds.midX - width / 2
        let originY = bounds.midY - height / 2
        return CGRect(x: originX, y: originY, width: width, height: height).integral
    }

    private func applyCardStyling() {
        guard let presentedView else { return }
        presentedView.layer.cornerRadius = cornerRadius
        presentedView.layer.cornerCurve = .continuous
        presentedView.layer.masksToBounds = true

        shadowView.layer.cornerRadius = cornerRadius
        shadowView.layer.cornerCurve = .continuous
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: cornerRadius).cgPath
    }

    @objc private func didTapDimmingView() {
        presentedViewController.dismiss(animated: true)
    }
}

private final class CenteredCardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewKey = isPresenting ? .to : .from
        guard let animatingView = transitionContext.view(forKey: key) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView

        if isPresenting {
            container.addSubview(animatingView)
            animatingView.alpha = 0
            animatingView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: isPresenting ? 0.86 : 1.0,
            initialSpringVelocity: 0.0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        ) {
            animatingView.alpha = self.isPresenting ? 1 : 0
            animatingView.transform = self.isPresenting ? .identity : CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            if !self.isPresenting {
                animatingView.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

