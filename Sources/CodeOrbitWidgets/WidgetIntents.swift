import AppIntents
import WidgetKit



public struct ConfigureUsernameIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Configure Username"
    public static var description = IntentDescription("Enter your username.")

    @Parameter(title: "Username")
    public var username: String?

    public static var parameterSummary: some ParameterSummary {
        Summary {
            \.$username
        }
    }

    public init() {}
}
