import ProjectDescription

let project = Project(
    name: "ZscalerControl",
    organizationName: "AHEAD",
    targets: [
        Target(
            name: "ZscalerControl",
            platform: .macOS,
            product: .app,
            bundleId: "com.ahead.ZscalerControl",
            deploymentTarget: .macOS(targetVersion: "13.0"),
            infoPlist: .extendingDefault(with: [
                "LSUIElement": true,
                "CFBundleIconFile": "AppIcon",
                "NSAppleEventsUsageDescription": "ZscalerControl needs to control system services.",
                "NSSystemAdministrationUsageDescription": "ZscalerControl needs administrative privileges to manage Zscaler services."
            ]),
            sources: ["ZscalerControl/Sources/**"],
            resources: ["ZscalerControl/Resources/**"],
            dependencies: []
        )
    ]
)
