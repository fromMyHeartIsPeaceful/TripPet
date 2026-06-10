import SwiftUI

struct PostcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let postcard: Postcard

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 18) {
                header

                PostcardArtwork(postcard: postcard)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    ArtImage(name: "icon_back", isDecorative: false)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(AppTheme.ink)
                    Text("返回")
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("返回邮箱")
            Spacer()
        }
    }
}

private struct PostcardArtwork: View {
    let postcard: Postcard

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                ArtImage(name: postcard.templateAssetName, cornerRadius: 24, showsShadow: true)
                    .frame(width: size.width, height: size.height)

                ArtImage(name: postcard.destinationAssetName)
                    .frame(width: size.width * 0.86, height: size.height * 0.53)
                    .position(x: size.width * 0.5, y: size.height * 0.31)

                ArtImage(name: postcard.stampAssetName)
                    .frame(width: size.width * 0.15, height: size.width * 0.15)
                    .rotationEffect(.degrees(-12))
                    .opacity(0.58)
                    .position(x: size.width * 0.82, y: size.height * 0.73)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(postcard.destination)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text(postcard.subtitle)
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer(minLength: 10)
                        Text(postcard.sentAt, style: .date)
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    Text(displayTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(postcard.body)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(5)
                        .lineLimit(5)
                        .minimumScaleFactor(0.86)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: size.width * 0.78, height: size.height * 0.28, alignment: .topLeading)
                .position(x: size.width * 0.45, y: size.height * 0.79)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayTitle)，来自\(postcard.destination)，\(postcard.subtitle)，\(postcard.body)")
    }

    private var displayTitle: String {
        postcard.title == "小猫寄来的自拍" ? "小猫寄来的明信片" : postcard.title
    }

}

#Preview("Postcard Paris") {
    PostcardDetailView(postcard: SeedData.previewPostcards[0])
}

#Preview("Postcard Iceland") {
    PostcardDetailView(postcard: SeedData.previewPostcards[1])
}
