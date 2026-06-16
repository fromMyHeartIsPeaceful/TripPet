import SwiftUI

struct PostcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @State private var isHandlingReturn = false
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
                guard isHandlingReturn == false else { return }
                isHandlingReturn = true
                Task {
                    await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    ArtImage(name: "icon_back", isDecorative: false)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(AppTheme.ink)
                    Text("返回")
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .disabled(isHandlingReturn)
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
                ArtImage(name: "postcard_base_portrait", contentMode: .fill, cornerRadius: 24, showsShadow: true)
                    .frame(width: size.width, height: size.height)
                    .clipped()

                ArtImage(name: destinationArtworkName, contentMode: .fill, cornerRadius: 14)
                    .frame(width: size.width * 0.870, height: size.height * 0.292)
                    .clipped()
                    .position(x: size.width * 0.5, y: size.height * 0.302)

                ArtImage(name: stampArtworkName)
                    .frame(width: size.width * 0.167, height: size.width * 0.167)
                    .rotationEffect(.degrees(-12))
                    .opacity(0.78)
                    .position(x: size.width * 0.843, y: size.height * 0.109)

                VStack(alignment: .leading, spacing: 10) {
                    Text(senderLine)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(postcard.body)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: size.width * 0.778, alignment: .leading)
                .position(x: size.width * 0.5, y: size.height * 0.647)
            }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(postcard.destination)明信片，\(postcard.subtitle)")
    }

    private var senderLine: String {
        "\(senderName)从\(postcard.destination)寄来"
    }

    private var senderName: String {
        guard let range = postcard.title.range(of: "寄来") else {
            return "小动物"
        }
        let name = postcard.title[..<range.lowerBound]
        return name.isEmpty ? "小动物" : String(name)
    }

    private var destinationArtworkName: String {
        switch postcard.destinationAssetName {
        case "destination_paris_line", "postcard_portrait_destination_paris":
            return "postcard_destination_paris"
        case "destination_iceland_line", "postcard_portrait_destination_reykjavik":
            return "postcard_destination_reykjavik"
        case "destination_lisbon_line", "postcard_portrait_destination_lisbon":
            return "postcard_destination_lisbon"
        case "postcard_airport_first_departure", "postcard_portrait_destination_airport":
            return "postcard_destination_airport"
        default:
            return postcard.destinationAssetName
        }
    }

    private var stampArtworkName: String {
        switch postcard.stampAssetName {
        case "stamp_paris", "postcard_portrait_stamp_paris":
            return "postcard_stamp_paris"
        case "stamp_iceland", "postcard_portrait_stamp_reykjavik":
            return "postcard_stamp_reykjavik"
        case "stamp_lisbon", "postcard_portrait_stamp_lisbon":
            return "postcard_stamp_lisbon"
        case "stamp_airport_first_departure", "postcard_portrait_stamp_airport":
            return "postcard_stamp_airport"
        default:
            return postcard.stampAssetName
        }
    }

}

#Preview("Postcard Paris") {
    PostcardDetailView(postcard: SeedData.preview.postcards[0])
        .environmentObject(AppEnvironment.preview())
}

#Preview("Postcard Iceland") {
    PostcardDetailView(postcard: SeedData.preview.postcards[1])
        .environmentObject(AppEnvironment.preview())
}
