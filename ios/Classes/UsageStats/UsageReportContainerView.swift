import DeviceActivity
import FamilyControls
import SwiftUI

enum UsageReportSegment: String {
    case daily
    case hourly
}

struct UsageReportParameters {
    let reportContextId: String
    let segment: UsageReportSegment
    let startDate: Date
    let endDate: Date

    static func from(arguments: Any?) -> UsageReportParameters {
        guard let args = arguments as? [String: Any] else {
            return UsageReportParameters.defaultValue()
        }

        let reportContextId = (args["reportContext"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let segmentRaw = (args["segment"] as? String)?.lowercased()
        let startTimeMs = UsageReportParameters.number(from: args["startTimeMs"])
        let endTimeMs = UsageReportParameters.number(from: args["endTimeMs"])

        let startDate = UsageReportParameters.date(fromMilliseconds: startTimeMs)
        let endDate = UsageReportParameters.date(fromMilliseconds: endTimeMs)

        return UsageReportParameters(
            reportContextId: reportContextId?.isEmpty == false ? reportContextId! : "daily",
            segment: UsageReportSegment(rawValue: segmentRaw ?? "") ?? .daily,
            startDate: startDate,
            endDate: endDate
        )
    }

    static func defaultValue() -> UsageReportParameters {
        let now = Date()
        return UsageReportParameters(
            reportContextId: "daily",
            segment: .daily,
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400),
            endDate: now
        )
    }

    private static func number(from value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let intValue = value as? Int {
            return Double(intValue)
        }
        return nil
    }

    private static func date(fromMilliseconds value: Double?) -> Date {
        guard let value else {
            return Date()
        }
        return Date(timeIntervalSince1970: value / 1000.0)
    }
}

struct UsageReportContainerView: View {
    let parameters: UsageReportParameters

    var body: some View {
        if #available(iOS 16.0, *) {
            DeviceActivityReport(
                parameters.reportContext,
                filter: parameters.filter
            )
        } else {
            Text("Usage reports require iOS 16.0 or later.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@available(iOS 16.0, *)
private extension UsageReportParameters {
    var reportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(reportContextId)
    }

    var filter: DeviceActivityFilter {
        let interval = normalizedInterval()
        let segmentValue: DeviceActivityFilter.SegmentInterval

        switch segment {
        case .hourly:
            segmentValue = .hourly(during: interval)
        case .daily:
            segmentValue = .daily(during: interval)
        }

        return DeviceActivityFilter(
            segment: segmentValue,
            users: .all,
            devices: .all
        )
    }

    func normalizedInterval() -> DateInterval {
        if endDate <= startDate {
            let end = startDate.addingTimeInterval(3600)
            return DateInterval(start: startDate, end: end)
        }
        return DateInterval(start: startDate, end: endDate)
    }
}
