// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import BackgroundTasks
import ExposureNotification
import UIKit

enum ENATaskIdentifier: String, CaseIterable {
	// only one task identifier is allowed have the .exposure-notification suffix
	case exposureNotification = "exposure-notification"

	var backgroundTaskSchedulerIdentifier: String {
		guard let bundleID = Bundle.main.bundleIdentifier else { return "invalid-task-id!" }
		return "\(bundleID).\(rawValue)"
	}
}

protocol ENATaskExecutionDelegate: AnyObject {
	func executeENABackgroundTask(task: BGTask, completion: @escaping ((Bool) -> Void))
}

/// - NOTE: To simulate the execution of a background task, use the following:
///         e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"de.rki.coronawarnapp-dev.exposure-notification"]
final class ENATaskScheduler {

	// MARK: - Static.

	static let shared = ENATaskScheduler()

	// MARK: - Attributes.

	weak var delegate: ENATaskExecutionDelegate?

	// MARK: - Initializer.

	private init() {
		registerTask(with: .exposureNotification, execute: exposureNotificationTask(_:))
		ENATaskScheduler.showNotification(
			title: "ENATaskScheduler",
			subtitle: "Initialized!",
			body: "You can now put the app in the background."
		)
	}

	// MARK: - Task registration.
	
	private func registerTask(with taskIdentifier: ENATaskIdentifier, execute: @escaping ((BGTask) -> Void)) {
		let identifierString = taskIdentifier.backgroundTaskSchedulerIdentifier
		BGTaskScheduler.shared.register(forTaskWithIdentifier: identifierString, using: .main) { task in
			task.expirationHandler = {
				task.setTaskCompleted(success: false)
			}
			// Make sure to set expiration handler before doing any work.
			execute(task)
		}
	}

	// MARK: - Task scheduling.

	func scheduleTask() {
		do {
			let taskRequest = BGProcessingTaskRequest(identifier: ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier)
			taskRequest.requiresNetworkConnectivity = true
			taskRequest.requiresExternalPower = false
			taskRequest.earliestBeginDate = nil
			try BGTaskScheduler.shared.submit(taskRequest)
			ENATaskScheduler.showNotification(
				title: "ENATaskScheduler",
				subtitle: "Scheduled!",
				body: "A task with the identifier \(ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier) was submitted."
			)
		} catch {
			logError(message: "ERROR: scheduleTask() could NOT submit task request: \(error)")
		}
	}

	// MARK: - Task execution handlers.

	private func exposureNotificationTask(_ task: BGTask) {
		ENATaskScheduler.showNotification(
			title: "ENATaskScheduler",
			subtitle: "Task triggered!",
			body: ""
		)

		delegate?.executeENABackgroundTask(task: task) { success in
			task.setTaskCompleted(success: success)
			ENATaskScheduler.showNotification(
				title: "ENATaskScheduler",
				subtitle: "Task done!",
				body: "A task with the identifier \(ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier) was set to completed."
			)
			self.scheduleTask()
		}
	}

	// MARK: - Util.

	static func showNotification(
		title: String,
		subtitle: String,
		body: String,
		notificationIdentifier: String = "com.sap.ios.cwa.background-test.\(UUID().uuidString)"
	) {
			let content = UNMutableNotificationContent()
			content.title = title
			content.subtitle = subtitle
			content.body = body

			let trigger = UNTimeIntervalNotificationTrigger(
				timeInterval: 1,
				repeats: false
			)

			let request = UNNotificationRequest(
				identifier: notificationIdentifier,
				content: content,
				trigger: trigger
			)

			UNUserNotificationCenter.current().add(request) { error in
				guard let error = error else { return }
				logError(message: "There was an error scheduling the local notification. \(error.localizedDescription)")
			}
	}
}
