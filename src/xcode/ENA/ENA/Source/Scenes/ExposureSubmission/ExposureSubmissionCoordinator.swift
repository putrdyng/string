//
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
//

import Foundation
import UIKit

protocol ExposureSubmissionCoordinator {

	// MARK: - Attributes.
	var delegate: ExposureSubmissionCoordinatorDelegate? { get set }
	var testResult: TestResult? { get set }

	// MARK: - Navigation.

	func start()
	func dismiss()

	func showOverviewScreen()
	func showTestResultScreen(with result: TestResult)
	func showHotlineScreen()
	func showTanScreen()
	func showQRScreen(qrScannerDelegate: ExposureSubmissionQRScannerDelegate)
	func showWarnOthersScreen()
	func showThankYouScreen()


	// MARK: - Buttons.
}

protocol ExposureSubmissionCoordinatorDelegate: class {
	func exposureSubmissionCoordinatorWillDisappear(_ coordinator: ExposureSubmissionCoordinator)
}

protocol ExposureSubmissionCoordinatorViewController {
	var coordinator: ExposureSubmissionCoordinator? { get set }
}

class ESCoordinator: ExposureSubmissionCoordinator {

	// MARK: - Attributes.

	weak var delegate: ExposureSubmissionCoordinatorDelegate?
	weak var parentNavigationController: UINavigationController?
	weak var navigationController: UINavigationController?
	weak var exposureSubmissionService: ExposureSubmissionService?
	var testResult: TestResult?

	// MARK: - Initializers.

	init(
		parentNavigationController: UINavigationController,
		exposureSubmissionService: ExposureSubmissionService,
		testResult: TestResult? = nil,
		delegate: ExposureSubmissionCoordinatorDelegate? = nil
	) {
		self.parentNavigationController = parentNavigationController
		self.exposureSubmissionService = exposureSubmissionService
		self.testResult = testResult
		self.delegate = delegate
	}
}

// MARK: - Creation.

extension ESCoordinator {

	private func createNavigationController() -> ExposureSubmissionNavigationController {
		return AppStoryboard.exposureSubmission.initiateInitial { coder in
			ExposureSubmissionNavigationController(coder: coder, coordinator: self)
		}
	}

	private func createIntroViewController() -> ExposureSubmissionIntroViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionIntroViewController.self) { coder -> UIViewController? in
			ExposureSubmissionIntroViewController(coder: coder, coordinator: self)
		}
	}

	private func createOverviewViewController() -> ExposureSubmissionOverviewViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionOverviewViewController.self) { coder in
			ExposureSubmissionOverviewViewController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
		}

	}

	private func createTanInputViewController() -> ExposureSubmissionTanInputViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionTanInputViewController.self) { coder -> UIViewController? in
			ExposureSubmissionTanInputViewController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
		}
	}

	private func createHotlineViewController() -> ExposureSubmissionHotlineViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionHotlineViewController.self) { coder -> UIViewController? in
			ExposureSubmissionHotlineViewController(coder: coder, coordinator: self)
		}
	}

	private func createTestResultViewController(with result: TestResult) -> ExposureSubmissionTestResultViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionTestResultViewController.self) { coder -> UIViewController? in
			ExposureSubmissionTestResultViewController(
				coder: coder,
				coordinator: self,
				exposureSubmissionService: self.exposureSubmissionService,
				testResult: result
			)
		}
	}

	private func createQRScannerViewController(qrScannerDelegate: ExposureSubmissionQRScannerDelegate) -> ExposureSubmissionQRScannerNavigationController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionQRScannerNavigationController.self) { coder -> UIViewController? in
			let vc = ExposureSubmissionQRScannerNavigationController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
			vc?.scannerViewController?.delegate = qrScannerDelegate
			return vc
		}
	}

	private func createWarnOthersViewController() -> ExposureSubmissionWarnOthersViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionWarnOthersViewController.self) { coder -> UIViewController? in
			ExposureSubmissionWarnOthersViewController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
		}
	}

	private func createSuccessViewController() -> ExposureSubmissionSuccessViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionSuccessViewController.self) { coder -> UIViewController? in
			ExposureSubmissionSuccessViewController(coder: coder, coordinator: self)
		}
	}
}

// MARK: - Navigation.

extension ESCoordinator {
	
	// MARK: - Helpers.

	private func push(_ vc: UIViewController) {
		self.navigationController?.pushViewController(vc, animated: true)
	}

	private func present(_ vc: UIViewController) {
		self.navigationController?.present(vc, animated: true)
	}

	private func getRootViewController() -> UIViewController {
		#if UITESTING
		if ProcessInfo.processInfo.arguments.contains("-negativeResult") {
			return createTestResultViewController(with: .negative)
		}

		#else
		// We got a test result and can jump straight into the test result view controller.
		if let service = exposureSubmissionService, testResult != nil, service.hasRegistrationToken() {
			// swiftlint:disable:next force_unwrapping
			return createTestResultViewController(with: testResult!)
		}
		#endif

		// By default, we show the intro view.
		return createIntroViewController()
	}

	// MARK: - Public API.

	func start() {
		let vc = getRootViewController()
		guard let parentNavigationController = parentNavigationController else {
			log(message: "Parent navigation controller not set.", level: .error, file: #file, line: #line, function: #function)
			return
		}

		let navigationController = createNavigationController()
		navigationController.setViewControllers([vc], animated: false)
		parentNavigationController.present(navigationController, animated: true)
		self.navigationController = navigationController
	}

	func dismiss() {
		navigationController?.dismiss(animated: true)
	}

	func showOverviewScreen() {
		let vc = createOverviewViewController()
		push(vc)
	}

	// TODO: HANDLING OF THE TEST RESULT ?
	func showTestResultScreen(with result: TestResult) {
		let vc = createTestResultViewController(with: result)
		push(vc)
	}

	func showHotlineScreen() {
		let vc = createHotlineViewController()
		push(vc)
	}
	func showTanScreen() {
		let vc = createTanInputViewController()
		push(vc)
	}

	func showQRScreen(qrScannerDelegate: ExposureSubmissionQRScannerDelegate) {
		let vc = createQRScannerViewController(qrScannerDelegate: qrScannerDelegate)
		present(vc)
	}

	func showWarnOthersScreen() {
		let vc = createWarnOthersViewController()
		push(vc)
	}

	func showThankYouScreen() {
		let vc = createSuccessViewController()
		push(vc)
	}
}
