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

import ExposureNotification
import UIKit

final class HomeViewController: UIViewController {

	// MARK: - View-related properties.

	private var sectionConfigurations: SectionConfiguration = []
	private var dataSource: UICollectionViewDiffableDataSource<Section, AnyHashable>?
	private var collectionView: UICollectionView! { view as? UICollectionView }

	// MARK: - Delegate

	private weak var delegate: HomeViewControllerDelegate?

	// MARK: - State-bound properties.
	var state: State {
		didSet {
			setStateOfChildViewControllers()
			scheduleCountdownTimer()
			setupSections()
		}
	}
	private(set) var isRequestRiskRunning = false
	var enStateHandler: ENStateHandler?

	// MARK: - Configurators.

	private var activeConfigurator: HomeActivateCellConfigurator!
	private var testResultConfigurator = HomeTestResultCellConfigurator()
	private var riskLevelConfigurator: HomeRiskLevelCellConfigurator?
	private var inactiveConfigurator: HomeInactiveRiskCellConfigurator?
	private var countdownTimer: CountdownTimer?

	private(set) var testResult: TestResult?
	private let exposureSubmissionService: ExposureSubmissionService

	// MARK: - Creating a Home View Controller

	init?(
		coder: NSCoder,
		delegate: HomeViewControllerDelegate,
		detectionMode: DetectionMode,
		exposureManagerState: ExposureManagerState,
		initialEnState: ENStateHandler.State,
		risk: Risk?,
		exposureSubmissionService: ExposureSubmissionService
	) {
		self.delegate = delegate
		self.exposureSubmissionService = exposureSubmissionService
		self.state = State(
			detectionMode: detectionMode,
			exposureManagerState: exposureManagerState,
			enState: initialEnState,
			risk: risk)
		super.init(coder: coder)
		navigationItem.largeTitleDisplayMode = .never
		delegate.addToUpdatingSetIfNeeded(self)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has intentionally not been implemented")
	}

	// MARK: UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		configureCollectionView()
		configureDataSource()
		setupAccessibility()

		setupSections()
		// updateSections()
		applySnapshotFromSections()

