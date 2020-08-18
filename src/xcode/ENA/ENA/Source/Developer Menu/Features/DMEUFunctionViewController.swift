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

class DMEUFunctionViewController: UIViewController {

	let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .white
		createViews()

        // Do any additional setup after loading the view.
    }
    

	// MARK: Creating an Errors View Controller
	init() {
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension DMEUFunctionViewController {

	private func createViews() {
		let downloadBtn = UIButton(type: .roundedRect)
		downloadBtn.translatesAutoresizingMaskIntoConstraints = false
		downloadBtn.setTitle("Download", for: .normal)
		downloadBtn.addTarget(self, action: #selector(downloadKey(_:)), for: .touchUpInside)
		view.addSubview(downloadBtn)
		downloadBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		downloadBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true


		let checkBtn = UIButton(type: .roundedRect)
		checkBtn.translatesAutoresizingMaskIntoConstraints = false
		checkBtn.setTitle("Check Risk", for: .normal)
		checkBtn.addTarget(self, action: #selector(calcRisk(_:)), for: .touchUpInside)
		view.addSubview(checkBtn)
		checkBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		checkBtn.leadingAnchor.constraint(equalTo: downloadBtn.trailingAnchor, constant: 40).isActive = true


		textView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(textView)
		textView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		textView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10).isActive = true
		textView.topAnchor.constraint(equalTo: checkBtn.bottomAnchor, constant: 10).isActive = true

		textView.text = "I love to test some thing."
	}



	@objc
	func downloadKey(_ sender: UIButton) {
		
	}


	@objc
	func calcRisk(_ sender: UIButton) {

	}

}
