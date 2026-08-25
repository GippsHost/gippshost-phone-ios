/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
 *
 * This file is part of Linphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI
import AVFoundation
import PhotosUI
import CoreImage

struct QrCodeScannerFragment: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	
	@Environment(\.dismiss) var dismiss
	
	@State var scanResult = "Scan a QR code"
	@State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
	@State private var showPhotoPicker = false
	@State private var showPhotoError = false
	@State private var photoErrorMessage = ""

	private var isSimulator: Bool {
#if targetEnvironment(simulator)
		true
#else
		false
#endif
	}

	private var hasCamera: Bool {
		AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
	}
	
	var body: some View {
		Group {
			if isSimulator {
				cameraUnavailableView(
					title: "QR scanning isn't available in Simulator",
					message: "The iOS Simulator has no camera feed. You can still choose a saved QR image from Photos, or scan it with Phone on a physical iPhone.",
					showSettingsButton: false
				)
			} else if !hasCamera {
				cameraUnavailableView(
					title: "Camera unavailable",
					message: "This device doesn't currently provide a camera. Choose a saved GippsHost setup QR image from Photos instead.",
					showSettingsButton: false
				)
			} else if cameraStatus == .denied || cameraStatus == .restricted {
				cameraUnavailableView(
					title: "Camera access is required",
					message: "Allow camera access in iOS Settings, then return to Phone to scan your GippsHost setup QR code.",
					showSettingsButton: cameraStatus == .denied
				)
			} else if cameraStatus == .authorized {
				ZStack(alignment: .top) {
					QRScanner(result: $scanResult)

					Text(scanResult)
						.default_text_style_white_800(styleSize: 20)
						.padding(.top, 175)

					scannerBackButton(color: .white)

					VStack {
						Spacer()
						choosePhotoButton()
							.padding(.bottom, 44)
					}
				}
			} else {
				cameraUnavailableView(
					title: "Waiting for camera access",
					message: "Allow camera access to scan your GippsHost setup QR code.",
					showSettingsButton: false
				)
			}
		}
		.edgesIgnoringSafeArea(.all)
		.navigationBarHidden(true)
		.sheet(isPresented: $showPhotoPicker) {
			QRPhotoPicker { result in
				switch result {
				case .success(let payload):
					handleImportedQRCode(payload)
				case .failure(let error):
					photoErrorMessage = error.localizedDescription
					showPhotoError = true
				}
			}
		}
		.alert("Couldn't use that QR image", isPresented: $showPhotoError) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(photoErrorMessage)
		}
		.onAppear {
			coreContext.codeScannerIsOpen = true
			cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
			if hasCamera && cameraStatus == .notDetermined {
				AVCaptureDevice.requestAccess(for: .video) { granted in
					DispatchQueue.main.async {
						cameraStatus = granted ? .authorized : .denied
					}
				}
			}
		}
		.onDisappear {
			coreContext.codeScannerIsOpen = false
		}
	}

	@ViewBuilder
	private func cameraUnavailableView(title: String, message: String, showSettingsButton: Bool) -> some View {
		ZStack(alignment: .top) {
			Color.white

			VStack(spacing: 18) {
				Image("qr-code")
					.renderingMode(.template)
					.resizable()
					.scaledToFit()
					.foregroundStyle(Color.orangeMain500)
					.frame(width: 64, height: 64)

				Text(title)
					.default_text_style_800(styleSize: 22)
					.multilineTextAlignment(.center)

				Text(message)
					.default_text_style(styleSize: 16)
					.multilineTextAlignment(.center)

				if showSettingsButton {
					Button("Open Settings") {
						guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
						UIApplication.shared.open(settingsURL)
					}
					.default_text_style_white_600(styleSize: 17)
					.padding(.horizontal, 28)
					.padding(.vertical, 12)
					.background(Color.orangeMain500)
					.cornerRadius(28)
				}

				choosePhotoButton()
			}
			.padding(.horizontal, 32)
			.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
			.frame(maxHeight: .infinity)

			scannerBackButton(color: Color.grayMain2c600)
		}
	}

	private func choosePhotoButton() -> some View {
		Button {
			showPhotoPicker = true
		} label: {
			HStack(spacing: 10) {
				Image(systemName: "photo.on.rectangle")
				Text("Choose QR from Photos")
			}
			.default_text_style_white_600(styleSize: 17)
			.padding(.horizontal, 24)
			.padding(.vertical, 12)
			.background(Color.orangeMain500)
			.cornerRadius(28)
		}
	}

	private func handleImportedQRCode(_ payload: String) {
		guard let url = URL(string: payload), UIApplication.shared.canOpenURL(url) else {
			photoErrorMessage = "The selected image contains a QR code, but it isn't a valid GippsHost Phone setup code."
			showPhotoError = true
			return
		}

		coreContext.doOnCoreQueue { core in
			try? core.setProvisioninguri(newValue: payload)
			core.stop()
			try? core.start()
		}
		ToastViewModel.shared.show("Success_qr_code_validated")
	}

	private func scannerBackButton(color: Color) -> some View {
		HStack {
			Button {
				dismiss()
			} label: {
				Image("caret-left")
					.renderingMode(.template)
					.resizable()
					.foregroundStyle(color)
					.frame(width: 25, height: 25)
					.padding(10)
			}
			.padding()
			.padding(.top, 50)

			Spacer()
		}
	}
}

private enum QRPhotoPickerError: LocalizedError {
	case imageUnavailable
	case qrCodeNotFound

	var errorDescription: String? {
		switch self {
		case .imageUnavailable:
			return "Phone couldn't load the selected image. Please choose another image."
		case .qrCodeNotFound:
			return "No readable QR code was found in that image. Try a clearer screenshot or photo."
		}
	}
}

private struct QRPhotoPicker: UIViewControllerRepresentable {
	let completion: (Result<String, Error>) -> Void

	func makeUIViewController(context: Context) -> PHPickerViewController {
		var configuration = PHPickerConfiguration(photoLibrary: .shared())
		configuration.filter = .images
		configuration.selectionLimit = 1

		let picker = PHPickerViewController(configuration: configuration)
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(completion: completion)
	}

	final class Coordinator: NSObject, PHPickerViewControllerDelegate {
		let completion: (Result<String, Error>) -> Void

		init(completion: @escaping (Result<String, Error>) -> Void) {
			self.completion = completion
		}

		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			picker.dismiss(animated: true)
			guard let provider = results.first?.itemProvider,
				  provider.canLoadObject(ofClass: UIImage.self) else {
				if !results.isEmpty {
					completion(.failure(QRPhotoPickerError.imageUnavailable))
				}
				return
			}

			provider.loadObject(ofClass: UIImage.self) { object, _ in
				guard let image = object as? UIImage,
					  let ciImage = CIImage(image: image) else {
					DispatchQueue.main.async {
						self.completion(.failure(QRPhotoPickerError.imageUnavailable))
					}
					return
				}

				let detector = CIDetector(
					ofType: CIDetectorTypeQRCode,
					context: CIContext(),
					options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
				)
				let payload = detector?
					.features(in: ciImage)
					.compactMap { ($0 as? CIQRCodeFeature)?.messageString }
					.first

				DispatchQueue.main.async {
					if let payload, !payload.isEmpty {
						self.completion(.success(payload))
					} else {
						self.completion(.failure(QRPhotoPickerError.qrCodeNotFound))
					}
				}
			}
		}
	}
}

#Preview {
	QrCodeScannerFragment()
}