		setStateOfChildViewControllers()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateTestResults()
		updateRisk(userInitiated: false)
		updateBackgroundColor()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateBackgroundColor()
	}

	private func setupAccessibility() {
		navigationItem.leftBarButtonItem?.customView = UIImageView(image: navigationItem.leftBarButtonItem?.image)
		navigationItem.leftBarButtonItem?.isAccessibilityElement = true
		navigationItem.leftBarButtonItem?.accessibilityTraits = .none
		navigationItem.leftBarButtonItem?.accessibilityLabel = AppStrings.Home.leftBarButtonDescription
		navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Home.leftBarButtonDescription
		navigationItem.rightBarButtonItem?.isAccessibilityElement = true
		navigationItem.rightBarButtonItem?.accessibilityLabel = AppStrings.Home.rightBarButtonDescription
		navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Home.rightBarButtonDescription
	}

	// MARK: Actions

	@IBAction private func infoButtonTapped() {
		delegate?.showRiskLegend()
	}

	// MARK: Misc

	// Called by HomeInteractor
	func setStateOfChildViewControllers() {
		delegate?.setExposureDetectionState(state: state, isRequestRiskRunning: isRequestRiskRunning)
	}

	func updateState(detectionMode: DetectionMode, exposureManagerState: ExposureManagerState, risk: Risk?) {
		state.detectionMode = detectionMode
		state.exposureManagerState = exposureManagerState
		state.risk = risk

		reloadData(animatingDifferences: false)
	}

	func showExposureSubmissionWithoutResult() {
		showExposureSubmission()
	}

	func showExposureSubmission(with result: TestResult? = nil) {
		delegate?.showExposureSubmission(with: result)
	}

	func showExposureNotificationSetting() {
		delegate?.showExposureNotificationSetting(enState: state.enState)
	}

	func showExposureDetection() {
		delegate?.showExposureDetection(state: state, isRequestRiskRunning: isRequestRiskRunning)
	}

	private func showScreenForActionSectionForCell(at indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath)
		switch cell {
		case is ActivateCollectionViewCell:
			showExposureNotificationSetting()
		case is RiskLevelCollectionViewCell:
		 	showExposureDetection()
		case is RiskFindingPositiveCollectionViewCell:
			showExposureSubmission(with: testResult)
		case is HomeTestResultCollectionViewCell:
			showExposureSubmission(with: testResult)
		case is RiskInactiveCollectionViewCell:
			showExposureDetection()
		case is RiskThankYouCollectionViewCell:
			return
		default:
			log(message: "Unknown cell type tapped.", file: #file, line: #line, function: #function)
			return
		}
	}

	private func showScreen(at indexPath: IndexPath) {
		guard let section = Section(rawValue: indexPath.section) else { return }
		let row = indexPath.row
		switch section {
		case .actions:
			showScreenForActionSectionForCell(at: indexPath)
		case .infos:
			if row == 0 {
				delegate?.showInviteFriends()
			} else {
				delegate?.showWebPage(from: self, urlString: AppStrings.SafariView.targetURL)
			}
		case .settings:
			if row == 0 {
				delegate?.showAppInformation()
			} else {
				delegate?.showSettings(enState: state.enState)
			}
		}
	}

	// MARK: Configuration

	func reloadData(animatingDifferences: Bool) {
		// updateSections()
		applySnapshotFromSections(animatingDifferences: animatingDifferences)
	}

	func reloadCell(at indexPath: IndexPath) {
		guard let snapshot = dataSource?.snapshot() else { return }
		guard let cell = collectionView.cellForItem(at: indexPath) else { return }
		sectionConfigurations[indexPath.section].cellConfigurators[indexPath.item].configureAny(cell: cell)
		dataSource?.apply(snapshot, animatingDifferences: true)
	}

	private func configureCollectionView() {
		collectionView.collectionViewLayout = .homeLayout(delegate: self)
		collectionView.delegate = self

		collectionView.contentInset = UIEdgeInsets(top: UICollectionViewLayout.topInset, left: 0, bottom: -UICollectionViewLayout.bottomBackgroundOverflowHeight, right: 0)

		collectionView.isAccessibilityElement = false
		collectionView.shouldGroupAccessibilityChildren = true

		let cellTypes: [UICollectionViewCell.Type] = [
			ActivateCollectionViewCell.self,
			RiskLevelCollectionViewCell.self,
			InfoCollectionViewCell.self,
			HomeTestResultCollectionViewCell.self,
			RiskInactiveCollectionViewCell.self,
			RiskFindingPositiveCollectionViewCell.self,
			RiskThankYouCollectionViewCell.self,
			InfoCollectionViewCell.self,
			HomeTestResultLoadingCell.self
		]

		collectionView.register(cellTypes: cellTypes)
	}

	private func configureDataSource() {
		dataSource = UICollectionViewDiffableDataSource<Section, AnyHashable>(collectionView: collectionView) { [unowned self] collectionView, indexPath, _ in
			let configurator = self.sectionConfigurations[indexPath.section].cellConfigurators[indexPath.row]
			let cell = collectionView.dequeueReusableCell(cellType: configurator.viewAnyType, for: indexPath)
			cell.unhighlight()
			configurator.configureAny(cell: cell)
			return cell
		}
	}

	func applySnapshotFromSections(animatingDifferences: Bool = false) {
		var snapshot = NSDiffableDataSourceSnapshot<Section, AnyHashable>()
		for sectionConfiguration in sectionConfigurations {
			snapshot.appendSections([sectionConfiguration.section])
			snapshot.appendItems(sectionConfiguration.cellConfigurators.map { $0.hashValue })
		}
		dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
	}

	private func updateBackgroundColor() {
		collectionView.backgroundColor = .backgroundColor(for: traitCollection.userInterfaceStyle)
	}

	func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
		return self.collectionView.cellForItem(at: indexPath)
	}
}

// MARK: - Update test state.

extension HomeViewController {
	func showTestResultScreen() {
		showExposureSubmission(with: testResult)
	}

	func updateTestResultState() {
		reloadActionSection()
		updateTestResults()
	}
}

