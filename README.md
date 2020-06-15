# Pager - Allows you to host multiple pages of content in a pure SwiftUI component.

Simple paging control to be used in SwiftUI projects without having to depend on the one provided by UIKit.

## Notes
It supports iOS 13, watchOS 6 and macOS 10.15. Haven't tested on tvOS device.

# Sample

Let's imagine you have created three different views you want to display (let's say onboarding purposes or a watchOS app).

```swift
struct Page1View: View {
    var body: some View {
        VStack(alignment: .top) { 
            Text("Here goes the first page!")
            Spacer()
            Text("That's all...")
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Page2View: View {
    var body: some View {
        Text("Nothing fancy for a second page.")
    }
}

struct Page3View: View {
    var body: some View {
        Text("Yet another simple page...")
    }
}
```

To host all of these views you will need to create a pager and specify each of the views you need.

```swift
struct HostView: View {
    var body: some View {
        Pager {
            [ // The pager requires a list of views as its view builder.
                AnyView(Page1View()),
                AnyView(Page2View()),
                AnyView(Page3View())
            ]
        }
    }
}
```

And that is all, the views will be loaded once the Pager is loaded.