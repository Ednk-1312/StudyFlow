//
//  PlatformSupport.swift
//  StudyOS
//
//  Small platform abstraction so shared views compile and behave on both
//  iOS and macOS without scattering #if through every file.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
/// Cross-platform image backing type (UIImage on iOS, NSImage on macOS).
/// Both expose an optional `cgImage`, which is what Vision consumes.
public typealias PlatformImage = UIImage

extension Image {
    /// Cross-platform image view from a captured or imported image.
    init(platformImage: PlatformImage) {
        self.init(uiImage: platformImage)
    }
}

extension PlatformImage {
    /// Optional CGImage for Vision pipelines (forwards to UIImage.cgImage).
    var cgImageOrNil: CGImage? { cgImage }
}

extension Color {
    init(platformColor: UIColor) { self.init(uiColor: platformColor) }

    static var platformTertiaryFill: Color { Color(uiColor: .tertiarySystemFill) }
    static var platformSecondaryGroupedBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var platformSecondarySystemBackground: Color { Color(uiColor: .secondarySystemBackground) }
    static var platformSeparator: Color { Color(uiColor: .separator) }
    static var platformSystemGroupedBackground: Color { Color(uiColor: .systemGroupedBackground) }
}
#elseif canImport(AppKit)
public typealias PlatformImage = NSImage

extension Image {
    init(platformImage: PlatformImage) {
        self.init(nsImage: platformImage)
    }
}

extension PlatformImage {
    /// NSImage.cgImage is a method on macOS; normalize it to a property.
    var cgImageOrNil: CGImage? { cgImage(forProposedRect: nil, context: nil, hints: nil) }
}

extension Color {
    init(platformColor: NSColor) { self.init(nsColor: platformColor) }

    static var platformTertiaryFill: Color { Color(nsColor: .quaternarySystemFill) }
    static var platformSecondaryGroupedBackground: Color { Color(nsColor: .controlBackgroundColor) }
    static var platformSecondarySystemBackground: Color { Color(nsColor: .controlBackgroundColor) }
    static var platformSeparator: Color { Color(nsColor: .separatorColor) }
    static var platformSystemGroupedBackground: Color { Color(nsColor: .windowBackgroundColor) }
}
#endif

#if os(macOS)
extension View {
    /// Standard content sizing for sheets presented on macOS — without it,
    /// sheets open at the child's cramped ideal size instead of a usable form width.
    func macSheetSizing() -> some View {
        frame(minWidth: 460, idealWidth: 560, minHeight: 320)
    }
}
#else
extension View {
    /// No-op on iOS/touch platforms.
    func macSheetSizing() -> some View {
        self
    }
}
#endif

#if os(macOS)
/// SwiftUI's `.keyboardType` modifier is iOS-only; shared form code keeps the
/// same spelling on both platforms, and macOS (physical keyboard) ignores it.
enum PlatformKeyboardType {
    case decimalPad
    case numberPad
}

extension View {
    func keyboardType(_ type: PlatformKeyboardType) -> some View {
        self
    }
}

// MARK: - iOS-only SwiftUI API shims

/// `.navigationBarTitleDisplayMode` is iOS-only. Shadow it with a no-op on
/// macOS, where the window toolbar already uses a single title style.
enum PlatformTitleDisplayMode {
    case automatic
    case inline
    case large
}

extension View {
    func navigationBarTitleDisplayMode(_ displayMode: PlatformTitleDisplayMode) -> some View {
        self
    }
}

/// `.insetGrouped` is iOS-only; the closest macOS equivalent is the standard
/// inset list style.
extension ListStyle where Self == InsetListStyle {
    static var insetGrouped: InsetListStyle { .init() }
}

/// iOS toolbar placements map onto the nearest macOS equivalents: leading
/// items join the navigation area, trailing items take the default (trailing)
/// toolbar position.
extension ToolbarItemPlacement {
    static var topBarLeading: ToolbarItemPlacement { .navigation }
    static var topBarTrailing: ToolbarItemPlacement { .automatic }
}
#endif
