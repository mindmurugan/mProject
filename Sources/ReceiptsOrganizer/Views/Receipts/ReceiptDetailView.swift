import SwiftUI
import SwiftData

struct ReceiptDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let receipt: Receipt

    @State private var showEditSheet = false

    var body: some View {
        List {
            productSection
            if let warranty = receipt.warrantyInfo {
                warrantySection(warranty)
            }
            if !receipt.attachments.isEmpty {
                attachmentsSection
            }
            if let notes = receipt.userNotes, !notes.isEmpty {
                notesSection(notes)
            }
            if let ocr = receipt.rawOCRText, !ocr.isEmpty {
                ocrSection(ocr)
            }
        }
        .navigationTitle(receipt.productName.isEmpty ? "Receipt" : receipt.productName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddEditReceiptView(existingReceipt: receipt)
            }
        }
    }

    private var productSection: some View {
        Section("Product") {
            LabeledContent("Name", value: receipt.productName.isEmpty ? "—" : receipt.productName)
            LabeledContent("Vendor", value: receipt.vendorName.isEmpty ? "—" : receipt.vendorName)
            LabeledContent("Category", value: receipt.category.displayName)
            if let date = receipt.purchaseDate {
                LabeledContent("Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted))
            }
            if let price = receipt.purchasePrice {
                LabeledContent("Price", value: "\(receipt.currencyCode) \(price)")
            }
        }
    }

    private func warrantySection(_ warranty: WarrantyInfo) -> some View {
        Section("Warranty") {
            WarrantyStatusView(warranty: warranty)
            if let expiry = warranty.expirationDate {
                LabeledContent("Expires", value: expiry.formatted(date: .abbreviated, time: .omitted))
            }
            if let months = warranty.durationMonths {
                LabeledContent("Duration", value: "\(months) months")
            }
            if let type = warranty.warrantyType as WarrantyType? {
                LabeledContent("Type", value: type.displayName)
            }
            if let provider = warranty.providerName {
                LabeledContent("Provider", value: provider)
            }
            if let terms = warranty.warrantyTerms, !terms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terms").font(.caption).foregroundStyle(.secondary)
                    Text(terms).font(.body)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var attachmentsSection: some View {
        Section("Documents (\(receipt.attachments.count))") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(receipt.attachments.sorted(by: { $0.pageNumber < $1.pageNumber })) { attachment in
                        if let data = attachment.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        Section("Notes") {
            Text(notes)
        }
    }

    private func ocrSection(_ text: String) -> some View {
        Section("Extracted Text") {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
