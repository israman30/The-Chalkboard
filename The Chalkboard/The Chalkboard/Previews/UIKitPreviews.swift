#if DEBUG
import SwiftUI
import UIKit

@available(iOS 13.0, *)
private struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let builder: () -> ViewController

    func makeUIViewController(context: Context) -> ViewController {
        builder()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

@available(iOS 13.0, *)
private struct UIViewPreview<View: UIView>: UIViewRepresentable {
    let builder: () -> View

    func makeUIView(context: Context) -> View {
        builder()
    }

    func updateUIView(_ uiView: View, context: Context) {}
}

@available(iOS 13.0, *)
struct MainCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let container = UIView()
            container.backgroundColor = .appBackground

            let cell = MainCell(style: .default, reuseIdentifier: "preview")
            cell.bind(ChalkboardItem(
                text: "This is a preview of the improved cell UI with dynamic type and better spacing.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            ))

            cell.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(cell)

            NSLayoutConstraint.activate([
                cell.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                cell.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                cell.topAnchor.constraint(equalTo: container.topAnchor),
                cell.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 390)
        .padding()
        .previewDisplayName("Main Cell")
    }
}
#endif

