//
//  Salsa+AutoSketch.swift
//  Salsa
//
//  Created by Wirawit Rueopas on 28/5/18.
//

import UIKit

/// Utilitiy class for making Artboard/Group from laid-out view instance.
public struct AutoSketch {

  /// Make artboard with frame relative to its own space (e.g. origin always (0,0))
  public static func makeArtboard(groups: [Group], insets: UIEdgeInsets, artboardName: String) -> Artboard {

    // Shifts every groups with left/top insets
    groups.forEach { (g) in
      g.frame = g.frame.offsetBy(dx: insets.left, dy: insets.top)
    }

    var width: CGFloat = 0
    var height: CGFloat = 0

    // Get right/bottom most position
    groups.forEach { g in
      height = max(height, g.frame.bottom)
      width = max(width, g.frame.right)
    }

    // Plus right/bottom insets
    width += insets.right
    height += insets.bottom

    let artboardColor = UIColor(white: 245/255.0, alpha: 1.0).makeSketchColor()
    return Artboard(name: artboardName, layers: groups, frame: CGRect(x: 0, y: 0, width: width, height: height), color: artboardColor)
  }

  /// Take 2d-array of any LayerContainers, lay out them in 2d in space starting from origin (0,0).
  /// Return the array of LayerContainers with frame modified.
  ///
  /// Usually use it to arrange [[Artboard]] and [[Group]].
  ///
  /// - Parameters:
  ///   - isFirstAxisHorizontal: If `true` (default), the first axis of `layers` moves along X axis. This is opposite of our general 2d intuition,
  /// which first axis moves along Y axis. TODO: Consider refactor this. I forgot why we chose to go this way at the beginning...
  public static func arrange<T: LayerContainer>(layers: [[T]], verticalPadding: CGFloat = 20.0, horizontalPadding: CGFloat = 20.0, isFirstAxisHorizontal: Bool = true) -> [T] {

    if isFirstAxisHorizontal {
      var x: CGFloat = 0
      // Moves horizontall
      layers.forEach { (gs) in
        var y: CGFloat = 0
        var nextStackX = x

        // Moves vertically
        gs.forEach({ (g) in
          let w = g.frame.width
          let h = g.frame.height
          g.frame = CGRect(x: x, y: y, width: w, height: h)
          y += (h + verticalPadding)
          nextStackX = max(nextStackX, x + w)
        })
        x = nextStackX + horizontalPadding
      }
      return layers.flatMap { $0 }
    } else {
      var y: CGFloat = 0

      // Moves vertically
      layers.forEach { (gs) in
        var x: CGFloat = 0
        var nextStackY = y

        // Moves horizontally
        gs.forEach({ (g) in
          let w = g.frame.width
          let h = g.frame.height
          g.frame = CGRect(x: x, y: y, width: w, height: h)
          x += (w + horizontalPadding)
          nextStackY = max(nextStackY, y + h)
        })
        y = nextStackY + verticalPadding
      }
      return layers.flatMap { $0 }
    }
  }

  public static func makeGroup(view: UIView, name: String) -> Group {
    // Create a Group
    let group = view.makeSketchGroup()

    return Group(frame: group.frame, layers: group.layers, alpha: group.alpha, name: name, shadow: group.shadow)
  }
}
