import SwiftUI
import SwiftData

struct ReceiptListView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var receipts: [Receipt]
    @State private var viewModel = ReceiptListViewModel()
    @State private var showAddSheet = false
    @State private var receiptToDelete: Receipt?

    var body: some View {
        Group {
            if receipts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Receipts")
        .searchable(text: $viewModel.searchText, prompt: "Search by product or vendor")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort", selection: $viewModel.sortOrder) {
                        ForEach(ReceiptListViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    Divider()
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All").tag(ReceiptCategory?.none)
                        ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.systemImage)
                                .tag(Optional(cat))
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddEditReceiptView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.filtered(receipts)) { receipt in
                NavigationLink(value: receipt) {
                    ReceiptRowView(receipt: receipt)
                }
            }
            .onDelete(perform: deleteReceipts)
        }
        .navigationDestination(for: Receipt.self) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Receipts", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Tap + to add your first receipt or warranty.")
        } actions: {
            Button("Add Receipt") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        let filtered = viewModel.filtered(receipts)
        for index in offsets {
            let receipt = filtered[index]
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }
}