extension HomeViewController: HomeLayoutDelegate {
	func homeLayoutSection(for sectionIndex: Int) -> Section? {
		Section(rawValue: sectionIndex)
	}
}

extension HomeViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		let cell = collectionView.cellForItem(at: indexPath)
		switch cell {
		case is RiskThankYouCollectionViewCell: return false
		default: return true
		}
	}

	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
		collectionView.cellForItem(at: indexPath)?.highlight()
	}

	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
		collectionView.cellForItem(at: indexPath)?.unhighlight()
	}

	func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		showScreen(at: indexPath)
	}
}

extension HomeViewController: ExposureStateUpdating {
	func updateExposureState(_ state: ExposureManagerState) {
		self.state.exposureManagerState = state
		reloadData(animatingDifferences: false)
	}
}

extension HomeViewController: ENStateHandlerUpdating {
	func updateEnState(_ state: ENStateHandler.State) {
		self.state.enState = state
		activeConfigurator.updateEnState(state)
		updateActiveCell()
		reloadData(animatingDifferences: false)
	}
}

extension HomeViewController: NavigationBarOpacityDelegate {
	var preferredNavigationBarOpacity: CGFloat {
		let alpha = (collectionView.adjustedContentInset.top + collectionView.contentOffset.y) / collectionView.contentInset.top
		return max(0, min(alpha, 1))
	}
}

private extension UICollectionViewCell {
	func highlight() {
		let highlightView = UIView(frame: bounds)
		highlightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		highlightView.backgroundColor = .enaColor(for: .listHighlight)
		highlightView.tag = 100_000
		highlightView.clipsToBounds = true

		if let homeCollectionViewCell = self as? HomeCardCollectionViewCell {
			highlightView.layer.cornerRadius = homeCollectionViewCell.contentView.layer.cornerRadius
		}
		addSubview(highlightView)
	}

	func unhighlight() {
		subviews.filter(({ $0.tag == 100_000 })).forEach({ $0.removeFromSuperview() })
	}
}

extension HomeViewController: RequiresAppDependencies {
	typealias SectionDefinition = (section: HomeViewController.Section, cellConfigurators: [CollectionViewCellConfiguratorAny])
	typealias SectionConfiguration = [SectionDefinition]

	private func updateActiveCell() {
		guard let indexPath = indexPathForActiveCell() else { return }
		// homeViewController.updateSections()
		reloadCell(at: indexPath)
	}

	private func updateRiskButton(isEnabled: Bool) {
		riskLevelConfigurator?.updateButtonEnabled(isEnabled)
	}

	private func updateRiskButton(isHidden: Bool) {
		riskLevelConfigurator?.updateButtonHidden(isHidden)
	}

	private func reloadRiskCell() {
		guard let indexPath = indexPathForRiskCell() else { return }
		// homeViewController.updateSections()
		reloadCell(at: indexPath)
	}

	/// Adjusts the risk configurator in a way that the cell is automatically
	/// reloaded by the diffable data source.
	/// - Parameter isLoading: denotes whether the risk cell
	/// is currently in a loading state (i.e. having a spinner) or not.
	func updateRiskCell(isLoading: Bool) {
		self.isRequestRiskRunning = isLoading
		riskLevelConfigurator?.isLoading = isLoading
		applySnapshotFromSections()
	}

	/// This method updates / checks for the current risk level.
	/// - Parameter userInitiated: If the user has tapped on the button in the home screen
	/// (i.e. requested to update the risk manually), `userInitiated` is set to `true`.
	/// if it was triggered from a background task, it would be `false`.
	func updateRisk(userInitiated: Bool) {
		if userInitiated {
			updateRiskCell(isLoading: true)
			riskProvider.requestRisk(userInitiated: userInitiated) { _ in
				self.updateRiskCell(isLoading: false)
			}
		} else {
			riskProvider.requestRisk(userInitiated: userInitiated)
		}

	}

