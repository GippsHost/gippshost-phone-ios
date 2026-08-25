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

struct QrCodeScannerFragment: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	
	@Environment(\.dismiss) var dismiss
	
	@State var scanResult = "Scan a QR code"
	@State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

	private var hasCamera: Bool {
		AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
	}
	
	var body: some View {
		Group {
			if !hasCamera {
				cameraUnavailableView(
					title: "QR scanning isn't available in Simulator",
					message: "The iOS Simulator has no camera feed. Open Phone on a physical iPhone to scan a GippsHost setup QR code.",
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
			}
			.padding(.horizontal, 32)
			.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
			.frame(maxHeight: .infinity)

			scannerBackButton(color: Color.grayMain2c600)
		}
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

#Preview {
	QrCodeScannerFragment()
}
