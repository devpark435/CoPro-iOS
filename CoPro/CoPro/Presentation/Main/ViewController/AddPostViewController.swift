//
//  AddPostViewController.swift
//  CoPro
//
//  Created by 문인호 on 1/26/24.
//

import UIKit
import KeychainSwift
import Photos

class AddPostViewController: UIViewController, SendStringData {
    func sendData(mydata: String, groupId: Int) {
        sortLabel.text = mydata
    }
    
    private enum Const {
        static let numberOfColumns = 3.0
        static let cellSpace = 1.0
        static let length = (UIScreen.main.bounds.size.width - cellSpace * (numberOfColumns - 1)) / numberOfColumns
        static let cellSize = CGSize(width: length, height: length)
        static let scale = UIScreen.main.scale
    }
    private let authService: PhotoAuthManager = MyPhotoAuthManager()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let keychain = KeychainSwift()
    private let sortStackView = UIStackView()
    private let sortLabel = UILabel()
    private let sortButton = UIButton()
    private let titleTextField = UITextField()
    private lazy var contentTextField = UITextView()
    private let attachButton = UIButton()
    private let lineView1 = UIView()
    private let lineView2 = UIView()
    private var imageUrls = [Int]()
    let textViewPlaceHolder = "내용을 입력하세요"
    private let warnView = UIView()
    lazy var remainCountLabel = UILabel()
    private let warnLabel = UILabel()
    private let imageScrollView = UIScrollView()
    var imageViews: [UIImageView] = []
    private let photoService: PhotoManager = MyPhotoManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigate()
        setUI()
        setLayout()
        view.bringSubviewToFront(attachButton)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveImages(_:)), name: NSNotification.Name("SelectedImages"), object: nil)
    }
    
    private func setUI() {
        self.view.backgroundColor = .white
        stackView.do {
            $0.axis = .vertical
            $0.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: .zero, right: 16)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        remainCountLabel.do {
            $0.text = "0/500"
            $0.font = .pretendard(size: 11, weight: .regular)
            $0.textColor = .G4()
            $0.textAlignment = .center
        }
        warnLabel.do {
            $0.text = "500자 이내로 간단히 입력해주세요."
            $0.font = .pretendard(size: 11, weight: .regular)
            $0.textColor = .G4()
        }
        sortStackView.do {
            $0.axis = .horizontal
        }
        sortLabel.do {
            $0.font = UIFont.pretendard(size: 17, weight: .regular)
            $0.text = "게시판 선택"
        }
        sortButton.do {
            $0.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            $0.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
        }
        lineView1.do {
            $0.backgroundColor = UIColor.G1()
        }
        titleTextField.do {
            $0.placeholder = "제목"
            $0.font = .pretendard(size: 17, weight: .bold)
        }
        lineView2.do {
            $0.backgroundColor = UIColor.G1()
        }
        contentTextField.do {
            $0.textContainerInset = UIEdgeInsets(top: 16.0, left: 0, bottom: 16.0, right: 0)
            $0.font = .pretendard(size: 17, weight: .regular)
            $0.text = textViewPlaceHolder
            $0.textColor = .lightGray
            $0.delegate = self
            $0.isScrollEnabled = false
            $0.sizeToFit()
        }
        attachButton.do {
            $0.setImage(UIImage(systemName: "camera.fill"), for: .normal)
            attachButton.addTarget(self, action: #selector(attachButtonTapped), for: .touchUpInside)
            $0.setPreferredSymbolConfiguration(.init(scale: .large), forImageIn: .normal)
            $0.backgroundColor = .lightGray
            $0.tintColor = .white
            $0.layer.cornerRadius = 45 / 2
        }
        imageScrollView.do {
            $0.showsHorizontalScrollIndicator = false
        }
    }
    
    private func setLayout() {
        view.addSubview(attachButton)
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        stackView.addArrangedSubviews(sortStackView, lineView1, titleTextField, lineView2, contentTextField, warnView, imageScrollView)
        imageScrollView.snp.makeConstraints {
            $0.height.equalTo(144)
        }
        sortStackView.snp.makeConstraints {
//            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
//            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(57)
        }
        sortStackView.addSubviews(sortLabel, sortButton)
        sortLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
        }

        sortButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.height.width.equalTo(24)
        }
        lineView1.snp.makeConstraints {
//            $0.top.equalTo(sortStackView.snp.bottom)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(0.5)
        }
        titleTextField.snp.makeConstraints {
//            $0.top.equalTo(lineView1.snp.bottom)
//            $0.leading.equalToSuperview().offset(16)
//            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(57)
        }
        lineView2.snp.makeConstraints {
//            $0.top.equalTo(titleTextField.snp.bottom)
//            $0.leading.equalToSuperview().offset(16)
//            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(0.5)
        }
