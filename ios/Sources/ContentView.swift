import SwiftUI

struct ContentView: View {
    @StateObject private var vm = IFACViewModel()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                SearchBar(query: vm.query, onQueryChange: vm.setQuery, clear: { vm.setQuery("") })
                    .padding(.horizontal)

                ProgressHeader(overall: vm.overallProgress)
                    .padding(.horizontal)

                List {
                    ForEach(vm.filtered) { tc in
                        Section {
                            TCSection(tc: tc, checked: vm.checked) { item in
                                vm.toggle(tc, item)
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(tc.code) – \(tc.name)")
                                    .font(.headline)
                                if !tc.keywords.isEmpty {
                                    Text("Keywords: \(tc.keywords)").font(.caption)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("IFAC Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTcSheet { code, name, items, keywords in
                    vm.addCustomTc(code: code.isEmpty ? nil : code,
                                   name: name,
                                   items: items.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                                   keywords: keywords)
                }
            }
        }
    }
}

private struct SearchBar: View {
    let query: String
    let onQueryChange: (String) -> Void
    let clear: () -> Void
    var body: some View {
        HStack {
            TextField("Search TCs, bullets, keywords…", text: .init(get: { query }, set: onQueryChange))
                .textFieldStyle(.roundedBorder)
            if !query.isEmpty {
                Button("Clear", action: clear)
            }
        }
    }
}

private struct ProgressHeader: View {
    let overall: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overall Progress").fontWeight(.semibold)
            ProgressView(value: overall)
            Text("\(Int(overall * 100))%")
                .font(.caption)
        }
    }
}

private struct TCSection: View {
    let tc: TC
    let checked: [String: Bool]
    let onToggle: (String) -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(expanded ? "Hide" : "Show") { expanded.toggle() }
                .font(.subheadline)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tc.items, id: \.self) { item in
                        let key = prefKey(tc.code, item)
                        HStack {
                            Toggle("", isOn: .init(get: { checked[key] ?? false },
                                                   set: { _ in onToggle(item) }))
                                .labelsHidden()
                            Text(item)
                        }
                    }
                }
            }
        }
    }
}

private struct AddTcSheet: View {
    var onConfirm: (String, String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var name = ""
    @State private var itemsText = ""
    @State private var keywords = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Topic") {
                    TextField("TC Code (e.g., USER-1)", text: $code)
                    TextField("Name", text: $name)
                    TextField("Keywords (comma-separated)", text: $keywords)
                    TextField("Bullets (one per line)", text: $itemsText, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle("Add Topic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onConfirm(code, name, itemsText, keywords)
                        dismiss()
                    }
                }
            }
        }
    }
}
