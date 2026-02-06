/// Main plugin entry point for the Pauza Screen Time plugin on iOS.
///
/// Handles method channel communication between Flutter and native iOS code,
/// routing calls to the appropriate handlers for permissions, installed apps,
/// and app restriction functionality.

import Flutter

public class PauzaScreenTimePlugin: NSObject, FlutterPlugin {

    /// Registers the plugin with the Flutter engine.
    public static func register(with registrar: FlutterPluginRegistrar) {
        CoreRegistrar.register(with: registrar)
        PermissionsRegistrar.register(with: registrar)
        InstalledAppsRegistrar.register(with: registrar)
        RestrictionsRegistrar.register(with: registrar)
        UsageStatsRegistrar.register(with: registrar)

        registrar.register(
            UsageReportViewFactory(messenger: registrar.messenger()),
            withId: UsageReportViewFactory.viewType
        )
    }
}
