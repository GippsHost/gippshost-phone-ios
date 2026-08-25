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
import CoreHaptics
import AudioToolbox

/// Feedback for call controls must never fall back to an audible system sound.
func callControlHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
	guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
	let generator = UIImpactFeedbackGenerator(style: style)
	generator.prepare()
	generator.impactOccurred()
}
	
func touchFeedback() {
	if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
		UIImpactFeedbackGenerator().impactOccurred()
	} else {
		AudioServicesPlaySystemSound(1519) // 1520 and 1521 are gradually stronger
	}
 }
