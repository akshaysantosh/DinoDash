import Foundation

enum DinoKind: String, CaseIterable {
    case ankylosaurus
    case brachiosaurus

    var displayName: String {
        switch self {
        case .ankylosaurus: return "Ankylosaurus"
        case .brachiosaurus: return "Brachiosaurus"
        }
    }

    var previewImageName: String {
        switch self {
        case .ankylosaurus: return "dino-preview-ankylosaurus"
        case .brachiosaurus: return "dino-preview-brachiosaurus"
        }
    }

    func makeNode() -> PlayableDino {
        switch self {
        case .ankylosaurus: return Ankylosaurus()
        case .brachiosaurus: return Brachiosaurus()
        }
    }
}
