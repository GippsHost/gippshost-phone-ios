import AVFoundation
import Contacts
import Photos
import SwiftUI
import UserNotifications

struct SettingsFragment: View {
	@Binding var isShowSettingsFragment: Bool
	@AppStorage("gippshost_do_not_disturb") private var doNotDisturb = false
	@State private var permissionSummary = "Checking permissions…"
	@State private var permissionsNeedAttention = false
	@State private var isShowRemoveAccountPopup = false

	var body: some View {
		NavigationView {
			ZStack {
				VStack(spacing: 0) {
					header
					ScrollView {
						VStack(spacing: 20) {
							if hasPhoneIdentity { phoneAccountCard }
							doNotDisturbCard
							permissionsCard
							aboutCard
							removeAccountButton
						}
						.padding(.vertical, 20)
						.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
					}
					.background(Color.gray100)
				}
				if isShowRemoveAccountPopup { removeAccountPopup }
			}
			.navigationTitle("")
			.navigationBarHidden(true)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear(perform: refreshPermissionSummary)
	}

	private var phoneAccountCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Your phone").default_text_style_800(styleSize: 18)
			if !accountName.isEmpty {
				Text(accountName)
					.default_text_style_700(styleSize: 16)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			HStack(spacing: 10) {
				Image(systemName: "phone.fill")
					.foregroundStyle(Color.orangeMain500)
				VStack(alignment: .leading, spacing: 2) {
					Text(phoneNumber.isEmpty ? "Extension" : "Phone number")
						.foregroundStyle(Color.grayMain2c600)
						.default_text_style(styleSize: 12)
					Text(formattedPhoneIdentity)
						.default_text_style(styleSize: 16)
				}
			}
		}
		.padding(20).background(.white).cornerRadius(15).padding(.horizontal)
	}

	private var header: some View {
		HStack {
			Image("caret-left")
				.renderingMode(.template).resizable()
				.foregroundStyle(Color.orangeMain500)
				.frame(width: 25, height: 25).padding(10).padding(.leading, -10)
				.onTapGesture { withAnimation { isShowSettingsFragment = false } }
			Text("Settings")
				.default_text_style_orange_800(styleSize: 16)
				.frame(maxWidth: .infinity, alignment: .leading)
			Spacer()
		}
		.frame(height: 50).padding(.horizontal).padding(.bottom, 4).background(.white)
	}

	private var doNotDisturbCard: some View {
		VStack(alignment: .leading, spacing: 10) {
			Toggle(isOn: $doNotDisturb) {
				HStack(spacing: 12) {
					Image(systemName: "moon.fill").foregroundStyle(Color.orangeMain500)
					Text("Do Not Disturb").default_text_style_700(styleSize: 16)
				}
			}
			Text("Incoming calls will be declined on this device while Do Not Disturb is enabled. You can still make outgoing calls.")
				.foregroundStyle(Color.grayMain2c600).default_text_style(styleSize: 13)
				.fixedSize(horizontal: false, vertical: true)
		}
		.padding(20).background(.white).cornerRadius(15).padding(.horizontal)
	}