	private func actionSectionDefinition() -> SectionDefinition {
		var actionsConfigurators: [CollectionViewCellConfiguratorAny] = []

		// MARK: - Add cards that are always shown.

		// Active card.
		activeConfigurator = HomeActivateCellConfigurator(state: state.enState)
		actionsConfigurators.append(activeConfigurator)

		// MARK: - Add cards depending on result state.

		if store.lastSuccessfulSubmitDiagnosisKeyTimestamp != nil {
			// This is shown when we submitted keys! (Positive test result + actually decided to submit keys.)
			// Once this state is reached, it cannot be left anymore.

			let thankYou = HomeThankYouRiskCellConfigurator()
			actionsConfigurators.append(thankYou)
			log(message: "Reached end of life state.", file: #file, line: #line, function: #function)

		} else if store.registrationToken != nil {
			// This is shown when we registered a test.
			// Note that the `positive` state has a custom cell and the risk cell will not be shown once the user was tested positive.

			switch self.testResult {
			case .none:
				// Risk card.
				if let risk = setupRiskConfigurator() {
					actionsConfigurators.append(risk)
				}

				// Loading card.
				let testResultLoadingCellConfigurator = HomeTestResultLoadingCellConfigurator()
				actionsConfigurators.append(testResultLoadingCellConfigurator)

			case .positive:
				let findingPositiveRiskCellConfigurator = setupFindingPositiveRiskCellConfigurator()
				actionsConfigurators.append(findingPositiveRiskCellConfigurator)

			default:
				// Risk card.
				if let risk = setupRiskConfigurator() {
					actionsConfigurators.append(risk)
				}

				let testResultConfigurator = setupTestResultConfigurator()
				actionsConfigurators.append(testResultConfigurator)
			}
		} else {
			// This is the default view that is shown when no test results are available and nothing has been submitted.

			// Risk card.
			if let risk = setupRiskConfigurator() {
				actionsConfigurators.append(risk)
			}

			let submitCellConfigurator = setupSubmitConfigurator()
			actionsConfigurators.append(submitCellConfigurator)
		}

		return (.actions, actionsConfigurators)
	}

	private func infoSectionDefinition() -> SectionDefinition {

		let info1Configurator = HomeInfoCellConfigurator(
			title: AppStrings.Home.infoCardShareTitle,
			description: AppStrings.Home.infoCardShareBody,
			position: .first,
			accessibilityIdentifier: AccessibilityIdentifiers.Home.infoCardShareTitle
		)

		let info2Configurator = HomeInfoCellConfigurator(
			title: AppStrings.Home.infoCardAboutTitle,
			description: AppStrings.Home.infoCardAboutBody,
			position: .last,
			accessibilityIdentifier: AccessibilityIdentifiers.Home.infoCardAboutTitle
		)

		return (.infos, [info1Configurator, info2Configurator])
	}

	private func settingsSectionDefinition() -> SectionDefinition {

		let appInformationConfigurator = HomeInfoCellConfigurator(
			title: AppStrings.Home.appInformationCardTitle,
			description: nil,
			position: .first,
			accessibilityIdentifier: AccessibilityIdentifiers.Home.appInformationCardTitle
		)

		let settingsConfigurator = HomeInfoCellConfigurator(
			title: AppStrings.Home.settingsCardTitle,
			description: nil,
			position: .last,
			accessibilityIdentifier: AccessibilityIdentifiers.Home.settingsCardTitle
		)

		return (.settings, [appInformationConfigurator, settingsConfigurator])

	}

	func setupSections() {
		let actionsSection: SectionDefinition = actionSectionDefinition()
		let infoSection: SectionDefinition = infoSectionDefinition()
		let settingsSection: SectionDefinition = settingsSectionDefinition()
		self.sectionConfigurations = [actionsSection, infoSection, settingsSection]
	}

}

extension HomeViewController {
	struct State {
		var detectionMode: DetectionMode
		var exposureManagerState: ExposureManagerState
		var enState: ENStateHandler.State

		var risk: Risk?
		var riskLevel: RiskLevel? { risk?.level }
		var numberRiskContacts: Int {
			risk?.details.numberOfExposures ?? 0
		}

		var daysSinceLastExposure: Int? {
			risk?.details.daysSinceLastExposure
		}
	}
}

// MARK: - Test result cell methods.

extension HomeViewController {

