//
//  ArtboardSession.swift
//  Salsa
//
//  Created by Wirawit Rueopas on 31/5/18.
//  Copyright © 2018 Yelp. All rights reserved.
//

import UIKit
import MapKit

func keyWindow() -> UIWindow {
  return UIApplication.shared.keyWindow!
}

/// An artboard session instance.
public final class ArtboardSession {

  fileprivate var groups: [[Group]] = []

  init() {}

  /// Snap the whole window (keyWindow). Make sure `UIApplication.shared.keyWindow!` isn't nil or this will crash.
  public func snapWindow(name: String) {
    groups.append([AutoSketch.makeGroup(view: keyWindow(), name: name)])
  }

  /// Snap specified `UIView`.
  public func snapView(_ view: UIView, name: String) {
    groups.append([AutoSketch.makeGroup(view: view, name: name)])
  }

  /// Snap active (top-most) viewControlelr's view. Useful when you just want the top one, not the whole window that includes navbar/tabbar.
  public func snapTopViewController(name: String) {
    snapView(keyWindow().topViewControllerView, name: name)
//    snapViewContent(keyWindow().topViewControllerView, name: name)
  }

  /// Snap whole content, useful if there's table/scrollview and you want to show it all.
//  public func snapViewContent(_ view: UIView, name: String, maxContentHeight: CGFloat? = nil) {
//    let previousFrame = view.frame
//    let wholeContentRectOnWindow = view.wholeContentRectRelativeToWindow
//    view.frame = .init(origin: view.frame.origin, size: wholeContentRectOnWindow.size)
//    view.layoutIfNeeded()
//
//    snapView(view, name: name)
//
//    view.frame = previousFrame
//    view.layoutIfNeeded()
//  }

  /**
    Apply + unapply view expanding under a session handler.

    - Parameters:
      - shouldExpandFurther: Whether we should expand the view further into subviews when calculating the whole content size.

  */
  public func subSessionExpandWholeContentOfTopViewController(shouldExpandFurther: ((UIView) -> Bool)? = nil, sessionHandler: (UIView) -> Void) {
    let view = keyWindow().topViewControllerView
    let previousFrame = view.frame
    let wholeContentRectOnWindow = view.wholeContentRectRelativeToWindow(shouldExpandFurther: shouldExpandFurther)
    view.frame = .init(origin: view.frame.origin, size: wholeContentRectOnWindow.size)
    view.layoutIfNeeded()

    sessionHandler(view)

    view.frame = previousFrame
    view.layoutIfNeeded()
  }
}

/// A convenient method to start an artboard creation session. In sessionHandler, use `ArtboardSession` to snapWindow/ViewController. These Sketch snapshot groups will be aligned horizontally in the returned artboard. To get more sophisticated behaviours (e.g., aligned in both axes), make a new custom convenient method.
public func artboardSession(name: String,
                            verticalPadding: CGFloat = 20,
                            horizontalPadding: CGFloat = 24,
                            artboardInsets: UIEdgeInsets = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
                            sessionHandler: (ArtboardSession) -> Void) -> Artboard {
  let session = ArtboardSession()
  sessionHandler(session)
  let groups = AutoSketch.arrange(layers: session.groups,
                                  verticalPadding: verticalPadding,
                                  horizontalPadding: horizontalPadding)
  return AutoSketch.makeArtboard(groups: groups,
                                 insets: artboardInsets,
                                 artboardName: name)
}

extension UIView {
  func wholeContentRectRelativeToWindow(shouldExpandFurther: ((UIView) -> Bool)? = nil) -> CGRect {

    // If no superview, probably keyWindow
    let sup = superview ?? self

    // current frame (relative to window)
    var contentFrame = sup.convert(frame, to: nil)

    defer {
      print("Final content frame for \(type(of: self)) is \(contentFrame)")
    }

    // If map view, don't go further into its subviews
    if isKind(of: MKMapView.self) {
      return contentFrame
    }

    // There maybe other cases we don't want to expand
    if let shouldExpandFurther = shouldExpandFurther, !shouldExpandFurther(self) {
      return contentFrame
    }

    // If scrollview, use content size (relative to window) as baseline
    if let scrollView = self as? UIScrollView {
      contentFrame = contentFrame.combined(with: sup.convert( .init(origin: frame.origin, size: scrollView.contentSize), to: nil))
    }

    // Combine with all subview frames (again, all already relative to window)
    for sv in subviews {
      contentFrame = contentFrame.combined(with: sv.wholeContentRectRelativeToWindow(shouldExpandFurther: shouldExpandFurther))
    }
    return contentFrame
  }
}

public extension UIWindow {

  /// Top-most/active view controller on screen.
  var topViewController: UIViewController {
    return rootViewController!.topViewController
  }

  /// Top-most/active view controller's view.
  var topViewControllerView: UIView {
    return rootViewController!.topViewController.view
  }
}

extension UIViewController {
  fileprivate var topViewController: UIViewController {
    switch self {
    case is UINavigationController:
      return (self as! UINavigationController).visibleViewController?.topViewController ?? self
    case is UITabBarController:
      return (self as! UITabBarController).selectedViewController?.topViewController ?? self
    default:
      return presentedViewController?.topViewController ?? self
    }
  }
}

