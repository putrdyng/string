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

import UIKit
import ExposureNotification

class DMEUFunctionViewController: UIViewController {

	let textView = UITextView()
	let benchmark = Benchmark()
	let client: Client
	let exposureDetector: ExposureDetector
	let downloadedPackagesStore = DownloadedPackagesSQLLiteStore(fileName: "EU_Test")

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .white
		createViews()
        // Do any additional setup after loading the view.
    }


	init(
		client: Client,
		exposureDetector: ExposureDetector
	) {
		self.client = client
		self.exposureDetector = exposureDetector
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

// MARK: Buttons Logic
extension DMEUFunctionViewController {

	@objc
	private func resetDidTap(_ sender: UIButton) {

	}

	@objc
	private func downloadBtnDidTap(_ sender: UIButton) {
		logMessage("Start to download the days.")

		benchmark.start()
		client.availableDays {[weak self] result in
			switch result {
			case let .success(days):
				self?.downloadKeys(for: days)
			case .failure:
				self?.logMessage("Fail to download the text.")
			}
		}
	}

	@objc
	private func calcRiskBtnDidTap(_ sender: UIButton) {

		let bm = Benchmark()
		bm.start()
		logMessage("Start to download Configuration.")
		client.exposureConfiguration { config in
			guard let exposureConfig = config else {
				self.logMessage("Fail to download the ExposureConfig file.", isError: true)
				return
			}
			self.logMessage("Finish downloading Configuration.")
			self.logMessage("Start to calculate risk level.")
			guard let urls = self.writtenPackages()?.urls else {
				self.logMessage("Fail to get the urls")
				return
			}


			_ = self.exposureDetector.detectExposures(
					configuration: exposureConfig,
					diagnosisKeyURLs: urls
			) { _, error in
				if let error = error as? ENError {
					self.logMessage("Error occurs while calculating risk level. The error code is \(error.errorCode)", isError: true)
					return
				}
				self.logMessage("✅ Finish calculating risk level. It takes \(bm.end()) seconds")
			}
		}
	}
	
	private func downloadKeys(for days: [String]) {
		let daysToDownload = days.joined(separator: "\n")
		logMessage("There are \(days.count) Keys. Days to download: \(daysToDownload)")
		logMessage("Start to download key packages... ")
		client.fetchDays(days) { daysResult in
			self.logMessage("✅ Finish download the result. It takes \(self.benchmark.end()) seconds")
			let hoursResult = HoursResult(errors: [], bucketsByHour: [:], day: "")
			let daysAndHours = FetchedDaysAndHours(hours: hoursResult, days: daysResult)
			self.logMessage("Persisting the packages")
			self.downloadedPackagesStore.addFetchedDaysAndHours(daysAndHours)
			self.logMessage("✅ Persisting is done!")
		}
	}
}

// MARK: Helper methods
extension DMEUFunctionViewController {
	private func logMessage(_ message: String, isError: Bool = false) {
		DispatchQueue.main.async {
			if isError {
				self.textView.text.append("❌")
			}
			self.textView.text.append(message)
			self.textView.text.append("\n")
		}
	}


	private func writtenPackages() -> WrittenPackages? {
		let fileManager = FileManager()
		let rootDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		do {
			try fileManager.createDirectory(at: rootDir, withIntermediateDirectories: true, attributes: nil)
			let packages = downloadedPackagesStore.allPackages(for: .formattedToday(), onlyHours: false)
			let writer = AppleFilesWriter(rootDir: rootDir, keyPackages: packages)
			return writer.writeAllPackages()
		} catch {
			logMessage("Fail to create WrittenPackages", isError: true)
			return nil
		}
	}
}


// MARK: Create the Views
extension DMEUFunctionViewController {

	private func createViews() {
		//Download Button
		let downloadBtn = UIButton(type: .roundedRect)
		downloadBtn.translatesAutoresizingMaskIntoConstraints = false
		downloadBtn.setTitle("Download", for: .normal)
		downloadBtn.addTarget(self, action: #selector(downloadBtnDidTap(_:)), for: .touchUpInside)
		view.addSubview(downloadBtn)
		downloadBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		downloadBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true


		//Risk calculation button
		let checkBtn = UIButton(type: .roundedRect)
		checkBtn.translatesAutoresizingMaskIntoConstraints = false
		checkBtn.setTitle("Check Risk", for: .normal)
		checkBtn.addTarget(self, action: #selector(calcRiskBtnDidTap(_:)), for: .touchUpInside)
		view.addSubview(checkBtn)
		checkBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		checkBtn.leadingAnchor.constraint(equalTo: downloadBtn.trailingAnchor, constant: 40).isActive = true

		//Reset button
		let resetBtn = UIButton(type: .roundedRect)
		resetBtn.translatesAutoresizingMaskIntoConstraints = false
		resetBtn.setTitle("Reset", for: .normal)
		resetBtn.addTarget(self, action: #selector(resetDidTap(_:)), for: .touchUpInside)
		view.addSubview(resetBtn)
		resetBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		resetBtn.leadingAnchor.constraint(equalTo: checkBtn.trailingAnchor, constant: 40).isActive = true


		textView.translatesAutoresizingMaskIntoConstraints = false
		textView.isEditable = false
		view.addSubview(textView)
		textView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		textView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10).isActive = true
		textView.topAnchor.constraint(equalTo: checkBtn.bottomAnchor, constant: 10).isActive = true
	}
}


class Benchmark {
	private var startTime: TimeInterval = 0
	func start() {
		startTime = Date().timeIntervalSince1970
	}
	func end() -> TimeInterval {
		Date().timeIntervalSince1970 - startTime
	}
}
