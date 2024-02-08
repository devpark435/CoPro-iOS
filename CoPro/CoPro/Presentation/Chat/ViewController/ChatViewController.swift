//
//  ChatViewController.swift
//  CoPro
//
//  Created by 박신영 on 12/27/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Photos
import FirebaseFirestore
import FirebaseAuth
import SnapKit

class ChatVC: MessagesViewController {
    
    let customAvatarView = CustomAvatarView()
    
    lazy var cameraBarButtonItem: InputBarButtonItem = {
        let button = InputBarButtonItem(type: .system)
        button.tintColor = .primary
        button.image = UIImage(systemName: "camera")
        button.addTarget(self, action: #selector(didTapCameraButton), for: .touchUpInside)
        return button
    }()
    
    private let user: User
    let chatFirestoreStream = ChatFirestoreStream()
    let channel: Channel
    var messages = [Message]()
    private var isSendingPhoto = false {
      didSet {
        messageInputBar.leftStackViewItems.forEach { item in
          guard let item = item as? InputBarButtonItem else {
            return
          }
          item.isEnabled = !self.isSendingPhoto
        }
      }
    }
    
    init(user: User, channel: Channel) {
        self.user = user
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
        
        title = channel.name
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        chatFirestoreStream.removeListener()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmDelegates()
        configure()
        setupMessageInputBar()
        removeOutgoingMessageAvatars()
        addCameraBarButtonToMessageInputBar()
        listenToMessages()
    }

    private func confirmDelegates() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
    }
    
    //채팅창 상단 이름
    private func configure() {
        title = nil

        let titleLabel = UILabel()
        titleLabel.text = channel.name
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "mobile"
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleView = UIView()
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(0)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(0)
        }

        navigationItem.titleView = titleView
    }

    
    private func setupMessageInputBar() {
        messageInputBar.inputTextView.tintColor = .primary
        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        messageInputBar.inputTextView.placeholder = "Aa"
    }
    
    private func removeOutgoingMessageAvatars() {
        guard let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else { return }
        layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.setMessageOutgoingAvatarSize(.zero)
        let outgoingLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }
    
    private func addCameraBarButtonToMessageInputBar() {
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([cameraBarButtonItem], forStack: .left, animated: false)
    }
    
    private func insertNewMessage(_ message: Message) {
        messages.append(message)
        messages.sort()
        
        messagesCollectionView.reloadData()
    }
    
    private func listenToMessages() {
        guard let id = channel.id else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        chatFirestoreStream.subscribe(id: id) { [weak self] result in
            switch result {
            case .success(let messages):
                self?.loadImageAndUpdateCells(messages)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func loadImageAndUpdateCells(_ messages: [Message]) {
        messages.forEach { message in
            var message = message
            if let url = message.downloadURL {
                FirebaseStorageManager.downloadImage(url: url) { [weak self] image in
                    guard let image = image else { return }
                    message.image = image
                    self?.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }
        }
    }
    
    @objc private func didTapCameraButton() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        present(picker, animated: true)
    }
}

extension ChatVC: MessagesDataSource {
    
    var currentSender: MessageKit.SenderType {
        return Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
    }
    
    func cellForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        _ = messages[indexPath.section]
        
        return messagesCollectionView.dequeueReusableCell(MessageContentCell.self, for: indexPath)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    private func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        return messagesCollectionView.dequeueReusableCell(MessageContentCell.self, for: indexPath)
    }
}

extension ChatVC: MessagesLayoutDelegate {
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let isCurrentSender = isFromCurrentSender(message: message)
            
        // 내가 보낸 메세지 일 떄
        if isCurrentSender {
            return .custom { view in
                let maskLayer = CAShapeLayer()

                // UIBezierPath를 사용하여 모서리에 반경을 적용
                let path = UIBezierPath(roundedRect: view.bounds,
                                        byRoundingCorners: [.topLeft, .bottomLeft, .bottomRight],
                                        cornerRadii: CGSize(width: 10, height: 10))
                
                // 우측 상단 모서리에 2의 반경 적용
                path.append(UIBezierPath(roundedRect: CGRect(x: view.bounds.width - 2, y: 0, width: 2, height: 2),
                                         byRoundingCorners: .topRight,
                                         cornerRadii: CGSize(width: 2, height: 2)))

                maskLayer.path = path.cgPath
                view.layer.mask = maskLayer

                // 그림자 설정
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOffset = CGSize(width: 0, height: 1)
                view.layer.shadowRadius = 1
                view.layer.shadowOpacity = 0.1
            }
        }
        
        // 상대가 보낸 메세지 일 떄
        else {
            return .custom { view in
                // 상대 보낸 메시지의 스타일
                let maskLayer = CAShapeLayer()

                // UIBezierPath를 사용하여 모서리에 반경을 적용
                let path = UIBezierPath(roundedRect: view.bounds,
                                        byRoundingCorners: [.topRight, .bottomLeft, .bottomRight],
                                        cornerRadii: CGSize(width: 10, height: 10))
                
                // 우측 상단 모서리에 2의 반경 적용
                path.append(UIBezierPath(roundedRect: CGRect(x: view.bounds.width - 2, y: 0, width: 2, height: 2),
                                         byRoundingCorners: .topLeft,
                                         cornerRadii: CGSize(width: 2, height: 2)))

                maskLayer.path = path.cgPath
                view.layer.mask = maskLayer

                // 그림자 설정
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOffset = CGSize(width: 0, height: 1)
                view.layer.shadowRadius = 1
                view.layer.shadowOpacity = 0.1
            }
        }
    }
    
    // 아래 여백
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    // 말풍선 위 이름 나오는 곳의 height
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if isLastMessageInTimeGroup(at: indexPath) {
            return 20
        }else {
            return 0 // 같은 시간대의 메시지는 0을 리턴
        }
    }
    
    func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0))
        }
    }
}

