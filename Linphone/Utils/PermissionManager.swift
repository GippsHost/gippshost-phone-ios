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

import Foundation
import Contacts
import UserNotifications
import SwiftUI
import AVFoundation

class PermissionManager: ObservableObject {
	
	static let shared = PermissionManager()
	
	@Published var pushPermissionGranted = false
	@Published var contactsPermissionGranted = false
	@Published var microphonePermissionGranted = false
	@Published var allPermissionsHaveBeenDisplayed = false
	
	private init() {}

	/// Checks the permissions needed for the core calling experience when the app starts.
	/// Camera and Photos are optional and are requested by the features that use them.
	/// New core permissions are requested with the system sheet. Core permissions that
	/// were previously denied are returned so the app can offer a shortcut to Settings.
	func checkPermissionsOnAppLoad(completion: @escaping ([String]) -> Void) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
			let contactsStatus = CNContactStore.authorizationStatus(for: .contacts)

			let hasUndeterminedPermission = settings.authorizationStatus == .notDetermined
				|| microphoneStatus == .undetermined
				|| contactsStatus == .notDetermined

			if hasUndeterminedPermission {
				DispatchQueue.main.async {
					self.getPermissions()
					completion([])
				}
				return
			}

			var missingPermissions: [String] = []
			if settings.authorizationStatus == .denied {
				missingPermissions.append("Notifications")
			}
			if microphoneStatus == .denied {
				missingPermissions.append("Microphone")
			}
			if contactsStatus == .denied {
				missingPermissions.append("Contacts")
			}

			DispatchQueue.main.async {
				completion(missingPermissions)
			}
		}
	}
	
	func getPermissions() {
		pushNotificationRequestPermission {
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			self.microphoneRequestPermission()
			self.contactsRequestPermission(group: dispatchGroup)
			
			dispatchGroup.notify(queue: .main) {
				self.allPermissionsHaveBeenDisplayed = true
			}
		}
	}
	
	func pushNotificationRequestPermission(completion: @escaping () -> Void) {
		let options: UNAuthorizationOptions = [.alert, .sound, .badge]
		UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
			if let error = error {
				Log.error("Unexpected error when asking for Push permission : \(error.localizedDescription)")
			}
			DispatchQueue.main.async {
				self.pushPermissionGranted = granted
			}
			completion()
		}
	}
	
	func microphoneRequestPermission() {
		AVAudioSession.sharedInstance().requestRecordPermission({ granted in
			DispatchQueue.main.async {
				self.microphonePermissionGranted = granted
			}
		})
	}
	
	func contactsRequestPermission(group: DispatchGroup) {
		let store = CNContactStore()
		store.requestAccess(for: .contacts) { success, _ in
			DispatchQueue.main.async {
				self.contactsPermissionGranted = success
			}
			group.leave()
		}
	}
	
	func havePermissionsAlreadyBeenRequested() {
		let micStatus = AVAudioSession.sharedInstance().recordPermission
		let contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
		
		let notifGroup = DispatchGroup()
		var notifStatus: UNAuthorizationStatus = .notDetermined
		
		notifGroup.enter()
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			notifStatus = settings.authorizationStatus
			notifGroup.leave()
		}
		
		notifGroup.notify(queue: .main) {
			let allAlreadyRequested = micStatus != .undetermined &&
									  contactsStatus != .notDetermined &&
									  notifStatus != .notDetermined
			
			if allAlreadyRequested {
				self.allPermissionsHaveBeenDisplayed = true
			}
		}
	}

}
