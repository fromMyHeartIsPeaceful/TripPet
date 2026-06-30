import SwiftUI
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

struct ArtImage: View {
    enum ContentMode {
        case fit
        case fill

        var swiftUIContentMode: SwiftUI.ContentMode {
            switch self {
            case .fit:
                return .fit
            case .fill:
                return .fill
            }
        }
    }

    var name: String
    var contentMode: ContentMode = .fit
    var isDecorative: Bool = true
    var cornerRadius: CGFloat = 0
    var showsShadow: Bool = false

    var body: some View {
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .renderingMode(name.hasPrefix("icon_") ? .template : .original)
                    .aspectRatio(contentMode: contentMode.swiftUIContentMode)
            } else {
                fallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: AppTheme.oliveInk.opacity(showsShadow ? 0.12 : 0), radius: 8, x: 0, y: 4)
        .accessibilityHidden(isDecorative)
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.cornerRadius), style: .continuous)
                .fill(AppTheme.ivory)
            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.cornerRadius), style: .continuous)
                .stroke(AppTheme.paperGray, style: StrokeStyle(lineWidth: AppTheme.hairline, dash: [6, 6]))

            #if DEBUG
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(6)
            #else
            Image(systemName: "photo")
                .foregroundStyle(AppTheme.paperGray)
            #endif
        }
    }
}

struct DashedPlaceholder: View {
    var title: String

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .stroke(
                AppTheme.ink,
                style: StrokeStyle(lineWidth: AppTheme.hairline, dash: [6, 6])
            )
            .overlay {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
    }
}

struct StepCounterView: View {
    static let defaultLimit = 3000

    let value: Int
    var limit: Int = defaultLimit
    var fontSize: CGFloat = 30

    static func displayText(value: Int, limit: Int = defaultLimit) -> String {
        let clampedValue = max(value, 0)
        return String(format: "%04d", clampedValue)
    }

    private var clampedLimit: Int {
        max(0, limit)
    }

    private var digits: [Int] {
        Self.displayText(value: value, limit: clampedLimit).compactMap { Int(String($0)) }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(Self.displayText(value: value, limit: clampedLimit))
                .foregroundStyle(AppTheme.ink)

            Text("/" + String(clampedLimit))
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .font(.system(size: fontSize, weight: .heavy, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: true, vertical: false)
        .contentTransition(.numericText())
        .animation(.easeOut(duration: 0.28), value: digits)
        .accessibilityLabel("今天的步数 \(Self.displayText(value: value, limit: clampedLimit)) / \(clampedLimit)")
    }
}

struct RollingDigitView: View {
    let digit: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.paperWhite.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.paperGray.opacity(0.78), lineWidth: AppTheme.hairline)
                )

            Text("\(digit)")
                .id(digit)
                .font(.system(size: 30, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.ink)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
        }
        .frame(width: 28, height: 40)
        .clipped()
    }
}

struct ShareablePNG: Transferable, Equatable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.data
        }
        .suggestedFileName { item in
            item.filename
        }
    }

    var previewImage: Image {
        if let image = UIImage(data: data) {
            return Image(uiImage: image)
        }
        return Image(systemName: "photo")
    }
}

enum ShareImageRenderer {
    static let pointSize = CGSize(width: 360, height: 640)
    static let scale: CGFloat = 3

    @MainActor
    static func makePNG<Content: View>(
        filename: String,
        @ViewBuilder content: () -> Content
    ) -> ShareablePNG? {
        guard let data = pngData(content: content) else {
            return nil
        }
        return ShareablePNG(data: data, filename: filename)
    }

    @MainActor
    static func pngData<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> Data? {
        let renderedContent = content()
            .frame(width: pointSize.width, height: pointSize.height)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: renderedContent)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(pointSize)
        return renderer.uiImage?.pngData()
    }
}

struct RenderedShareLink<Content: View>: View {
    let title: String
    let filename: String
    let accessibilityLabel: String
    @ViewBuilder var content: () -> Content

    @State private var item: ShareablePNG?

    var body: some View {
        Group {
            if let item {
                ShareLink(
                    item: item,
                    preview: SharePreview(title, image: item.previewImage)
                ) {
                    shareLabel
                }
            } else {
                Button {} label: {
                    shareLabel
                }
                .disabled(true)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .task(id: filename) {
            item = ShareImageRenderer.makePNG(filename: filename) {
                content()
            }
        }
    }

    private var shareLabel: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .frame(width: 36, height: 36)
            .background(AppTheme.ivory)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.paperGray, lineWidth: AppTheme.hairline)
            )
    }
}

struct ShareCanvasBackground: View {
    var body: some View {
        AppTheme.paperWhite
            .overlay {
                ArtImage(name: "texture_paper_grain", contentMode: .fill)
                    .opacity(0.08)
            }
    }
}

struct ShareBrandFooter: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("share_app_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.Share.appName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(AppCopy.Share.promo)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.82)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.ivory.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.paperGray.opacity(0.72), lineWidth: AppTheme.hairline)
        )
    }
}
