import SwiftUI

struct PostcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    let postcard: Postcard

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 18) {
                header

                PostcardArtwork(
                    postcard: postcard,
                    senderName: senderName,
                    animalId: tripForPostcard?.animalId,
                    destination: destinationForPostcard
                )

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

            RenderedShareLink(
                title: "\(postcard.destination)明信片",
                filename: "bulu-postcard-\(postcard.id).png",
                accessibilityLabel: AppCopy.Share.postcardAccessibilityLabel
            ) {
                PostcardShareImage(
                    postcard: postcard,
                    senderName: senderName,
                    animalId: tripForPostcard?.animalId,
                    destination: destinationForPostcard
                )
            }
        }
    }

    private var senderName: String {
        if let trip = tripForPostcard {
            return environment.repository.animalName(for: trip.animalId)
        }
        return postcard.titleSenderNameFallback
    }

    private var tripForPostcard: Trip? {
        environment.repository.trips.first { $0.id == postcard.tripId }
    }

    private var destinationForPostcard: ManifestDestination? {
        if let trip = tripForPostcard,
           let destination = environment.destination(for: trip) {
            return destination
        }
        return environment.destinations.first {
            $0.displayName == postcard.destination ||
                $0.landmarkAssetName == postcard.destinationAssetName
        }
    }
}

struct PostcardShareImage: View {
    let postcard: Postcard
    let senderName: String
    let animalId: String?
    let destination: ManifestDestination?

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 5) {
                Text("来自\(postcard.destination)的明信片")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text("\(senderName)寄来的远方来信")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.top, 2)

            PostcardArtwork(
                postcard: postcard,
                senderName: senderName,
                animalId: animalId,
                destination: destination,
                showsShadow: false
            )
            .frame(width: 252)
            .shadow(color: AppTheme.oliveInk.opacity(0.08), radius: 10, x: 0, y: 5)

            ShareBrandFooter()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(width: ShareImageRenderer.pointSize.width, height: ShareImageRenderer.pointSize.height)
        .background(ShareCanvasBackground())
    }
}

struct PostcardArtwork: View {
    let postcard: Postcard
    let senderName: String
    let animalId: String?
    let destination: ManifestDestination?
    var showsShadow: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                ArtImage(name: "postcard_base_portrait", contentMode: .fill, cornerRadius: 24, showsShadow: showsShadow)
                    .frame(width: size.width, height: size.height)
                    .clipped()

