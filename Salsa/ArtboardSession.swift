//
//  ArtboardSession.swift
//  Salsa
//
//  Created by Wirawit Rueopas on 31/5/18.
//  Copyright © 2018 Yelp. All rights reserved.
//

import UIKit

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
        groups.append([AutoSketch.makeGroup(view: keyWindow().topViewControllerView, name: name)])
    }
}

/// Start an artboard creation session. In sessionHandler, use `ArtboardSession` to snapWindow/View. These Sketch snapshot groups will be aligned horizontally in the returned artboard.
public func artboardSession(name: String, sessionHandler: (ArtboardSession) -> Void) -> Artboard {
    let session = ArtboardSession()
    sessionHandler(session)
    let groups = AutoSketch.arrange(layers: session.groups,
                                    verticalPadding: 20,
                                    horizontalPadding: 20)
    return AutoSketch.makeArtboard(groups: groups,
                                   insets: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
                                   artboardName: name)
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

