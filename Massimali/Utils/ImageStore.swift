import UIKit

/// Preparazione delle foto dei macchinari prima di salvarle nel database.
///
/// Una foto della fotocamera pesa 3-5 MB: dentro SwiftData, moltiplicata per
/// decine di macchinari e riscritta a ogni backup, sarebbe insostenibile.
/// Qui viene ridotta a un lato massimo di 640 px e ricompressa in JPEG,
/// che per una miniatura in lista è più che sufficiente (~40-80 KB).
enum ImageStore {

    static let maxDimension: CGFloat = 640
    static let compression: CGFloat = 0.75

    /// Ridimensiona e comprime. Restituisce `nil` se l'immagine non è utilizzabile.
    static func prepare(_ image: UIImage) -> Data? {
        let resized = downscale(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compression)
    }

    /// Riduce il lato lungo a `maxDimension` mantenendo le proporzioni.
    /// Le immagini già piccole vengono comunque ridisegnate, così l'orientamento
    /// EXIF della fotocamera viene applicato una volta per tutte.
    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
