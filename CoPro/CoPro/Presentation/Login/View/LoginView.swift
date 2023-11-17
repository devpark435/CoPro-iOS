//
//  LoginView.swift
//  CoPro
//
//  Created by 박현렬 on 11/8/23.
//

import UIKit
import SnapKit
import Then
import GoogleSignIn
import AuthenticationServices

protocol LoginViewDelegate: AnyObject {
    func handleAppleIDRequest()
    func handleGitHubSignIn()
}

class LoginView: UIView {
    weak var delegate: LoginViewDelegate?
    //loginButton 선언
    let googleSignInButton = UIButton()
    let appleSignInButton = UIButton()
    let githubSignInButton = UIButton()
    let signOutButton = UIButton()
    let coproLogo = UIImageView(image : Image.coproLogo)
    let coproLogoLabel = UILabel()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //view에 button추가
        addSubview(coproLogo)
        addSubview(googleSignInButton)
        addSubview(appleSignInButton)
        addSubview(githubSignInButton)
        addSubview(signOutButton)
        
        addSubview(coproLogoLabel)
        let attributedString = NSMutableAttributedString(string: "협업할 개발자를 찾는다면?", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 25, weight: .bold)])
        attributedString.addAttribute(NSAttributedString.Key.kern, value: 1.37, range: NSRange(location: 0, length: attributedString.length))

        coproLogoLabel.attributedText = attributedString
        coproLogoLabel.textAlignment = .center
        coproLogoLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
            make.bottom.equalTo(coproLogo.snp.top).offset(-20)  // logo 위에 위치
            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(20)
            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-20)
        }
        //Logo Design
        coproLogo.snp.makeConstraints{(make) in
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
            make.centerY.equalTo(self.safeAreaLayoutGuide.snp.centerY).offset(-82)
            make.width.equalTo(192)
            make.height.equalTo(177)
        }
        
        //Button Design
        appleSignInButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
            make.top.equalTo(coproLogo.snp.bottom).offset(42)
            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(20)
            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.height.equalTo(48)
        }
        appleSignInButton.backgroundColor = UIColor.black
        appleSignInButton.layer.cornerRadius = 12
        appleSignInButton.setAttributedTitle(NSAttributedString(string: "Sign in with Apple", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.kern: 1.25]), for: .normal)

        googleSignInButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
            make.top.equalTo(appleSignInButton.snp.bottom).offset(20)
            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(20)
            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.height.equalTo(48)
        }
        googleSignInButton.backgroundColor = UIColor(red: 0.25, green: 0.52, blue: 0.95, alpha: 1.0)
        googleSignInButton.layer.cornerRadius = 12
        googleSignInButton.setAttributedTitle(NSAttributedString(string: "Sign in with Google", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.kern: 1.25]), for: .normal)

        
        
        
        githubSignInButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
            make.top.equalTo(googleSignInButton.snp.bottom).offset(20)
            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(20)
            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.height.equalTo(48)
        }
        githubSignInButton.backgroundColor = UIColor.black
        githubSignInButton.layer.cornerRadius = 12
        githubSignInButton.setAttributedTitle(NSAttributedString(string: "Sign in with GitHub", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.kern: 1.25]), for: .normal)

        
//        signOutButton.snp.makeConstraints { (make) in
//            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
//            make.top.equalTo(githubSignInButton.snp.bottom).offset(20)
//            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(20)
//            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-20)
//        }
//        signOutButton.backgroundColor = UIColor.black
//        signOutButton.layer.cornerRadius = 12
//        signOutButton.setAttributedTitle(NSAttributedString(string: "Sign out", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium),NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didTapAppleSignIn() {
        delegate?.handleAppleIDRequest()
    }
    
}