	private func reloadTestResult(with result: TestResult) {
		testResultConfigurator.testResult = result
		reloadActionSection()
		guard let indexPath = indexPathForTestResultCell() else { return }
		reloadCell(at: indexPath)
	}

	func reloadActionSection() {
		sectionConfigurations[0] = actionSectionDefinition()
		reloadData(animatingDifferences: false)
	}
}

// MARK: - Action section setup helpers.

extension HomeViewController {

	// swiftlint:disable:next function_body_length
	func setupRiskConfigurator() -> CollectionViewCellConfiguratorAny? {

		let detectionIsAutomatic = state.detectionMode == .automatic
		let dateLastExposureDetection = state.risk?.details.exposureDetectionDate

		riskLevelConfigurator = nil
		inactiveConfigurator = nil

		let detectionInterval = (riskProvider.configuration.exposureDetectionInterval.day ?? 1) * 24

		let riskLevel: RiskLevel? = state.exposureManagerState.enabled ? state.riskLevel : .inactive

		switch riskLevel {
		case .unknownInitial:
			riskLevelConfigurator = HomeUnknownRiskCellConfigurator(
				isLoading: false,
				lastUpdateDate: nil,
				detectionInterval: detectionInterval,
				detectionMode: state.detectionMode,
				manualExposureDetectionState: riskProvider.manualExposureDetectionState
			)
		case .inactive:
			inactiveConfigurator = HomeInactiveRiskCellConfigurator(
				inactiveType: .noCalculationPossible,
				previousRiskLevel: store.previousRiskLevel,
				lastUpdateDate: dateLastExposureDetection
			)
			inactiveConfigurator?.activeAction = inActiveCellActionHandler

		case .unknownOutdated:
			inactiveConfigurator = HomeInactiveRiskCellConfigurator(
				inactiveType: .outdatedResults,
				previousRiskLevel: store.previousRiskLevel,
				lastUpdateDate: dateLastExposureDetection
			)
			inactiveConfigurator?.activeAction = inActiveCellActionHandler

		case .low:
			riskLevelConfigurator = HomeLowRiskCellConfigurator(
				numberRiskContacts: state.numberRiskContacts,
				numberDays: state.risk?.details.numberOfDaysWithActiveTracing ?? 0,
				totalDays: 14,
				lastUpdateDate: dateLastExposureDetection,
				isButtonHidden: detectionIsAutomatic,
				detectionMode: state.detectionMode,
				manualExposureDetectionState: riskProvider.manualExposureDetectionState,
				detectionInterval: detectionInterval
			)
		case .increased:
			riskLevelConfigurator = HomeHighRiskCellConfigurator(
				numberRiskContacts: state.numberRiskContacts,
				daysSinceLastExposure: state.daysSinceLastExposure,
				lastUpdateDate: dateLastExposureDetection,
				manualExposureDetectionState: riskProvider.manualExposureDetectionState,
				detectionMode: state.detectionMode,
				validityDuration: detectionInterval
			)
		case .none:
			riskLevelConfigurator = nil
		}

		riskLevelConfigurator?.buttonAction = {
			self.updateRisk(userInitiated: true)
		}
		return riskLevelConfigurator ?? inactiveConfigurator
	}

	private func setupTestResultConfigurator() -> HomeTestResultCellConfigurator {
		testResultConfigurator.primaryAction = showTestResultScreen
		return testResultConfigurator
	}

	func setupSubmitConfigurator() -> HomeTestResultCellConfigurator {
		let submitConfigurator = HomeTestResultCellConfigurator()
		submitConfigurator.primaryAction = showExposureSubmissionWithoutResult
		return submitConfigurator
	}

	func setupFindingPositiveRiskCellConfigurator() -> HomeFindingPositiveRiskCellConfigurator {
		let configurator = HomeFindingPositiveRiskCellConfigurator()
		configurator.nextAction = {
			self.showExposureSubmission(with: self.testResult)
		}
		return configurator
	}
}

// MARK: - IndexPath helpers.

extension HomeViewController {

