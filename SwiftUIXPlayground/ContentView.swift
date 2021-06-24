//
//  ContentView.swift
//  SwiftUIXPlayground
//
//  Created by Will Bishop on 16/6/21.
//

import SwiftUIX
import PhotosUI

struct ContentView: View {
	
	@State var showPicker = false
	@State var images: [UIImage] = []
	
	var body: some View {
		PaginationView(images, id: \.self, axis: .horizontal, transitionStyle: .scroll, showsIndicators: true) { image in
			ImageCropper(image: image)
				.frame(width: 300, height: 300)
		}
		Button(action: {
			self.showPicker = true
		}, label: {
			Text("Show Picker")
		})
		.sheet(isPresented: self.$showPicker, content: {
			ImagePicker(images: self.$images)
				.edgesIgnoringSafeArea([.bottom])
		})
		
//		Button(action: {
//			self.chosenImage = nil
//		}, label: {
//			Text("Clear")
//		})
	}
}

struct ImageCropper: UIViewRepresentable {
	
	typealias UIViewType = UIScrollView
	var image: UIImage
	
	func makeUIView(context: Context) -> UIScrollView {
		return ImageCropperScrollView(image)
	}
	
	func updateUIView(_ uiView: UIScrollView, context: Context) {
		
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator()
	}
	
	class Coordinator: NSObject, UIScrollViewDelegate {
		
	}
	
}

class ImageCropperScrollView: UIScrollView, UIScrollViewDelegate {
	
	public var image: UIImage
	let imageView = UIImageView()

	init(_ image: UIImage) {
		self.image = image
		super.init(frame: .zero)
	
		self.backgroundColor = .blue
		imageView.image = image
		imageView.contentMode = .scaleAspectFill
		
		self.addSubview(imageView)
		self.delegate = self
		self.minimumZoomScale = 1.0
		self.maximumZoomScale = 4.0
		self.showsVerticalScrollIndicator = false
		self.showsHorizontalScrollIndicator = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func layoutSubviews() {
		self.setupConstraints()
	}
	func setupConstraints() {
		imageView.translatesAutoresizingMaskIntoConstraints = false
		self.contentSize = imageView.frame.size

		var widthAnchor: NSLayoutConstraint
		var heightAnchor: NSLayoutConstraint
		switch image.aspect {
		case .tall:
			let heightScale = self.frame.height / image.size.width
			widthAnchor = self.imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
			heightAnchor = self.imageView.heightAnchor.constraint(equalToConstant: image.size.height * heightScale)
		case .wide:
			let widthScale = self.frame.width / image.size.height
			heightAnchor = self.imageView.heightAnchor.constraint(equalTo: self.widthAnchor)
			widthAnchor = self.imageView.widthAnchor.constraint(equalToConstant: image.size.width * widthScale)
		case .square:
			widthAnchor = self.imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
			heightAnchor = self.imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
		}
		
		NSLayoutConstraint.activate([
			widthAnchor,
			heightAnchor
		])
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		print(scrollView.zoomScale)
	}
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		self.setInset(for: scrollView)
	}
	
	func screenshot() -> UIImage {
		let renderer = UIGraphicsImageRenderer(bounds: bounds)
		return renderer.image { rendererContext in
			layer.render(in: rendererContext.cgContext)
		}
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	@discardableResult
	public func setInset(for scrollView: UIScrollView) -> UIEdgeInsets{
		scrollView.contentSize = imageView.frame.size
		let totalWidth = scrollView.bounds.width
		let imageWidth = imageView.frame.width
		let remainingWidth = max(0, totalWidth - imageWidth)
		
		let totalHeight = scrollView.bounds.height
		let pageHeight = imageView.frame.height
		let remainingHeight = max(0, totalHeight - pageHeight)
		let insets = UIEdgeInsets(top: remainingHeight / 2, left: remainingWidth / 2, bottom: 0, right: 0)
		scrollView.contentInset = insets
		return insets
	}
	

}

extension UIImage {
	
	enum ImageAspect {
		case tall
		case wide
		case square
	}
	
	var aspect: ImageAspect {
		if self.size.width > self.size.height {
			return .wide
		} else if self.size.width < self.size.height {
			return .tall
		} else {
			return .square
		}
	}
	
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

struct ShareSheet: UIViewControllerRepresentable {
	typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
	
	let activityItems: [Any]
	let applicationActivities: [UIActivity]? = nil
	let excludedActivityTypes: [UIActivity.ActivityType]? = nil
	let callback: Callback? = nil
	
	func makeUIViewController(context: Context) -> UIActivityViewController {
		let controller = UIActivityViewController(
			activityItems: activityItems,
			applicationActivities: applicationActivities)
		controller.excludedActivityTypes = excludedActivityTypes
		controller.completionWithItemsHandler = callback
		return controller
	}
	
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
		// nothing to do here
	}
}
