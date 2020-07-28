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

/// TODO: Accessibility check.
class ESOptionCell: UITableViewCell {

	// MARK: - Attributes.

	private(set) var option: ESSymptomsViewController.Options?
	private let view: UIView
	private let selectionLabel: ENALabel
	private let selectionImage: UIImageView

	private let minimumHeight: CGFloat = 100
	private let inset: CGFloat = 20

	// MARK: - Initializers.

	/// - TODO: Cleanup.
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

		view = UIView()
		view.backgroundColor = .enaColor(for: .background)
		view.layer.cornerRadius = 8
		view.layer.shadowColor = UIColor.enaColor(for: .shadow).cgColor
		view.layer.shadowOffset = .init(width: 0, height: 2)
		view.layer.shadowOpacity = 1.0
		view.layer.shadowRadius = 4

		selectionImage = UIImageView()
		selectionImage.contentMode = .scaleAspectFit
		selectionImage.tintColor = .enaColor(for: .tint)

		selectionLabel = ENALabel(frame: .zero)
		selectionLabel.style = .headline
		selectionLabel.numberOfLines = 0

		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.selectionStyle = .none

		view.translatesAutoresizingMaskIntoConstraints = false
		selectionImage.translatesAutoresizingMaskIntoConstraints = false
		selectionLabel.translatesAutoresizingMaskIntoConstraints = false

		addSubview(view)
		view.addSubview(selectionLabel)
		view.addSubview(selectionImage)

		// View container constraints.

		view.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
		view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
		view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
		view.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
		view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

		// Content constraints.

		view.topAnchor.constraint(equalTo: selectionLabel.topAnchor, constant: -inset).isActive = true
		view.bottomAnchor.constraint(equalTo: selectionLabel.bottomAnchor, constant: inset).isActive = true
		selectionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		selectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset).isActive = true

		// Make sure text and label cannot overlap.
		selectionLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionImage.leadingAnchor, constant: -inset).isActive = true
		selectionImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset).isActive = true
		selectionImage.widthAnchor.constraint(equalToConstant: 20).isActive = true
		selectionImage.heightAnchor.constraint(equalToConstant: 20).isActive = true
		selectionImage.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Configuration methods.

	func configure(text: String, option: ESSymptomsViewController.Options) {
		selectionLabel.text = text
		self.option = option
		didDeselect()
	}

	func didSelect() {
		view.layer.borderWidth = 2
		view.layer.borderColor = UIColor.enaColor(for: .buttonPrimary).cgColor
		selectionImage.image = UIImage(systemName: "circle.fill")
	}

	func didDeselect() {
		view.layer.borderWidth = 1
		view.layer.borderColor = UIColor.enaColor(for: .shadow).cgColor
		selectionImage.image = UIImage(systemName: "circle")
	}
}
