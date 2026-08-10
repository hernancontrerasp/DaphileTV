import SwiftUI
import UIKit

struct TVFocusableView<Content: View>: UIViewRepresentable {

    @Binding var isFocused: Bool

    let content: Content
    let onSelect: () -> Void

    init(
        isFocused: Binding<Bool>,
        onSelect: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isFocused = isFocused
        self.onSelect = onSelect
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> FocusableHostingView {

        let view = FocusableHostingView()

        view.onFocusChanged = { focused in
            context.coordinator.parent.isFocused = focused
        }

        view.onSelect = {
            context.coordinator.parent.onSelect()
        }

        let hostingController = UIHostingController(
            rootView: AnyView(content)
        )

        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        view.hostingController = hostingController

        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            hostingController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            hostingController.view.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            hostingController.view.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])

        return view
    }

    func updateUIView(
        _ uiView: FocusableHostingView,
        context: Context
    ) {

        context.coordinator.parent = self

        uiView.onFocusChanged = { focused in
            context.coordinator.parent.isFocused = focused
        }

        uiView.onSelect = {
            context.coordinator.parent.onSelect()
        }

        uiView.hostingController?.rootView = AnyView(content)
    }

    final class Coordinator {

        var parent: TVFocusableView

        init(_ parent: TVFocusableView) {
            self.parent = parent
        }
    }
}


// MARK: - Focusable UIKit Container

final class FocusableHostingView: UIView {

    var hostingController: UIHostingController<AnyView>?

    var onFocusChanged: ((Bool) -> Void)?
    var onSelect: (() -> Void)?

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {

        super.didUpdateFocus(
            in: context,
            with: coordinator
        )

        let focused = context.nextFocusedView === self

        onFocusChanged?(focused)
    }

    override func pressesEnded(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {

        for press in presses {

            if press.type == .select {

                onSelect?()

                return
            }
        }

        super.pressesEnded(
            presses,
            with: event
        )
    }
}
