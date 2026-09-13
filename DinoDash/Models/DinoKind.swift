import Foundation

enum DinoKind: String, CaseIterable {
    case ankylosaurus
    case spinosaurus

    var displayName: String {
        switch self {
        case .ankylosaurus: return "Ankylosaurus"
        case .spinosaurus: return "Spinosaurus"
        }
    }

    var previewImageName: String {
        switch self {
        case .ankylosaurus: return "dino-preview-ankylosaurus"
        case .spinosaurus: return "dino-preview-spinosaurus"
        }
    }

    func makeNode() -> PlayableDino {
        switch self {
        case .ankylosaurus: return Ankylosaurus()
        case .spinosaurus: return Spinosaurus()
        }
    }
}
