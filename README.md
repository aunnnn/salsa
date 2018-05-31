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

----
# Salsa (Original README.md)

## What is Salsa?
Salsa is an open source library that renders iOS views and exports them into a Sketch file. We built Salsa to help bridge the gap between design and engineering in an effort to create a single source of truth for visual styling of UI.

## How it works
Running Salsa inside of an iOS simulator will output two things into a specified directory: a .salsa file and an images folder. You can then pass these two inputs into the salsa command line tool to compile them into a .sketch file.

### Why two steps?
Certain macOS-only APIs need to be used to encode text for .sketch files. Having two steps allows us to define our own intermediate file format that’s easier to work with than the full sketch file format. This means we can leverage this file format in the future if we want to expand this tool for other platforms.

# Installing Salsa
```ruby
pod 'Salsa'
```

```bash
brew tap yelp/salsa
brew install salsa
```

# Using Salsa
```swift
import Salsa
```
##### Converting a view to a [Sketch Group](https://www.sketchapp.com/docs/grouping/groups/)
```swift
// Configure the export directory
SalsaConfig.exportDirectory = "/some_directory"

// Convert a view into a group
let myGroup = myView.makeSketchGroup()
```
##### Putting a group into a sketch document and exporting to a salsa file
```swift
// Create a page containing the generated group, and insert it into a Document
let document = Document(pages: [Page(layers: [myGroup])])

// Export the document to disk
try? document.export(fileName: "my_file")
```

##### Converting a salsa file to a sketch file
In your terminal of choice run the following:
```bash
$ salsa -f /some_directory/my_file.salsa -e /some_directory/my_file.sketch
```

## Creating a Sketch file documenting your standard UI elements
We provide some helpers to help you document your elements out of the box. You organize examples of your views into an [Artboard](https://www.sketchapp.com/docs/grouping/artboards/) by conforming your view class to [`ArtboardRepresentable`](https://yelp.github.io/salsa/Protocols/ArtboardRepresentable.html).
```swift
extension View1: ArtboardRepresentable {
  static func artboardElements() -> [[ArtboardElement]] {
    ...
  }
}
```
If you would like to also create [Symbols](https://sketchapp.com/docs/symbols/) of your views to go along with the generated Artboards you can instead conform your views to [`SymbolRepresentable`](https://yelp.github.io/salsa/Protocols/SymbolRepresentable.html).

```swift
extension View2: SymbolRepresentable {
  static func artboardElements() -> [[ArtboardElement]] {
    ...
  }
}
```
Create your Artboards and Symbols from these [`ArtboardRepresentable`](https://yelp.github.io/salsa/Protocols/ArtboardRepresentable.html)  and [`SymbolRepresentable`](https://yelp.github.io/salsa/Protocols/SymbolRepresentable.html) views
```swift
// Configure the export directory
SalsaConfig.exportDirectory = "/some_directory"

// Generate the artboards and symbols
let artboardsAndSymbols = makeArtboardsAndSymbols(from: [[View1.self], [View2.self]])

// Put the artboards and symbols onto their own dedicated pages
let artboardPage = Page(name: "Artboards", layers: artboardsAndSymbols.artboards)
let symbolPage = Page(name: "Symbols", layers: artboardsAndSymbols.symbols)

// Create a document with the generated pages and export it
let document = Document(pages: [artboardPage, symbolPage])
try? document.export(fileName: "my_file")
```

## Example Project
Check out the Example project to see how Sasla can be used in production. The Example app uses a test target to generate Sketch files without manually launching Xcode.  

To generate a Sketch file for the Example project run the following after cloning the repo:
```bash
cd Example
pod install
./generate_sketch
```
This should create a new file called `ExampleSketch.sketch` inside the project directory

Open up [`generate_sketch`](https://github.com/Yelp/salsa/blob/master/Example/generate_sketch) with a text editor to see how this is done.

## Documentation
For a full breakdown of the Salsa API [check out the docs](https://yelp.github.io/salsa/index.html)
