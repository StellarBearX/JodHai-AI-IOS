import WidgetKit
import SwiftUI

// MARK: - Entry View (reads widgetFamily from environment)

struct JodHaiWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JodHaiWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            JodHaiMediumWidgetView(entry: entry)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            JodHaiAccessoryWidgetView(entry: entry)
        default:
            JodHaiSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct JodHaiWidget: Widget {
    let kind = "JodHaiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JodHaiWidgetProvider()) { entry in
            JodHaiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Jod-Hai")
        .description("See today's spend and log expenses instantly.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Bundle Entry Point

@main
struct JodHaiWidgetBundle: WidgetBundle {
    var body: some Widget {
        JodHaiWidget()
    }
}
