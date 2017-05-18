//
//  LiveViewController.swift
//  XMGTV
//
//  Created by apple on 16/11/9.
//  Copyright © 2016年 coderwhy. All rights reserved.
//

import UIKit

private let kChatToolsViewHeight : CGFloat = 44
private let kGiftlistViewHeight : CGFloat = 320
private let kChatContentViewHeight : CGFloat = 200

class RoomViewController: UIViewController, Emitterable {
    
    // MARK: 控件属性
    @IBOutlet weak var bgImageView: UIImageView!
    
    fileprivate lazy var chatToolsView : ChatToolsView = ChatToolsView.loadFromNib()
    fileprivate lazy var giftListView : GiftListView = GiftListView.loadFromNib()
    fileprivate lazy var chatContentView : ChatContentView = ChatContentView.loadFromNib()
    fileprivate lazy var socket : YYServer = YYServer(address: "192.168.1.110", port: 2123)
    
    // MARK: 系统回调函数
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        if socket.connectSercer() {
            print("连接服务器成功")
            socket.startReadMessage()
            socket.sendJoinRoom()
            socket.delegate = self
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    deinit {
        socket.sendLeaveRoom()
        
    }
}


// MARK:- 设置UI界面内容
extension RoomViewController {
    fileprivate func setupUI() {
        setupBlurView()
        setupBottomView()
    }
    
    fileprivate func setupBlurView() {
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        blurView.frame = bgImageView.bounds
        bgImageView.addSubview(blurView)
    }
    
    fileprivate func setupBottomView() {
        
        // 0.设置Chat内容的View
        chatContentView.frame = CGRect(x: 0, y: view.bounds.height - 44 - kChatContentViewHeight, width: view.bounds.width, height: kChatContentViewHeight)
        chatContentView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(chatContentView)
        
        // 1.设置chatToolsView
        chatToolsView.frame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: kChatToolsViewHeight)
        chatToolsView.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        chatToolsView.delegate = self
        view.addSubview(chatToolsView)
        
        // 2.设置giftListView
        giftListView.frame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: kGiftlistViewHeight)
        giftListView.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        view.addSubview(giftListView)
        giftListView.delegate = self
    }
}


// MARK:- 事件监听
extension RoomViewController {
    @IBAction func exitBtnClick() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatToolsView.inputTextField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.giftListView.frame.origin.y = kScreenH
        })
    }
    
    @IBAction func bottomMenuClick(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            chatToolsView.inputTextField.becomeFirstResponder()
        case 1:
            print("点击了分享")
        case 2:
            UIView.animate(withDuration: 0.25, animations: { 
                self.giftListView.frame.origin.y = kScreenH - kGiftlistViewHeight
                
            })
        case 3:
            print("点击了更多")
//        case 4:
//            sender.isSelected = !sender.isSelected
//            let point = CGPoint(x: sender.center.x, y: view.bounds.height - sender.bounds.height * 0.5)
            //sender.isSelected ? startEmittering(point) : stopEmittering()
        default:
            fatalError("未处理按钮")
        }
    }
}


// MARK:- 监听键盘的弹出
extension RoomViewController {
    @objc fileprivate func keyboardWillChangeFrame(_ note : Notification) {
        let duration = note.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        let endFrame = (note.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let inputViewY = endFrame.origin.y - kChatToolsViewHeight
        
        UIView.animate(withDuration: duration, animations: {
            UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: 7)!)
            let endY = inputViewY == (kScreenH - kChatToolsViewHeight) ? kScreenH : inputViewY
            self.chatToolsView.frame.origin.y = endY
            
            let contentEndY = inputViewY == (kScreenH - kChatToolsViewHeight) ? (kScreenH - kChatContentViewHeight - 44) : endY - kChatContentViewHeight
            self.chatContentView.frame.origin.y = contentEndY
        })
    }
}



// MARK:- 监听用户输入的内容
extension RoomViewController : ChatToolsViewDelegate, GiftListViewDelegate {
    func chatToolsView(toolView: ChatToolsView, message: String) {
        //print(message)
        socket.sendTextMessage(message: message)
    }
    
    func giftListView(giftView: GiftListView, giftModel: GiftModel) {
        //print(giftModel.subject)
        socket.sendGiftMessage(giftModel.subject, giftModel.img2, 1)
    }
}

// MARK:-socket代理
extension  RoomViewController: YYServerDelegate {

    func server(_ server: YYServer, joinRoom user: User) {
//        print(user.name + " 进入了房间")
        chatContentView.insertMsg(user.name + " 进入了房间")
    }
    
    func server(_ server: YYServer, leaveRoom user: User) {
//        print(user.name + " 离开了房间")
        chatContentView.insertMsg(user.name + " 离开了房间")
    }
    
    func server(_ server: YYServer, textMessage: TextMessage) {
//        print(textMessage.user.name + ":" + textMessage.text)
        chatContentView.insertMsg(textMessage.user.name + ":" + textMessage.text)
    }
    
    func server(_ server: YYServer, giftMessage: GiftMessage) {
//        print(giftMessage.user.name + "送了礼物" + giftMessage.giftName)
        chatContentView.insertMsg(giftMessage.user.name + "送了礼物" + giftMessage.giftName)
    }
}
