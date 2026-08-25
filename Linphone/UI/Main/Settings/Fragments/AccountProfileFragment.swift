import SwiftUI
import UniformTypeIdentifiers

struct AccountProfileFragment: View {
	@EnvironmentObject var accountProfileViewModel: AccountProfileViewModel
	@Binding var isShowAccountProfileFragment: Bool
	@AppStorage("gippshost_do_not_disturb") private var doNotDisturb = false
	@State private var isShowLogoutPopup = false

	var body: some View {
		NavigationView {
			ZStack {
				VStack(spacing: 0) {
					header
					ScrollView {
						if let index = accountProfileViewModel.accountModelIndex,
						   CoreContext.shared.accounts.indices.contains(index) {
							let accountModel = CoreContext.shared.accounts[index]
							VStack(spacing: 20) {
								accountDetails(accountModel)
								doNotDisturbCard
								otherActions
							}
							.padding(.vertical, 20)
							.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
						}
					}
					.background(Color.gray100)
				}
				if isShowLogoutPopup { logoutPopup }
			}
			.navigationTitle("")
			.navigationBarHidden(true)
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}

	private var header: some View {
		HStack {
			Image("caret-left")
				.renderingMode(.template)
				.resizable()
				.foregroundStyle(Color.orangeMain500)
				.frame(width: 25, height: 25)
				.padding(10)
				.padding(.leading, -10)
				.onTapGesture {
					withAnimation { isShowAccountProfileFragment = false }
				}
			Text("manage_account_title")
				.default_text_style_orange_800(styleSize: 16)
				.frame(maxWidth: .infinity, alignment: .leading)
			Spacer()
		}
		.frame(height: 50)
		.padding(.horizontal)
		.padding(.bottom, 4)
		.background(.white)
	}

	private func accountDetails(_ accountModel: AccountModel) -> some View {
		VStack(alignment: .leading, spacing: 14) {
			Text("manage_account_details_title")
				.default_text_style_800(styleSize: 18)
			if let address = accountModel.avatarModel?.address,
			   !AppServices.corePreferences.hideSipAddresses {
				HStack(spacing: 10) {
					VStack(alignment: .leading, spacing: 4) {
						Text("SIP address")
							.default_text_style_700(styleSize: 13)
						Text(address)
							.foregroundStyle(Color.grayMain2c700)
							.default_text_style(styleSize: 15)
							.lineLimit(1)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					Button {
						UIPasteboard.general.setValue(address, forPasteboardType: UTType.plainText.identifier)
						ToastViewModel.shared.show("Success_address_copied_into_clipboard")
					} label: {
						Image("copy").resizable().frame(width: 20, height: 20)
					}
				}
			}
		}
		.padding(20)
		.background(.white)
		.cornerRadius(15)
		.padding(.horizontal)
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
				.foregroundStyle(Color.grayMain2c600)
				.default_text_style(styleSize: 13)
				.fixedSize(horizontal: false, vertical: true)
		}
		.padding(20)
		.background(.white)
		.cornerRadius(15)
		.padding(.horizontal)
	}

	private var otherActions: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("contact_details_actions_title")
				.default_text_style_800(styleSize: 18)
				.padding(.horizontal, 20)
			VStack(spacing: 18) {
				Button { isShowLogoutPopup = true } label: {
					HStack {
						Image("sign-out").renderingMode(.template).resizable()
							.foregroundStyle(Color.redDanger500).frame(width: 25, height: 25)
						Text("manage_account_delete").foregroundStyle(Color.redDanger500)
							.default_text_style(styleSize: 16).frame(maxWidth: .infinity, alignment: .leading)
					}
				}
			}
			.padding(20)
			.background(.white)
			.cornerRadius(15)
			.padding(.horizontal)
		}
	}

	private var logoutPopup: some View {
		PopupView(
			isShowPopup: $isShowLogoutPopup,
			title: Text("manage_account_dialog_remove_account_title"),
			content: Text("This will remove the GippsHost Phone account from this device."),
			titleFirstButton: nil, actionFirstButton: {},
			titleSecondButton: Text("manage_account_delete"),
			actionSecondButton: {
				if let index = accountProfileViewModel.accountModelIndex,
				   CoreContext.shared.accounts.indices.contains(index) {
					CoreContext.shared.accounts[index].logout()
					isShowAccountProfileFragment = false
				}
			},
			titleThirdButton: Text("dialog_cancel"),
			actionThirdButton: { isShowLogoutPopup = false }
		)
		.background(.black.opacity(0.65))
	}
}
