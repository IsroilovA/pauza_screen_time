import Flutter
import SwiftUI
import UIKit

final class UsageReportPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private let hostingController: UIHostingController<UsageReportContainerView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        let parameters = UsageReportParameters.from(arguments: args)
        let rootView = UsageReportContainerView(parameters: parameters)
        let controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = .clear
        controller.view.frame = frame
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.containerView = UIView(frame: frame)
        self.hostingController = controller

        super.init()
        containerView.addSubview(controller.view)
    }

    func view() -> UIView {
        containerView
    }
}
