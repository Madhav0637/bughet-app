import SwiftData
import SwiftUI

/// Name and emoji fields, shared by adding a category and editing one.
struct CategoryFields: View {
    @Binding var name: String
    @Binding var emoji: String

    var body: some View {
        LabeledContent("Name") {
            TextField("e.g. Rent", text: $name)
                .multilineTextAlignment(.trailing)
        }
        LabeledContent("Emoji") {
            TextField("🙂", text: $emoji)
                .multilineTextAlignment(.trailing)
                // Keep only the most recent character, so typing a new emoji replaces the old one.
                .onChange(of: emoji) {
                    if emoji.count > 1, let last = emoji.last { emoji = String(last) }
                }
        }
    }
}

/// Adds a new category.
struct CategoryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && CategoryService.isValidEmoji(emoji)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CategoryFields(name: $name, emoji: $emoji)
                } footer: {
                    Text("Tap Emoji, then use the 🙂 key on the keyboard to pick one.")
                }
                .listRowBackground(Color.surface)
            }
            .kokuList()
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .alert("Couldn't save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        do {
            try CategoryService(context: context).add(name: name, emoji: emoji)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
