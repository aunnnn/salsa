# Salsa+AutoSketch

[Medium article](https://blog.oozou.com/documenting-ios-apps-visually-e8736b431cf7)

## What is Salsa?
[Salsa](https://github.com/Yelp/salsa) exports iOS views to a Sketch file, to help communication between design and engineering.

## What is AutoSketch?
AutoSketch is an experimental project built on top of Salsa. It snaps full view hierarchies from a running app, and exports them to Sketch groups as UI automation navigates through the app. In the end we will have a Sketch file that mirrors various pages in the app, like a visual documentation. They can browse through the file to know which view belongs to which UIView subclass in the project.

## How it's done
To do this AutoSketch:
1. Add wrappers around Salsa code for capturing Groups/Artboard from instance of views (originally we make new views specially for capturing purpose in a static function).
2. Remove purging/filtering any private views out from Salsa Compiler.
3. Use view class name as Sketch group name (`type(of: self)`).

Check out [`Salsa+AutoSketch.swift`](https://github.com/aunnnn/salsa-AutoSketch/blob/master/Salsa/Salsa%2BAutoSketch.swift) for the additional wrapper.

AutoSketch adds `artboardSession` utility function that wraps around Salsa to make it easy to generate Artboard in one go:
```swift
public func artboardSession(name: String, sessionHandler: (ArtboardSession) -> Void) -> Artboard
```

`ArtboardSession` can be used to snap views or windows:

```swift
public func snapWindow(name: String) // name is group name, might use group name as view controller subclass, to make it easy to find
```
```swift
public func snapView(_ view: UIView, name: String)
```
All snapped views in a session will be shown horizontally in an artboard.
Checkout [`ArtboardSession.swift`](https://github.com/aunnnn/salsa-AutoSketch/blob/master/Salsa/ArtboardSession.swift)

## Example
You will use it with UI automation test framework of your choice. I used EarlGrey, and wrote [some convenience functions here.](https://github.com/aunnnn/EarlGrey-Convenience)

Basically, it is unit testing that can do UI automation. That means we have full access of our app code which allows us to snap live views as we navigate through the app!

Sample code:

```swift
import XCTest // Unit test
import EarlGrey // UI Automation
import Salsa // View-to-Sketch
@testable import YourApp // Your app

class AutoSketchTest: XCTestCase {

  func setup() {
    super.setup()
    SalsaConfig.exportDirectory = "/tmp/yourApp"
  }
  
  func waitUntilLoadingFinish() {
      waitUntilElementIsGone(id: "SVProgressHUD")
  }
    
  func testSnap() {
    makeSureKeyWindowVisible()
    
    let allTabBarsFlow = artboardSession(name: "TabBars") { (s) in
      tap(id: "Tab1")
      waitUntilLoadingFinish()
      s.snapWindow(name: "Tab 1")

      tap(id: "Tab2")
      waitUntilLoadingFinish()
      s.snapWindow(name: "Tab 2")
      
      ...
    }
    
    // Stack all artboards vertically, you can arrange it how you want in 2d space with 2d array
    let artboards = AutoSketch.arrange(layers: [[allTabBarsFlow, ...]], verticalPadding: 200, horizontalPadding: 200)
    let page = Page(name: "Artboards", layers: artboards)
    let document = Document(pages: [page], colors: [], textStyles: [])

    do {
      try document.export()
    } catch let error {
      XCTFail("Failed to export file: \(error)")
    }
  }  
}
```

Great thing with the white-box UI automation is that you can get the keyWindow, its active view controller, its button/view/label instances, then set accessibility identifiers on them and tap on those identifiers directly. No need to go through your app's code and add accessbility identifier all over the places. Set and use it just-in-time.

## Installation
1. Clone the repo.
2. Add `Salsa` to your Podfile that refers to this repo:
```ruby
pod 'Salsa', :path => '~/path/to/downloaded/salsa'
```
Or you can try using `:git => 'https://github.com/aunnnn/salsa-AutoSketch.git'`, I never used this way though.
3. Build Salsa-Complier target. You will get the command-line program for that in the product folder. You will use this to generate Sketch file instead of the original one from `brew`. The original one generates simplified Sketch and trims many prviate views, this one generates full view hierarchy, for debugging purpose.
4. Do automation test, e.g. with EarlGrey. Snap views as shown in the sample testcase. If you do the export right, you will get `generate.salsa` files at the `SalsaConfig.exportDirectory` (e.g., `/tmp/YourApp`).
5. Use the salsa compiler you built (that command-line program) to convert generate.salsa (`/tmp/YourApp`) to a Sketch file. Make sure you have installed any custom fonts you use on the app, on your Mac again as well, else it will crash with font not found.

## Original Salsa Repo
https://github.com/Yelp/salsa
