import Foundation

@MainActor
@Observable
final class SyncService {
    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?

    var isAppActive = true {
        didSet {
            if isAppActive {
                // Trigger immediate sync on foreground return
                triggerSync()
            }
        }
    }

    private var pollingTask: Task<Void, Never>?
    private var onData: (([Building]) -> Void)?

    private var pollInterval: Duration {
        isAppActive ? .seconds(30) : .seconds(300)
    }

    // MARK: - Lifecycle

    func startSync(api: APIService, onData: @escaping @MainActor ([Building]) -> Void) {
        self.onData = onData
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.performSync(api: api)
                do {
                    try await Task.sleep(for: self?.pollInterval ?? .seconds(30))
                } catch {
                    break
                }
            }
        }
    }

    func stopSync() {
        pollingTask?.cancel()
        pollingTask = nil
        onData = nil
    }

    func triggerSync() {
        // Cancel current wait and restart loop for immediate poll
        guard onData != nil else { return }
        // Just kick a one-shot sync; the loop continues on its own
        Task { [weak self] in
            guard let self else { return }
            await self.performSync(api: APIService.shared)
        }
    }

    // MARK: - Sync

    private func performSync(api: APIService) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let buildings = try await api.fetchBuildings()
            syncError = nil
            lastSyncDate = Date()
            onData?(buildings)
        } catch {
            syncError = error.localizedDescription
        }
    }
}
