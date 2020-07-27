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
		title = "Title"
		dynamicTableViewModel = .symptomsStartModel()
		tableView.register(CalendarCell.self, forCellReuseIdentifier: CellReuseIdentifier.calendar.rawValue)
	}
}

private extension DynamicTableViewModel {
	static func symptomsStartModel() -> DynamicTableViewModel {
		.with {
			$0.add(
				.section(
					header: DynamicHeader.text("Header"),
					cells: [
						.body(text: "Body",
							  accessibilityIdentifier: "TODO"),
						.calendar()
					]
				)
			)
		}
	}
}

extension ESSymptomsViewController {
	enum CellReuseIdentifier: String, TableViewCellReuseIdentifiers {
		case calendar = "calendarCell"
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
