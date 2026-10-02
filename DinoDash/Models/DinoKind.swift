import Foundation

enum DinoKind: String, CaseIterable {
    case ankylosaurus
    case brachiosaurus
    case stegosaurus

    var displayName: String {
        switch self {
        case .ankylosaurus: return "Ankylosaurus"
        case .brachiosaurus: return "Brachiosaurus"
        case .stegosaurus: return "Stegosaurus"
        }
    }

    var previewImageName: String {
        switch self {
        case .ankylosaurus: return "dino-preview-ankylosaurus"
        case .brachiosaurus: return "dino-preview-brachiosaurus"
        case .stegosaurus: return "dino-preview-stegosaurus"
        }
    }

    func makeNode() -> PlayableDino {
        switch self {
        case .ankylosaurus: return Ankylosaurus()
        case .brachiosaurus: return Brachiosaurus()
        case .stegosaurus: return Stegosaurus()
        }
    }
}
