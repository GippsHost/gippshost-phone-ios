/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
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
import Combine

struct LoginFragment: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	
	@StateObject private var accountLoginViewModel = AccountLoginViewModel()
	@StateObject private var keyboard = KeyboardResponder()
	
	@State private var isSecured: Bool = true
	@State private var usesHostedSystem = false
	@State private var hostedSystemName = ""
	
	@FocusState var isNameFocused: Bool
	@FocusState var isPasswordFocused: Bool
	@FocusState var isServerFocused: Bool
	@FocusState var isHostedSystemNameFocused: Bool
	
	@State private var isShowPopup = false
	
	@State private var linkActive = ""
	
	@State private var isLinkSIPActive = false
	@State private var isLinkREGActive = false
	
	@State var isShowHelpFragment = false
	
	var isShowBack = false
	
	var onBackPressed: (() -> Void)?

	private var resolvedServer: String {
		if usesHostedSystem {
			let name = hostedSystemName
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.lowercased()
				.trimmingCharacters(in: CharacterSet(charactersIn: "."))
			return name.isEmpty ? "" : "\(name).voice.gippshost.com.au"
		}
		return accountLoginViewModel.domain
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()
			.trimmingCharacters(in: CharacterSet(charactersIn: "."))
	}

	private var hostedSystemNameIsValid: Bool {
		guard usesHostedSystem else { return true }
		let labels = hostedSystemName
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()
			.split(separator: ".")
		guard !labels.isEmpty else { return false }
		return labels.allSatisfy { label in
			label.range(of: "^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$", options: .regularExpression) != nil
		}
	}

	private var formIsValid: Bool {
		!accountLoginViewModel.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			&& !accountLoginViewModel.passwd.isEmpty
			&& hostedSystemNameIsValid
			&& AccountLoginViewModel.isAllowedVoiceDomain(resolvedServer)
	}

	var body: some View {
		NavigationView {
			ZStack {
				GeometryReader { geometry in
					if #available(iOS 16.4, *) {
						ScrollView(.vertical) {
							innerScrollView(geometry: geometry)
						}
						.scrollBounceBehavior(.basedOnSize)
					} else {
						ScrollView(.vertical) {
							innerScrollView(geometry: geometry)
						}
					}
					
					if self.isShowPopup {
						let generalTerms = String(format: "[%@](%@)", String(localized: "assistant_dialog_general_terms_label"), "https://www.linphone.org/en/terms-of-use/")
						let privacyPolicy = String(format: "[%@](%@)", String(localized: "assistant_dialog_privacy_policy_label"), "https://linphone.org/en/privacy-policy")
						let splitMsg = String(localized: "assistant_dialog_general_terms_and_privacy_policy_message").components(separatedBy: "%@")
						if splitMsg.count == 3 { // We expect form of  STRING %A STRING %@ STRING
							let contentPopup1 = Text(.init(splitMsg[0]))
							let contentPopup2 = Text(.init(generalTerms)).underline()
							let contentPopup3 = Text(.init(splitMsg[1]))
							let contentPopup4 = Text(.init(privacyPolicy)).underline()
							let contentPopup5 = Text(.init(splitMsg[2]))
							PopupView(
								isShowPopup: $isShowPopup,
								title: Text("assistant_dialog_general_terms_and_privacy_policy_title"),
								content: contentPopup1 + contentPopup2 + contentPopup3 + contentPopup4 + contentPopup5,
								titleFirstButton: nil,
								actionFirstButton: {},
								titleSecondButton: Text("dialog_accept"),
								actionSecondButton: { acceptGeneralTerms() },
								titleThirdButton: Text("dialog_deny"),
								actionThirdButton: { self.isShowPopup.toggle() }
							)
							.background(.black.opacity(0.65))
							.onTapGesture {
								self.isShowPopup.toggle()
							}
						} else {  // backup just in case
							PopupView(
								isShowPopup: $isShowPopup,
								title: Text("assistant_dialog_general_terms_and_privacy_policy_title"),
								content: Text(.init(String(format: String(localized: "assistant_dialog_general_terms_and_privacy_policy_message"), generalTerms, privacyPolicy))),
								titleFirstButton: nil,
								actionFirstButton: {},
								titleSecondButton: Text("dialog_accept"),
								actionSecondButton: { acceptGeneralTerms() },
								titleThirdButton: Text("dialog_deny"),
								actionThirdButton: { self.isShowPopup.toggle() }
							)
							.background(.black.opacity(0.65))
							.onTapGesture {
								self.isShowPopup.toggle()
							}
						}
					}
				}
				
				if isShowHelpFragment {
					HelpFragment(
						isShowHelpFragment: $isShowHelpFragment
					)
					.transition(.move(edge: .trailing))
					.zIndex(3)
				}
				
				if coreContext.loggingInProgress {
					PopupLoadingView()
						.background(.black.opacity(0.65))
				}
			}
			.navigationTitle("")
			.navigationBarHidden(true)
			.edgesIgnoringSafeArea(.bottom)
			.edgesIgnoringSafeArea(.horizontal)
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func innerScrollView(geometry: GeometryProxy) -> some View {
		VStack {
			ZStack {
				HStack {
					if isShowBack {
						Image("caret-left")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.grayMain2c500)
							.frame(width: 25, height: 25)
							.padding(.all, 10)
							.onTapGesture {
								withAnimation {
									onBackPressed?()
								}
							}
					} else {
						Color.clear
							.frame(width: 25, height: 25)
							.padding(.all, 10)
					}

					Spacer()
				}

				Text("gippshost_setup_title")
					.default_text_style_800(styleSize: 20)
			}
			.frame(width: geometry.size.width)
			.padding(.top, 10)
			.padding(.bottom, 20)
			
			Image("gippshost-cloud")
				.renderingMode(.template)
				.resizable()
				.scaledToFit()
				.foregroundStyle(Color.orangeMain500)
				.frame(width: 72, height: 52)
				.padding(.bottom, 12)

			VStack(alignment: .leading) {
				Text(String(localized: "username")+"*")
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				TextField("username", text: $accountLoginViewModel.username)
					.default_text_style(styleSize: 15)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.frame(height: 25)
					.padding(.horizontal, 20)
					.padding(.vertical, 15)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(isNameFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
					)
					.padding(.bottom)
					.focused($isNameFocused)
				
				Text(String(localized: "password")+"*")
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				ZStack(alignment: .trailing) {
					Group {
						if isSecured {
							SecureField("password", text: $accountLoginViewModel.passwd)
								.default_text_style(styleSize: 15)
								.frame(height: 25)
								.focused($isPasswordFocused)
						} else {
							TextField("password", text: $accountLoginViewModel.passwd)
								.default_text_style(styleSize: 15)
								.disableAutocorrection(true)
								.autocapitalization(.none)
								.frame(height: 25)
								.focused($isPasswordFocused)
						}
					}
					
					Button(action: {
						isSecured.toggle()
					}, label: {
						Image(self.isSecured ? "eye-slash" : "eye")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.grayMain2c500)
							.frame(width: 20, height: 20)
					})
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 15)
				.cornerRadius(60)
				.overlay(
					RoundedRectangle(cornerRadius: 60)
						.inset(by: 0.5)
						.stroke(isPasswordFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
				)
				.padding(.bottom)

				Toggle(isOn: $usesHostedSystem) {
					Text("gippshost_hosted_system")
						.default_text_style_600(styleSize: 15)
				}
				.tint(Color.orangeMain500)
				.padding(.bottom)
				.onChange(of: usesHostedSystem) { enabled in
					if !enabled {
						hostedSystemName = ""
						accountLoginViewModel.domain = "voice.gippshost.com.au"
					}
				}

				if usesHostedSystem {
					Text(String(localized: "gippshost_subdomain") + "*")
						.default_text_style_700(styleSize: 15)
						.padding(.bottom, -5)

					HStack(spacing: 4) {
						TextField("wendymcewan", text: $hostedSystemName)
							.default_text_style(styleSize: 15)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.focused($isHostedSystemNameFocused)
						Text(".voice.gippshost.com.au")
							.default_text_style(styleSize: 13)
							.foregroundStyle(Color.grayMain2c500)
					}
					.frame(height: 25)
					.padding(.horizontal, 20)
					.padding(.vertical, 15)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(isHostedSystemNameFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
					)
					Text("gippshost_hosted_system_hint")
						.default_text_style(styleSize: 12)
						.foregroundStyle(Color.grayMain2c500)
						.padding(.leading, 12)
						.padding(.bottom)
				} else {
					Text(String(localized: "gippshost_server") + "*")
						.default_text_style_700(styleSize: 15)
						.padding(.bottom, -5)

					TextField("voice.gippshost.com.au", text: $accountLoginViewModel.domain)
						.default_text_style(styleSize: 15)
						.disableAutocorrection(true)
						.autocapitalization(.none)
						.frame(height: 25)
						.padding(.horizontal, 20)
						.padding(.vertical, 15)
						.cornerRadius(60)
						.overlay(
							RoundedRectangle(cornerRadius: 60)
								.inset(by: 0.5)
								.stroke(isServerFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
						)
						.padding(.bottom)
						.focused($isServerFocused)
				}
				
				Button(action: {
					accountLoginViewModel.domain = resolvedServer
					SharedMainViewModel.shared.changeDisplayProfileMode()
					self.accountLoginViewModel.login()
					coreContext.loggingInProgress = true
				}, label: {
					Text("assistant_account_login")
						.default_text_style_white_600(styleSize: 20)
						.frame(height: 35)
						.frame(maxWidth: .infinity)
				})
				.padding(.horizontal, 20)
				.padding(.vertical, 10)
				.background(formIsValid ? Color.orangeMain500 : Color.orangeMain100)
				.cornerRadius(60)
				.disabled(!formIsValid)
				.padding(.bottom)
				
				HStack {
					VStack {
						Divider()
					}
					Text("or")
						.default_text_style(styleSize: 15)
						.foregroundStyle(Color.grayMain2c500)
					VStack {
						Divider()
					}
				}
				.padding(.bottom, 10)
				
				NavigationLink(destination: {
					QrCodeScannerFragment()
				}, label: {
					HStack {
						Image("qr-code")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.orangeMain500)
							.frame(width: 20, height: 20)
						
						Text("assistant_scan_qr_code")
							.default_text_style_orange_600(styleSize: 20)
							.frame(height: 35)
					}
					.frame(maxWidth: .infinity)
					
				})
				.padding(.horizontal, 20)
				.padding(.vertical, 10)
				.cornerRadius(60)
				.overlay(
					RoundedRectangle(cornerRadius: 60)
						.inset(by: 0.5)
						.stroke(Color.orangeMain500, lineWidth: 1)
				)
				.padding(.bottom)
			}
			.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
			.padding(.horizontal, 20)
			
			Spacer()
			
			Text("GippsHost customers only • gippshost.com.au")
				.default_text_style(styleSize: 13)
				.foregroundStyle(Color.grayMain2c500)
				.padding(.bottom, 24)
		}
		.frame(minHeight: geometry.size.height)
		.padding(.bottom, keyboard.currentHeight)
	}
	
	func acceptGeneralTerms() {
		SharedMainViewModel.shared.changeGeneralTerms()
		self.isShowPopup.toggle()
		switch linkActive {
		case "SIP":
			self.isLinkSIPActive = true
		case "REG":
			self.isLinkREGActive = true
		default:
			print("Link Not Active")
		}
	}
}

#Preview {
	LoginFragment()
}
