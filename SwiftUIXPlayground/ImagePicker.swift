//
//  ImagePicker.swift
//  SwiftUIXPlayground
//
//  Created by Will Bishop on 24/6/21.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
	@Binding var images: [UIImage]
	
	typealias UIViewControllerType = PHPickerViewController
	
	func makeUIViewController(context: Context) -> PHPickerViewController {
		var pickerConfiguration = PHPickerConfiguration()
		pickerConfiguration.filter = .any(of: [.images, .livePhotos])
		pickerConfiguration.selectionLimit = 5
		
		let picker = PHPickerViewController(configuration: pickerConfiguration)
		picker.delegate = context.coordinator
		
		return picker
	}
	
	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
		
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}
	
	class Coordinator: NSObject, PHPickerViewControllerDelegate {
		
		var parent: ImagePicker?
		
		init(_ parent: ImagePicker) {
			self.parent = parent
		}
		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			self.handleResults(results)
			picker.dismiss()
		}
		
		func handleResults(_ results: [PHPickerResult]) {
			let dispatchQueue = DispatchQueue(label: "com.stryds.strydsapp.AlbumImageQueue")
			var selectedImageDatas = [UIImage?](repeating: nil, count: results.count)
			var totalConversionsCompleted = 0
			
			for (index, result) in results.enumerated() {
				result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
					print("Begin Processing")
					guard let url = url else {
						print("Failed \(#line)")
						return
					}
					
					let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
					guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
						print("Failed \(#line)")
						dispatchQueue.sync { totalConversionsCompleted += 1 }
						return
					}
					
					let downsampleOptions = [
						kCGImageSourceCreateThumbnailFromImageAlways: true,
						kCGImageSourceCreateThumbnailWithTransform: true,
						kCGImageSourceThumbnailMaxPixelSize: 760,
					] as CFDictionary
					
					guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
						print("Failed \(#line)")
						dispatchQueue.sync { totalConversionsCompleted += 1 }
						return
					}
					
					let data = NSMutableData()
					guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
						print("Failed \(#line)")
						dispatchQueue.sync { totalConversionsCompleted += 1 }
						return
					}
					
					let isPNG: Bool = {
						guard let utType = cgImage.utType else { return false }
						return (utType as String) == UTType.png.identifier
					}()
					
					let destinationProperties = [
						kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
					] as CFDictionary
					
					CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
					CGImageDestinationFinalize(imageDestination)
					dispatchQueue.sync {
						selectedImageDatas[index] = UIImage(data: data as Data)
						totalConversionsCompleted += 1
					}
					self.parent?.images = selectedImageDatas.compactMap{$0}
				}
				
			}
			
		}
	}
}
