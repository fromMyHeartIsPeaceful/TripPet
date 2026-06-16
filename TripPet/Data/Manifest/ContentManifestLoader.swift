import Foundation

enum ContentManifestLoader {
    private static let catalogResourceName = "LocationDestinationCatalog"

    static func load(bundle: Bundle = .main) -> ContentManifest? {
        guard let url = bundle.url(forResource: "ContentManifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(ContentManifest.self, from: data)
    }

    static func loadSeedData(bundle: Bundle = .main, fallback: SeedData = .preview) -> SeedData {
        guard let manifest = load(bundle: bundle) else {
            return fallback
        }

        var seed = SeedData(manifest: manifest)
        seed.destinations = mergeDestinations(
            manifestDestinations: seed.destinations,
            catalogDestinations: loadCatalogDestinations(bundle: bundle)
        )
        return seed
    }

    static func loadTicketRuleEngine(bundle: Bundle = .main, fallback: TicketRuleEngine = TicketRuleEngine()) -> TicketRuleEngine {
        guard let manifest = load(bundle: bundle) else {
            return fallback
        }

        return TicketRuleEngine(
            requiredStepsPerTicket: manifest.rules.stepsPerTicket,
            dailyTicketLimit: manifest.rules.dailyTicketLimit
        )
    }

    static func loadDestinations(bundle: Bundle = .main) -> [ManifestDestination] {
        let fallback = [
            ManifestDestination(
                id: "paris",
                displayName: "巴黎",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎早安",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "清晨的巴黎还没有完全醒来。{animal}在远远能看见铁塔的街角停了一会儿，把面包香、石板路上的光和一点点风，都轻轻收进了这张明信片。"
            ),
            ManifestDestination(
                id: "iceland",
                displayName: "冰岛",
                landmarkAssetName: "destination_iceland_line",
                stampAssetName: "stamp_iceland",
                routeMapAssetName: "trip_route_map_iceland",
                primaryColor: "#A9C9D8",
                postcardTitleTemplate: "{animal}寄来的风声",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "冰岛的云压得很低，路边的灯像一粒小小的星。{animal}把围巾裹紧，听见风从黑色海岸跑过去，于是给小屋寄回这一点安静的远方。"
            )
        ]
        return mergeDestinations(
            manifestDestinations: load(bundle: bundle)?.destinations ?? fallback,
            catalogDestinations: loadCatalogDestinations(bundle: bundle)
        )
    }

    static func loadCatalogDestinations(bundle: Bundle = .main) -> [ManifestDestination] {
        guard let url = bundle.url(forResource: catalogResourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(LocationDestinationCatalog.self, from: data) else {
            return []
        }

        return catalog.destinations
    }

    static func mergeDestinations(
        manifestDestinations: [ManifestDestination],
        catalogDestinations: [ManifestDestination]
    ) -> [ManifestDestination] {
        guard catalogDestinations.isEmpty == false else {
            return manifestDestinations
        }

        var mergedById = Dictionary(
            uniqueKeysWithValues: catalogDestinations.map { ($0.id, $0) }
        )
        var orderedIds = catalogDestinations.map(\.id)

        for destination in manifestDestinations {
            if mergedById[destination.id] == nil {
                orderedIds.append(destination.id)
            }
            mergedById[destination.id] = merge(manifestDestination: destination, catalogDestination: mergedById[destination.id])
        }

        return orderedIds.compactMap { mergedById[$0] }
    }

    private static func merge(
        manifestDestination: ManifestDestination,
        catalogDestination: ManifestDestination?
    ) -> ManifestDestination {
        guard let catalogDestination else {
            return manifestDestination
        }

        var merged = catalogDestination
        merged.landmarkAssetName = manifestDestination.landmarkAssetName
        merged.stampAssetName = manifestDestination.stampAssetName
        merged.routeMapAssetName = manifestDestination.routeMapAssetName
        merged.primaryColor = manifestDestination.primaryColor
        merged.postcardTitleTemplate = manifestDestination.postcardTitleTemplate
        merged.postcardSubtitle = manifestDestination.postcardSubtitle
        merged.postcardBodyTemplate = manifestDestination.postcardBodyTemplate
        return merged
    }
}
