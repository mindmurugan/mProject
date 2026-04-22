import SwiftUI
import SwiftData
import PhotosUI

struct AddEditReceiptView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingReceipt: Receipt?

    @State private var viewModel: AddEditReceiptViewModel?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var warrantyDate: Date = Date()
    @State private var hasWarranty: Bool = false

    init(existingReceipt: Receipt? = nil) {
        self.existingReceipt = existingReceipt
    }

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = AddEditReceiptViewModel(receipt: existingReceipt, modelContext: modelContext)
                if let existing = existingReceipt {
                    hasWarranty = existing.warrantyInfo != nil
                    warrantyDate = existing.warrantyInfo?.expirationDate ?? Date()
                }
                viewModel = vm
            }
        }
    }

    @ViewBuilder
    private func content(vm: AddEditReceiptViewModel) -> some View {
        Form {
            // Document capture
            Section("Document") {
                Button {
                    vm.showScanner = true
                } label: {
                    Label("Scan Document", systemImage: "doc.viewfinder")
                }

                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
                .onChange(of: photosPickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await vm.processPickedImage(image)
                        }
                    }
                }
            }

            if vm.isProcessing {
                Section {
                    AIExtractionProgressView(stage: vm.processingStage.rawValue)
                }
            }

            if let error = vm.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }

            // Product details
            Section("Product Details") {
                TextField("Product Name", text: Binding(
                    get: { vm.receipt.productName },
                    set: { vm.receipt.productName = $0 }
                ))
                TextField("Vendor / Store", text: Binding(
                    get: { vm.receipt.vendorName },
                    set: { vm.receipt.vendorName = $0 }
                ))
                Picker("Category", selection: Binding(
                    get: { vm.receipt.category },
                    set: { vm.receipt.category = $0 }
                )) {
                    ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                        Label(cat.displayName, systemImage: cat.systemImage).tag(cat)
                    }
                }
                DatePicker(
                    "Purchase Date",
                    selection: Binding(
                        get: { vm.receipt.purchaseDate ?? Date() },
                        set: { vm.receipt.purchaseDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }

            // Warranty
            Section("Warranty") {
                Toggle("Has Warranty", isOn: $hasWarranty)
                    .onChange(of: hasWarranty) { _, isOn in
                        if isOn {
                            if vm.receipt.warrantyInfo == nil {
                                let w = WarrantyInfo()
                                vm.receipt.warrantyInfo = w
                            }
                        } else {
                            vm.receipt.warrantyInfo = nil
                        }
                    }

                if hasWarranty {
                    DatePicker(
                        "Expiration Date",
                        selection: $warrantyDate,
                        displayedComponents: .date
                    )
                    .onChange(of: warrantyDate) { _, date in
                        vm.receipt.warrantyInfo?.expirationDate = date
                    }

                    Picker("Warranty Type", selection: Binding(
                        get: { vm.receipt.warrantyInfo?.warrantyType ?? .manufacturer },
                        set: { vm.receipt.warrantyInfo?.warrantyType = $0 }
                    )) {
                        ForEach(WarrantyType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField("Provider Name", text: Binding(
                        get: { vm.receipt.warrantyInfo?.providerName ?? "" },
                        set: { vm.receipt.warrantyInfo?.providerName = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            // Notes
            Section("Notes") {
                TextField("Optional notes...", text: Binding(
                    get: { vm.receipt.userNotes ?? "" },
                    set: { vm.receipt.userNotes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }
        }
        .navigationTitle(existingReceipt == nil ? "New Receipt" : "Edit Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    do {
                        try vm.saveManually()
                        dismiss()
                    } catch {
                        vm.errorMessage = error.localizedDescription
                    }
                }
                .fontWeight(.semibold)
                .disabled(vm.isProcessing)
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showScanner },
            set: { vm.showScanner = $0 }
        )) {
            DocumentScannerView { pages in
                vm.showScanner = false
                Task { await vm.processScannedPages(pages) }
            } onCancelled: {
                vm.showScanner = false
            }
        }
    }
}
