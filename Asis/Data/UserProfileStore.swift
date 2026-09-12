import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Resolves profiles by the authenticated UID and owns one removable listener.
///
/// Existing accounts used random document IDs. Exact UID lookup preserves those records
/// while new accounts use their UID as the document ID. Ambiguous matches fail safely.
/// Example: `store.observe(uid: user.uid) { result in }`.
final class UserProfileStore {
    private var listener: ListenerRegistration?
    private var generation = UUID()

    enum ProfileError: LocalizedError {
        case signedOut, ambiguous

        var errorDescription: String? {
            switch self {
            case .signedOut: return String(localized: "notLoggedInError")
            case .ambiguous: return "More than one profile exists for this account. Please contact support."
            }
        }
    }

    /// Observes a profile while the same user remains authenticated.
    /// - Parameters:
    ///   - uid: The authenticated user's exact UID.
    ///   - completion: Main-queue profile data or a resolution/read error.
    /// - Returns: Nothing. Errors are passed to the completion rather than thrown.
    func observe(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        stop()
        let request = generation
        Self.resolve(uid: uid) { [weak self] result in
            guard let self, self.generation == request, Self.matches(uid) else { return }
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let reference):
                self.listener = reference.addSnapshotListener { [weak self] snapshot, error in
                    guard let self, self.generation == request, Self.matches(uid) else { return }
                    if let error { completion(.failure(error)) }
                    else { completion(.success(snapshot?.data() ?? [:])) }
                }
            }
        }
    }

    /// Removes the listener and invalidates pending callbacks, including account switches.
    /// - Returns: Nothing. Does not throw. Call when a screen disappears or signs out.
    func stop() {
        generation = UUID()
        listener?.remove()
        listener = nil
    }

    /// Saves fields to the current account only and reports the server result.
    /// - Parameters:
    ///   - fields: The changed profile fields. UID is always taken from authentication.
    ///   - completion: Called once with a save error or nil after confirmation.
    /// - Returns: Nothing. Does not throw. Example: `update(fields: ["name": name]) { error in }`.
    static func update(fields: [String: Any], completion: @escaping (Error?) -> Void) {
        guard Backend.isConfigured, let uid = Auth.auth().currentUser?.uid else {
            completion(ProfileError.signedOut)
            return
        }
        resolve(uid: uid) { result in
            guard matches(uid) else { completion(ProfileError.signedOut); return }
            switch result {
            case .failure(let error): completion(error)
            case .success(let reference):
                var data = fields
                data["uid"] = uid
                reference.setData(data, merge: true) { error in
                    completion(matches(uid) ? error : ProfileError.signedOut)
                }
            }
        }
    }

    private static func matches(_ uid: String) -> Bool {
        Backend.isConfigured && Auth.auth().currentUser?.uid == uid
    }

    private static func resolve(uid: String, completion: @escaping (Result<DocumentReference, Error>) -> Void) {
        guard matches(uid) else { completion(.failure(ProfileError.signedOut)); return }
        let users = Firestore.firestore().collection("users")
        users.whereField("uid", isEqualTo: uid).limit(to: 2).getDocuments { snapshot, error in
            guard matches(uid) else { completion(.failure(ProfileError.signedOut)); return }
            if let error { completion(.failure(error)); return }
            guard let documents = snapshot?.documents else {
                completion(.failure(ProfileError.signedOut))
                return
            }
            guard documents.count <= 1 else { completion(.failure(ProfileError.ambiguous)); return }
            completion(.success(documents.first?.reference ?? users.document(uid)))
        }
    }

    deinit { listener?.remove() }
}