                ArtImage(name: edgeArtworkName, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .opacity(0.86)

                ArtImage(name: destinationArtworkName, contentMode: .fill, cornerRadius: 14)
                    .frame(width: size.width * 0.870, height: size.height * 0.292)
                    .clipped()
                    .position(x: size.width * 0.5, y: size.height * 0.302)

                ArtImage(name: motifArtworkName)
                    .frame(width: size.width * 0.132, height: size.width * 0.132)
                    .rotationEffect(.degrees(9))
                    .opacity(0.72)
                    .position(x: size.width * 0.170, y: size.height * 0.115)

                ArtImage(name: stampArtworkName)
                    .frame(width: size.width * 0.167, height: size.width * 0.167)
                    .rotationEffect(.degrees(-12))
                    .opacity(0.78)
                    .position(x: size.width * 0.843, y: size.height * 0.109)

                VStack(alignment: .leading, spacing: 10) {
                    Text(senderLine)
                        .font(AppTheme.postcardTitle(size: 21))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                    Text(postcard.body)
                        .font(AppTheme.postcardBody(size: 17))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(6)
                        .lineLimit(8)
                        .minimumScaleFactor(0.82)
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

    private var destinationArtworkName: String {
        if let destinationId = destination?.id,
           let cityArtwork = Self.cityDestinationArtwork[destinationId] {
            return cityArtwork
        }
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
            if postcard.destinationAssetName != "postcard_destination_city_generic" {
                return postcard.destinationAssetName
            }
            return Self.archetypeArtworkName(for: destination)
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

    private var edgeArtworkName: String {
        "postcard_edge_\(animalStyleKey)"
    }

    private var motifArtworkName: String {
        "postcard_motif_\(animalStyleKey)"
    }

    private var animalStyleKey: String {
        if let animalId,
           Self.supportedAnimalStyleKeys.contains(animalId) {
            return animalId
        }
        if let inferred = Self.animalStyleByAssetName[postcard.animalAssetName] {
            return inferred
        }
        return "xiaoman_hamster"
    }

    static let supportedAnimalStyleKeys: Set<String> = [
        "xiaoman_hamster",
        "tangyuan_puppy",
        "moji_cat",
        "dengdeng_rabbit",
        "feifei_parrot",
        "xiaolu_guinea_pig",
        "deer_visitor",
        "fox_visitor",
        "bear_visitor",
    ]

    static let animalStyleByAssetName: [String: String] = [
        "animal_home_xiaoman_hamster": "xiaoman_hamster",
        "animal_home_tangyuan_puppy": "tangyuan_puppy",
        "animal_home_moji_cat": "moji_cat",
        "animal_home_dengdeng_rabbit": "dengdeng_rabbit",
        "animal_home_feifei_parrot": "feifei_parrot",
        "animal_home_xiaolu_guinea_pig": "xiaolu_guinea_pig",
        "animal_home_jiujiu_deer": "deer_visitor",
        "animal_home_aini_fox": "fox_visitor",
        "animal_home_dundun_bear": "bear_visitor",
    ]

    static let cityDestinationArtwork: [String: String] = [
        "cn_beijing": "postcard_destination_city_beijing",
        "cn_shanghai": "postcard_destination_city_shanghai",
        "jp_tokyo": "postcard_destination_city_tokyo",
        "jp_kyoto": "postcard_destination_city_kyoto",
        "kr_seoul": "postcard_destination_city_seoul",
        "cn_hongkong": "postcard_destination_city_hongkong",
        "sg_singapore": "postcard_destination_city_singapore",
        "fr_paris": "postcard_destination_city_paris",
        "uk_london": "postcard_destination_city_london",
        "it_rome": "postcard_destination_city_rome",
        "it_venice": "postcard_destination_city_venice",
        "es_barcelona": "postcard_destination_city_barcelona",
        "nl_amsterdam": "postcard_destination_city_amsterdam",
        "us_new_york": "postcard_destination_city_new_york",
        "us_los_angeles": "postcard_destination_city_los_angeles",
        "us_san_francisco": "postcard_destination_city_san_francisco",
        "ca_vancouver": "postcard_destination_city_vancouver",
        "au_sydney": "postcard_destination_city_sydney",
        "au_melbourne": "postcard_destination_city_melbourne",
        "tr_istanbul": "postcard_destination_city_istanbul",
        "eg_cairo": "postcard_destination_city_cairo",
        "br_rio": "postcard_destination_city_rio",
        "za_cape_town": "postcard_destination_city_cape_town",
        "is_reykjavik": "postcard_destination_city_reykjavik",
    ]

    static func archetypeArtworkName(for destination: ManifestDestination?) -> String {
        guard let destination else {
            return "postcard_destination_archetype_east_asia_city"
        }
        let id = destination.id
        let country = destination.countryOrRegion ?? ""
        let continent = destination.continent ?? ""

        if id.hasPrefix("jp_") || id.hasPrefix("kr_") || id.hasPrefix("cn_") || id.hasPrefix("sg_") {
            return "postcard_destination_archetype_east_asia_city"
        }
        if id.hasPrefix("is_") || id.hasPrefix("no_") || id.hasPrefix("fi_") || id.hasPrefix("se_") || id.hasPrefix("ca_") {
            return "postcard_destination_archetype_snow"
        }
        if id.hasPrefix("eg_") || id.hasPrefix("ma_") || id.hasPrefix("ae_") || id.hasPrefix("qa_") {
            return "postcard_destination_archetype_desert"
        }
        if id.hasPrefix("br_") || id.hasPrefix("th_") || id.hasPrefix("id_") || id.hasPrefix("my_") {
            return "postcard_destination_archetype_tropical"
        }
        if id.hasPrefix("au_") || id.hasPrefix("nz_") {
            return "postcard_destination_archetype_oceania_coast"
        }
        if id.hasPrefix("us_") || id.hasPrefix("mx_") {
            return "postcard_destination_archetype_north_america_street"
        }
        if country.contains("土耳其") || country.contains("埃及") || continent == "Africa" {
            return "postcard_destination_archetype_historic_market"
        }
        if continent == "Europe" || continent == "Europe/Asia" {
            return "postcard_destination_archetype_european_old_town"
        }
        if continent == "Oceania" {
            return "postcard_destination_archetype_oceania_coast"
        }
        if continent == "North America" {
            return "postcard_destination_archetype_north_america_street"
        }
        if continent == "South America" {
            return "postcard_destination_archetype_tropical"
        }
        return "postcard_destination_archetype_modern_skyline"
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
