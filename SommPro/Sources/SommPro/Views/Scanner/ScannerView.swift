import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ScannerViewModel
    @State private var isShowingCamera = false
    @State private var navigationOutcome: ScannerViewModel.ScanOutcome?

    init(enrichmentCoordinator: EnrichmentCoordinator) {
        _viewModel = State(initialValue: ScannerViewModel(enrichmentCoordinator: enrichmentCoordinator))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(ScanMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text(viewModel.mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.isProcessing {
                    ProgressView(viewModel.mode == .menu ? "Reading menu…" : "Reading label…")
                } else {
                    Button {
                        isShowingCamera = true
                    } label: {
                        Label("Scan", systemImage: "camera.fill")
                            .font(.title2.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                switch viewModel.mode {
                case .shop where !viewModel.shopQueue.isEmpty:
                    ShopQueueList(outcomes: viewModel.shopQueue) { outcome in
                        navigationOutcome = outcome
                    }
                case .menu where !viewModel.menuCandidates.isEmpty:
                    MenuCandidateList(candidates: viewModel.menuCandidates) { candidate in
                        Task {
                            if let outcome = await viewModel.resolveMenuCandidate(candidate, modelContext: modelContext) {
                                navigationOutcome = outcome
                            }
                        }
                    }
                default:
                    Spacer()
                }
            }
            .navigationTitle("SommPro")
            .sheet(isPresented: $isShowingCamera) {
                CameraCaptureView { image in
                    isShowingCamera = false
                    Task {
                        await viewModel.handleCapturedImage(image, modelContext: modelContext)
                        if viewModel.mode == .drink, let outcome = viewModel.activeOutcome {
                            navigationOutcome = outcome
                        }
                    }
                }
                .ignoresSafeArea()
            }
            .navigationDestination(item: $navigationOutcome) { outcome in
                WineDetailView(outcome: outcome, enrichmentCoordinator: viewModel.enrichmentCoordinator)
            }
            .alert(
                "Scan failed",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
