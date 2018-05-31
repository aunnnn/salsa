# Salsa+AutoSketch

## What's Salsa? What's AutoSketch?
[Salsa](https://github.com/Yelp/salsa) exports iOS views to a Sketch file, to help communication between design and engineering.

AutoSketch is an experimental project, built on top of the hard work of Salsa, with the goal that such Sketch file could be a visual documentation of iOS apps. New developers in the team can browse the Sketch Artboard of various pages captured from the live app ("stuffed view hierarchy") and can easily figure out which views belong to which `UIView` subclass.

To do this AutoSketch:
1. Modify Salsa code to allow it to capture Groups/Artboard from instance of live views (*instead of making new views for capturing purpose in a static function*)
2. Modify Salsa Compiller to not purging/filtering out any private views.
3. Use `type(of: self)` as view's group name.
Check out `Salsa+AutoSketch.swift`.

AutoSketch also adds: 
```swift
public func artboardSession(name: String, sessionHandler: (ArtboardSession) -> Void) -> Artboard
```
to make it easy to generate Artboard with `name`. You can use `ArtboardSession` to snap views:
```swift
public func snapWindow(name: String) // name is group name, might use group name as view controller subclass, to make it easy to find
public func snapView(_ view: UIView, name: String)
```
All snapped views in a session will be shown horizontally in an artboard.

## To use AutoSketch in practice
You will combine it with your UI automation test framework of your choice. I used EarlGrey, and built some convenience functions [here.](https://github.com/aunnnn/EarlGrey-Convenience)

It's a unit testing that can do UI automation. That means we have full access of our app code which allows us to snap live views as we navigate through the app!

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
    
    let allTabBarsFlow = artboardSession(name: "Home TabBars") { (s) in
      s.snapWindow(name: "Menu")
      tap(id: "Exclusives")
      waitUntilLoadingFinish()
      s.snapWindow(name: "Exclusives")

      tap(id: "Tracker")
      waitUntilLoadingFinish()
      s.snapWindow(name: "Tracker")
      
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

Great thing with the white-box UI automation is that you can get the keyWindow, get its active view controller, get its button/view/label, then set an accessibility identifier, then tap on that id directly! No need to go through your app's code and add accessbility identifier all over the places. Set and use it just-in-time.

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
