import SwiftUI

struct EventDraft: Identifiable {
    var event: Event
    let isNew: Bool

    var id: Event.ID { event.id }
}

extension Event {
    static func draft(for business: Business, now: Date = .now) -> Event {
        let start = Calendar.current.nextDate(
            after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? now
        return Event(
            id: UUID(), businessID: business.id, title: "", description: "",
            category: business.category, startTime: start,
            endTime: start.addingTimeInterval(2 * 60 * 60), capacity: nil)
    }

    func canPublish(at now: Date) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && endTime > startTime
            && endTime > now
            && (capacity.map { $0 > 0 } ?? true)
    }

    mutating func reschedule(startingAt newStart: Date) {
        let previousDuration = duration
        startTime = newStart
        endTime = newStart.addingTimeInterval(previousDuration)
    }
}

struct EventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var event: Event
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    private let isNew: Bool
    private let onChange: () async -> Void

    init(draft: EventDraft, onChange: @escaping () async -> Void) {
        _event = State(initialValue: draft.event)
        isNew = draft.isNew
        self.onChange = onChange
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $event.title)
                    TextField("What's happening?", text: $event.description, axis: .vertical)
                        .lineLimit(3...6)
                    CategoryPicker(selection: $event.category)
                }
                Section("When") {
                    DatePicker("Starts", selection: startTimeValue)
                    DatePicker("Ends", selection: $event.endTime, in: event.startTime...)
                    LabeledContent("Length", value: event.durationText)
                }
                Section("Spots") {
                    Toggle("Limit spots", isOn: hasCapacity.animation(Motion.animation(reduceMotion: reduceMotion)))
                    if let capacity = event.capacity {
                        Stepper("Up to \(capacity) people", value: capacityValue, in: 1...500)
                    }
                }
                if !isNew {
                    Section {
                        Button("Delete Event", role: .destructive) {
                            isConfirmingDelete = true
                        }
                    }
                }
            }
            .disabled(isSaving)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(isNew ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().accessibilityLabel("Saving event")
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Event", role: .destructive) {
                    Task { await delete() }
                }
            }
            .errorAlert($errorMessage)
            .interactiveDismissDisabled(isSaving)
        }
    }

    private var canSave: Bool {
        event.canPublish(at: .now)
    }

    private var hasCapacity: Binding<Bool> {
        Binding(
            get: { event.capacity != nil },
            set: { event.capacity = $0 ? 20 : nil })
    }

    private var startTimeValue: Binding<Date> {
        Binding(
            get: { event.startTime },
            set: { event.reschedule(startingAt: $0) })
    }

    private var capacityValue: Binding<Int> {
        Binding(
            get: { event.capacity ?? 1 },
            set: { event.capacity = $0 })
    }

    private func save() async {
        guard canSave, !isSaving else { return }
        event.title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.description = event.description.trimmingCharacters(in: .whitespacesAndNewlines)
        await apply { _ = try await repositories.events.save(event) }
    }

    private func delete() async {
        await apply { try await repositories.events.delete(event.id) }
    }

    private func apply(_ change: () async throws -> Void) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await change()
            await onChange()
            dismiss()
        } catch {
            errorMessage = "Your changes couldn't be saved. Please try again."
        }
    }
}
