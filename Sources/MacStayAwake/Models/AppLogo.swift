import AppKit

@MainActor
enum AppLogo {
    // The packaged app carries this resource directly; SwiftPM tests and tools
    // use the package resource bundle. Both load the same alpha silhouette.
    static let templateImage: NSImage = {
        let url = Bundle.main.url(forResource: "CoffeeMark", withExtension: "png")
            ?? Bundle.module.url(forResource: "CoffeeMark", withExtension: "png")
        guard let url, let image = NSImage(contentsOf: url) else {
            preconditionFailure("CoffeeMark.png is missing from the app resources")
        }
        image.isTemplate = true
        return image
    }()

    static let menuBarImage: NSImage = {
        let image = templateImage.copy() as! NSImage
        image.size = NSSize(width: 20, height: 20)
        return image
    }()
}