// 상대방이 보낸 메시지, 내가 보낸 메시지를 구분하여 색상과 모양 지정
extension ChatVC: MessagesDisplayDelegate {
    
    func isFirstMessageInTimeGroup(at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else {
            // 현재 섹션이 첫 번째 섹션인 경우 항상 true 반환
            return true
        }
        
        let currentMessage = messages[indexPath.section]
        let previousMessage = messages[indexPath.section - 1]
        
        // 현재 메시지의 sentDate와 이전 메시지의 sentDate 비교하여 같은 시간대인지 확인
        let calendar = Calendar.current
        let isSameTimeGroup = calendar.isDate(currentMessage.sentDate, equalTo: previousMessage.sentDate, toGranularity: .minute)
        
        // 이전 메시지와 다른 시간대이면 true 반환 (시간대의 첫 번째 메시지)
        return !isSameTimeGroup
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.frame.origin.y = 0 // 아바타뷰를 메시지 맨 위에 배치
        
        let isFirstMessageInGroup = isFirstMessageInTimeGroup(at: indexPath)
        if isFirstMessageInGroup {
            avatarView.isHidden = false
        } else {
            avatarView.isHidden = true
        }
    }
    
    // 말풍선의 배경 색상
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessageBackground
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .black : .white
    }
    
    func isLastMessageInTimeGroup(at indexPath: IndexPath) -> Bool {
        guard indexPath.section < messages.count - 1 else {
            return true
        }
        
        let currentMessage = messages[indexPath.section]
        let nextMessage = messages[indexPath.section + 1]
        
        return !Calendar.current.isDate(currentMessage.sentDate, equalTo: nextMessage.sentDate, toGranularity: .minute)
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let isLastMessageInGroup = isLastMessageInTimeGroup(at: indexPath)
        
        if isLastMessageInGroup {
            let sentDate = message.sentDate
            let dateString = dateFormatter.string(from: sentDate)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.gray
            ]
            
            return NSAttributedString(string: dateString, attributes: attributes)
        } else {
            return nil
        }
    }

    
    
    func messageContainerSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return MessageSizeCalculator().messageContainerSize(for: message, at: indexPath)
    }
}

extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(user: user, content: text)
        
        chatFirestoreStream.save(message) { [weak self] error in
            if let error = error {
                print(error)
                return
            }
            self?.messagesCollectionView.scrollToLastItem()
        }
        inputBar.inputTextView.text.removeAll()
    }
}

extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let asset = info[.phAsset] as? PHAsset {
            let imageSize = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(for: asset,
                                                     targetSize: imageSize,
                                                     contentMode: .aspectFit,
                                                     options: nil) { image, _ in
                guard let image = image else { return }
                self.sendPhoto(image)
            }
        } else if let image = info[.originalImage] as? UIImage {
            sendPhoto(image)
        }
    }
    
    private func sendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        FirebaseStorageManager.uploadImage(image: image, channel: channel) { [weak self] url in
            self?.isSendingPhoto = false
            guard let user = self?.user, let url = url else { return }
            
            var message = Message(user: user, image: image)
            message.downloadURL = url
            self?.chatFirestoreStream.save(message)
            self?.messagesCollectionView.scrollToLastItem()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