//        contentTextField.snp.makeConstraints {
//            $0.top.equalTo(lineView2.snp.bottom)
//            $0.trailing.leading.equalToSuperview()
//            $0.height.equalTo(420)
//        }
        warnView.snp.makeConstraints {
            $0.height.equalTo(50)
        }
        warnView.addSubviews(remainCountLabel, warnLabel)
        remainCountLabel.snp.makeConstraints {
            $0.top.equalTo(contentTextField.snp.bottom).offset(16)
            $0.trailing.equalToSuperview()
        }
        warnLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        attachButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(25)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            $0.width.height.equalTo(45)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTextView(_:)))
                view.addGestureRecognizer(tapGesture)
    }
    
    private func setNavigate() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeButtonTapped))
        let button = UIButton(type: .system)
        button.setTitle("등록", for: .normal)
        button.backgroundColor = UIColor.P2()
        button.layer.cornerRadius = 18
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 33) // 버튼 크기 설정
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButtonItem
        }
    @objc func sortButtonPressed() {
        let bottomSheetVC = SelectBoardBottomSheetViewController()
        bottomSheetVC.delegate = self
        bottomSheetVC.tmp = sortLabel.text ?? "게시판 선택"
            present(bottomSheetVC, animated: true, completion: nil)
    }
    @objc private func closeButtonTapped() {
            dismiss(animated: true, completion: nil)
        }
    @objc private func attachButtonTapped() {
        authService.requestAuthorization { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                let vc = PhotoViewController().then {
                    $0.modalPresentationStyle = .fullScreen
                }
                vc.delegate = self
                present(vc, animated: true)
            case .failure:
                return
            }
        }
    }
    @objc private func addButtonTapped() {
        addPost(title: titleTextField.text ?? "", category: sortLabel.text!, content: contentTextField.text, image: imageUrls)
    }

    @objc func receiveImages(_ notification: Notification) {
        print("receiveImagebuttontapped")
        
        // userInfo에서 PHAsset 배열을 가져옴
        if let assets = notification.userInfo?["images"] as? [PHAsset] {
            // 기존의 모든 이미지 뷰 제거
            imageViews.forEach { $0.removeFromSuperview() }
            imageViews.removeAll()
            
            // 받은 모든 PHAsset을 UIImageView로 생성하여 UIScrollView에 추가
            var xOffset: CGFloat = 0
            for asset in assets {
                // 비동기적으로 이미지 로드
                photoService.fetchImage(
                    phAsset: asset,
                    size: CGSize(width: 144 * Const.scale, height: 144 * Const.scale),
                    contentMode: .aspectFit,
                    completion: { [weak self] image in
                        DispatchQueue.main.async {
                            // 이미지 뷰 생성 및 추가
                            let imageView = UIImageView(image: image)
                            imageView.frame = CGRect(x: xOffset, y: 0, width: 144, height: 144)
                            self?.imageScrollView.addSubview(imageView)
                            self?.imageViews.append(imageView)
                            imageView.do {
                                $0.layer.cornerRadius = 10
                                $0.clipsToBounds = true
                            }
                            
                            xOffset += 156 // 다음 이미지 뷰의 x 좌표 오프셋
                            
                            // 스크롤 뷰의 contentSize를 설정하여 모든 이미지 뷰가 보이도록 함
                            self?.imageScrollView.contentSize = CGSize(width: xOffset, height: 144)
                        }
                    }
                )
            }
        }
    }
}

extension AddPostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == textViewPlaceHolder {
            textView.text = nil
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = textViewPlaceHolder
            textView.textColor = .lightGray
            updateCountLabel(characterCount: 0)
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let inputString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldString = textView.text, let newRange = Range(range, in: oldString) else { return true }
        let newString = oldString.replacingCharacters(in: newRange, with: inputString).trimmingCharacters(in: .whitespacesAndNewlines)

        let characterCount = newString.count
        guard characterCount <= 500 else { return false }
        updateCountLabel(characterCount: characterCount)

        return true
    }
    
    @objc
        private func didTapTextView(_ sender: Any) {
            view.endEditing(true)
        }

        private func updateCountLabel(characterCount: Int) {
            remainCountLabel.text = "\(characterCount)/500"
//            remainCountLabel.asColor(targetString: "\(characterCount)", color: characterCount == 0 ? .lightGray : .blue)
        }
}

extension UILabel {
    func asColor(targetString: String, color: UIColor?) {
        let fullText = text ?? ""
        let range = (fullText as NSString).range(of: targetString)
        let attributedString = NSMutableAttributedString(string: fullText)
        attributedString.addAttribute(.foregroundColor, value: color as Any, range: range)
        attributedText = attributedString
    }
}

extension AddPostViewController {
    func addPost( title: String, category: String, content: String, image: [Int]) {
        if let token = self.keychain.get("accessToken") {
            print("\(token)")
            BoardAPI.shared.addPost(token: token, title: titleTextField.text ?? "", category: category, contents: contentTextField.text, imageId: imageUrls) { result in
                switch result {
                case .success:
                    print("success")
                    self.dismiss(animated: true, completion: nil)
                case .requestErr(let message):
                    LoginAPI.shared.refreshAccessToken { result in // 토큰 재발급 요청
                                            switch result {
                                            case .success(let loginDTO):
                                                print("토큰 재발급 성공: \(loginDTO)")
                                                self.keychain.set(loginDTO.data.accessToken, forKey: "accessToken") // 새로 발급받은 토큰 저장
                                                self.addPost(title: title, category: category, content: content, image: image) // addPost 함수 재호출
                                            case .failure(let error):
                                                print("토큰 재발급 실패: \(error)")
                                            }
                                        }
                case .pathErr:
                    print("Path error")
                    
                case .serverErr:
                    print("Server error")
                    
                case .networkFail:
                    print("Network failure")
                    
                default:
                    break
                }
            }
        }
    }
}

extension AddPostViewController: ImageUploaderDelegate {
    func didUploadImages(with urls: [Int]) {
        self.imageUrls = urls
    }
}