	private var permissionsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 12) {
				Image(systemName: permissionsNeedAttention ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
					.foregroundStyle(permissionsNeedAttention ? Color.orangeMain500 : Color.greenSuccess500)
				Text("Permissions").default_text_style_700(styleSize: 16)
			}
			Text(permissionSummary)
				.foregroundStyle(Color.grayMain2c600).default_text_style(styleSize: 13)
				.fixedSize(horizontal: false, vertical: true)
			Button {
				guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
				UIApplication.shared.open(settingsURL)
			} label: {
				Text("Manage permissions").default_text_style_orange_700(styleSize: 15)
			}
			.buttonStyle(.plain)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(20).background(.white).cornerRadius(15).padding(.horizontal)
	}

	private var aboutCard: some View {
		VStack(alignment: .leading, spacing: 18) {
			Text("About GippsHost Phone").default_text_style_800(styleSize: 18)
			HStack {
				Text("Version").default_text_style(styleSize: 15)
				Spacer()
				Text(appVersion).foregroundStyle(Color.grayMain2c600).default_text_style(styleSize: 15)
			}
			Divider()
			Link(destination: URL(string: "mailto:support@gippshost.com.au")!) {
				settingsLink(title: "Contact support", systemImage: "envelope")
			}
			Divider()
			Link(destination: URL(string: "https://www.gippshost.com.au/privacy-policy/")!) {
				settingsLink(title: "Privacy policy", systemImage: "hand.raised")
			}
		}
		.padding(20).background(.white).cornerRadius(15).padding(.horizontal)
	}

	private var removeAccountButton: some View {
		Button { isShowRemoveAccountPopup = true } label: {
			HStack(spacing: 12) {
				Image(systemName: "rectangle.portrait.and.arrow.right")
				Text("Remove account").default_text_style_700(styleSize: 16)
				Spacer()
			}
			.foregroundStyle(Color.redDanger500)
			.padding(20).background(.white).cornerRadius(15).padding(.horizontal)
		}
		.buttonStyle(.plain)
	}

	private var removeAccountPopup: some View {
		PopupView(
			isShowPopup: $isShowRemoveAccountPopup,
			title: Text("Remove account?"),
			content: Text("This will remove the GippsHost Phone account from this device."),
			titleFirstButton: nil, actionFirstButton: {},
			titleSecondButton: Text("Remove account"),
			actionSecondButton: {
				CoreContext.shared.accounts.first?.logout()
				isShowSettingsFragment = false
			},
			titleThirdButton: Text("Cancel"),
			actionThirdButton: { isShowRemoveAccountPopup = false }
		)
		.background(.black.opacity(0.65))
	}

	private func settingsLink(title: String, systemImage: String) -> some View {
		HStack(spacing: 12) {
			Image(systemName: systemImage).frame(width: 22)
			Text(title).default_text_style(styleSize: 15)
			Spacer()
			Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .semibold))
		}
		.foregroundStyle(Color.grayMain2c700)
	}

	private var appVersion: String {
		let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
		let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
		return build.isEmpty ? version : "\(version) (\(build))"
	}

	private var accountName: String {
		let configured = AppServices.config.getString(section: "gippshost", key: "account_name", defaultString: "")
		if !configured.isEmpty { return configured }
		return CoreContext.shared.accounts.first?.displayNameAvatar ?? ""
	}

	private var phoneNumber: String {
		AppServices.config.getString(section: "gippshost", key: "phone_number", defaultString: "")
	}

	private var sipUsername: String {
		CoreContext.shared.accounts.first?.account.params?.identityAddress?.username ?? ""
	}

	private var hasPhoneIdentity: Bool {
		!accountName.isEmpty || !phoneNumber.isEmpty || !sipUsername.isEmpty
	}

	private var formattedPhoneIdentity: String {
		phoneNumber.isEmpty ? sipUsername : formattedPhoneNumber
	}

	private var formattedPhoneNumber: String {
		var digits = phoneNumber.filter(\.isNumber)
		if digits.hasPrefix("61") && digits.count == 11 {
			digits = "0" + String(digits.dropFirst(2))
		}
		if digits.count == 10 {
			let first = digits.prefix(2)
			let middle = digits.dropFirst(2).prefix(4)
			let last = digits.suffix(4)
			return "\(first) \(middle) \(last)"
		}
		return phoneNumber
	}

	private func refreshPermissionSummary() {
		UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
			var missing: [String] = []
			if notificationSettings.authorizationStatus != .authorized && notificationSettings.authorizationStatus != .provisional { missing.append("Notifications") }
			if AVAudioSession.sharedInstance().recordPermission != .granted { missing.append("Microphone") }
			if CNContactStore.authorizationStatus(for: .contacts) != .authorized { missing.append("Contacts") }
			if AVCaptureDevice.authorizationStatus(for: .video) != .authorized { missing.append("Camera") }
			let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
			if photoStatus != .authorized && photoStatus != .limited { missing.append("Photos") }
			DispatchQueue.main.async {
				permissionsNeedAttention = !missing.isEmpty
				permissionSummary = missing.isEmpty
					? "All permissions required for calling and contacts are enabled."
					: "Review access for: \(missing.joined(separator: ", "))."
			}
		}
	}
}
