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

class ESSymptomsViewController: DynamicTableViewController {

	// MARK: - Attributes.

	private weak var coordinator: ExposureSubmissionCoordinator?
	private var selectedOption: Options? {
		didSet {
			// TODO: Debug code.
			print("Selected option: \(String(describing: selectedOption))")
		}
	}

	// MARK: - Initializers.

	init(coordinator: ExposureSubmissionCoordinator) {
		self.coordinator = coordinator
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View lifecycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Symptom-Beginn"
		dynamicTableViewModel = .symptomsStartModel()
		tableView.register(CalendarCell.self, forCellReuseIdentifier: CellReuseIdentifier.calendar.rawValue)
		tableView.register(ESOptionCell.self, forCellReuseIdentifier: CellReuseIdentifier.symptoms.rawValue)
	}

	// MARK: - UITableViewDelegate methods.

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) as? ESOptionCell else { return }
		selectedOption = cell.option
	}
}

private extension DynamicTableViewModel {
	static func symptomsStartModel() -> DynamicTableViewModel {
		.with {
			$0.add(
				.section(
					cells: [
						.title2(
							text: "Wann sind die Symptome bei Ihnen aufgetreten?",
							accessibilityIdentifier: "TODO"),
						.body(
							text: "Selektieren sie entweder das genaue Datum in dem Kalender oder wenn Sie sich nicht genau erinnern, eine der anderen Optionen.",
							accessibilityIdentifier: "TODO"
						),
						.calendar(),
						.option(text: "In den letzten 7 Tagen", option: .lastSevenDays),
						.option(text: "Vor 1-2 Wochen", option: .oneToTwoWeeks),
						.option(text: "Vor mehr als 2 Wochen", option: .moreThanTwoWeeks),
						.option(text: "Keine Angabe", option: .noInformation)
					]
				)
			)
		}
	}
}

extension ESSymptomsViewController {
	enum CellReuseIdentifier: String, TableViewCellReuseIdentifiers {
		case calendar = "calendarCell"
		case symptoms = "symptomsCell"
	}
}

private extension DynamicCell {
	static func calendar() -> Self {
		.identifier(ESSymptomsViewController.CellReuseIdentifier.calendar,
					action: .none,
					accessoryAction: .none) { _, cell, _ in
						guard let cell = cell as? CalendarCell else { return }

						// TODO: Do some setup here.
		}
	}
}

private extension DynamicCell {
	static func option(text: String, option: ESSymptomsViewController.Options) -> Self {
		.custom(
		withIdentifier: ESSymptomsViewController.CellReuseIdentifier.symptoms,
		action: .none,
		accessoryAction: .none
		) { _, cell, _ in
			guard let cell = cell as? ESOptionCell else { return }
			cell.configure(text: text, option: option)
		}
	}
}

extension ESSymptomsViewController {
	enum Options {
		case date(Date)
		case lastSevenDays
		case oneToTwoWeeks
		case moreThanTwoWeeks
		case noInformation
	}
}
