import SwiftUI

/// Short messages at the bottom of the screen, such as "Deleted Zomato · Undo". Shared by the whole app, so a toast
/// started in a sheet is still visible after the sheet closes.
@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        var systemImage: String?
        var actionTitle: String?
    }

    private(set) var current: Toast?
    @ObservationIgnored private var action: (() -> Void)?
    @ObservationIgnored private var dismissal: Task<Void, Never>?

    func show(_ message: String, systemImage: String? = nil, actionTitle: String? = nil,
              duration: Duration = .seconds(4), action: (() -> Void)? = nil) {
        dismissal?.cancel()
        self.action = action
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            current = Toast(message: message, systemImage: systemImage, actionTitle: actionTitle)
        }
        dismissal = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func performAction() {
        let action = self.action
        dismiss()
        action?()
    }

    func dismiss() {
        dismissal?.cancel()
        action = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { current = nil }
    }
}

struct ToastView: View {
    let toast: ToastCenter.Toast
    let onAction: () -> Void

    @Environment(\.highlight) private var highlight

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage = toast.systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let actionTitle = toast.actionTitle {
                Button(actionTitle, action: onAction)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(highlight.fill)
                    .buttonStyle(.pressable)
                    .accessibilityIdentifier("toastAction")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 54)
        .background(Color.toastBackground, in: .rect(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
        .environment(\.colorScheme, .dark)
    }
}

/// The bottom of Home and Activity: the current toast, and the add button beside it.
struct FloatingActions: View {
    let onAdd: () -> Void

    @Environment(ToastCenter.self) private var toasts

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let toast = toasts.current {
                ToastView(toast: toast, onAction: toasts.performAction)
                    .id(toast.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 0)
            AddButton(action: onAdd)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}