	private func indexPathForRiskCell() -> IndexPath? {
		for section in sectionConfigurations {
			let index = section.cellConfigurators.firstIndex { cellConfigurator in
				cellConfigurator === self.riskLevelConfigurator
			}
			guard let item = index else { return nil }
			let indexPath = IndexPath(item: item, section: HomeViewController.Section.actions.rawValue)
			return indexPath
		}
		return nil
	}

	private func indexPathForActiveCell() -> IndexPath? {
		for section in sectionConfigurations {
			let index = section.cellConfigurators.firstIndex { cellConfigurator in
				cellConfigurator === self.activeConfigurator
			}
			guard let item = index else { return nil }
			let indexPath = IndexPath(item: item, section: HomeViewController.Section.actions.rawValue)
			return indexPath
		}
		return nil
	}

	private func indexPathForTestResultCell() -> IndexPath? {
		let section = sectionConfigurations.first
		let index = section?.cellConfigurators.firstIndex { cellConfigurator in
			cellConfigurator === self.testResultConfigurator
		}
		guard let item = index else { return nil }
		let indexPath = IndexPath(item: item, section: HomeViewController.Section.actions.rawValue)
		return indexPath
	}
}

// MARK: - Exposure submission service calls.

extension HomeViewController {
	func updateTestResults() {
		// Avoid unnecessary loading.
		guard testResult == nil || testResult != .positive else { return }
		guard store.registrationToken != nil else { return }

		// Make sure to make the loading cell appear for at least `minRequestTime`.
		// This avoids an ugly flickering when the cell is only shown for the fraction of a second.
		// Make sure to only trigger this additional delay when no other test result is present already.
		let requestStart = Date()
		let minRequestTime: TimeInterval = 0.5

		self.exposureSubmissionService.getTestResult { [weak self] result in
			switch result {
			case .failure(let error):
				// When we fail here, trigger an alert and set the state to pending.
				self?.alertError(
					message: error.localizedDescription,
					title: AppStrings.Home.resultCardLoadingErrorTitle,
					completion: {
						self?.testResult = .pending
						self?.reloadTestResult(with: .pending)
					}
				)

			case .success(let result):
				let requestTime = Date().timeIntervalSince(requestStart)
				let delay = requestTime < minRequestTime && self?.testResult == nil ? minRequestTime : 0
				DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
					self?.testResult = result
					self?.reloadTestResult(with: result)
				}
			}
		}
	}
}


extension HomeViewController {
	private func inActiveCellActionHandler() {
		showExposureNotificationSetting()
	}
}

// MARK: - CountdownTimerDelegate methods.

/// The `CountdownTimerDelegate` is used to update the remaining time that is shown on the risk cell button until a manual refresh is allowed.
extension HomeViewController: CountdownTimerDelegate {
	private func scheduleCountdownTimer() {
		guard self.state.detectionMode == .manual else { return }

		// Cleanup potentially existing countdown.
		countdownTimer?.invalidate()
		NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)

		// Schedule new countdown.
		NotificationCenter.default.addObserver(self, selector: #selector(invalidateCountdownTimer), name: UIApplication.didEnterBackgroundNotification, object: nil)
		let nextUpdate = self.riskProvider.nextExposureDetectionDate()
		countdownTimer = CountdownTimer(countdownTo: nextUpdate)
		countdownTimer?.delegate = self
		countdownTimer?.start()
	}

	@objc
	private func invalidateCountdownTimer() {
		countdownTimer?.invalidate()
	}

	func countdownTimer(_ timer: CountdownTimer, didEnd done: Bool) {
		// Reload action section to trigger full refresh of the risk cell configurator (updates
		// the isButtonEnabled attribute).
		self.reloadActionSection()
	}

	func countdownTimer(_ timer: CountdownTimer, didUpdate time: String) {
		guard let indexPath = self.indexPathForRiskCell() else { return }
		guard let cell = cellForItem(at: indexPath) as? RiskLevelCollectionViewCell else { return }

		// We pass the time and let the configurator decide whether the button can be activated or not.
		riskLevelConfigurator?.timeUntilUpdate = time
		riskLevelConfigurator?.configureButton(for: cell)
	}
}

extension HomeViewController {
	enum Section: Int {
		case actions
		case infos
		case settings
	}
}
