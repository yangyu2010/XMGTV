//
//  YYServer.swift
//  ClientServer
//
//  Created by Young on 2017/5/12.
//  Copyright © 2017年 YuYang. All rights reserved.
//

import UIKit

protocol YYServerDelegate: class {
    func server(_ server: YYServer, joinRoom user: User)
    func server(_ server: YYServer, leaveRoom user: User)
    func server(_ server: YYServer, textMessage : TextMessage)
    func server(_ server: YYServer, giftMessage : GiftMessage)
}


class YYServer {

    weak var delegate: YYServerDelegate?
    
    fileprivate var tcpClient: TCPClient
    
    init(address: String, port: Int) {
        tcpClient = TCPClient(addr: address, port: port)
    }
    
    fileprivate lazy var userInfo: User = {
        let user = User.Builder()
        user.name = "yangyu\(arc4random_uniform(10))"
        user.level = 20
        
        return try! user.build()
    }()
}

extension YYServer {
    func connectSercer() -> Bool {
        let temp = tcpClient.connect(timeout: 5)
        return temp.0
    }
    
   
    func startReadMessage() {
        DispatchQueue.global().async {
            while true {
                
                if let lengthMsg = self.tcpClient.read(kYYServerDataCountHeader) {
                    
                    // 1.读取长度的data
                    let lengthData = Data(bytes: lengthMsg, count: kYYServerDataCountHeader)
                    var length: Int = 0
                    (lengthData as NSData).getBytes(&length, length: kYYServerDataCountHeader)
                    //                print(length)
                    
                    // 2.读取消息的类型
                    guard let typeMessage = self.tcpClient.read(kYYServerDataCountType) else { return }
                    let typeData = Data(bytes: typeMessage, count: kYYServerDataCountType)
                    var type: Int = 0
                    (typeData as NSData).getBytes(&type, length: kYYServerDataCountType)
                    //print(type)
                    
                    // 3.根据长度读取真实消息
                    guard let message = self.tcpClient.read(length) else { return }
                    let messageData = Data(bytes: message, count: length)
                    
                    // 4.处理数据
                    DispatchQueue.main.async {
                        self.handleMessage(type: type, data: messageData)
                    }

                                    
                }else {
                    //isClientConnected = false
                    print("服务器挂了")
                }
                
            }
        }
    }
    
    private func handleMessage(type: Int, data: Data) {
        
        switch type {
        case kYYServerMessageJoinRoom:
            guard let user = try? User.parseFrom(data: data) else { break }
            delegate?.server(self, joinRoom: user)
        case kYYServerMessageLeaveRoom:
            guard let user = try? User.parseFrom(data: data) else { break }
            delegate?.server(self, leaveRoom: user)
        case kYYServerMessageSendText:
            guard let textMessage = try? TextMessage.parseFrom(data: data) else { break }
            delegate?.server(self, textMessage: textMessage)
        case kYYServerMessageSendGift:
            guard let giftMessage = try? GiftMessage.parseFrom(data: data) else { break }
            delegate?.server(self, giftMessage: giftMessage)
        default:
            print("未知类型")
        }
    }

}

/*
 进入房间 = 0
 离开房间 = 1
 文本 = 2
 礼物 = 3
 */
extension YYServer {
    // 发送消息
    private func sendMessage(data: Data, type: Int) {
        
        // 1.消息长度
        var length = data.count
        let headerData = Data(bytes: &length, count: kYYServerDataCountHeader)
        
        
        // 2.消息类型
        var tempType = type
        let typeData = Data(bytes: &tempType, count: kYYServerDataCountType)
        
        // 3.总共的消息
        let totalDta = headerData + typeData + data
        
        let result = tcpClient.send(data: totalDta)
        print(result.1)
    }
    
    // 进入房间
    func sendJoinRoom() {
        let msgData = userInfo.data()
        sendMessage(data: msgData, type: kYYServerMessageJoinRoom)
    }
    
    // 离开房间
    func sendLeaveRoom() {
        let msgData = userInfo.data()
        sendMessage(data: msgData, type: kYYServerMessageLeaveRoom)
    }
    
    // 发送文本
    func sendTextMessage(message: String) {
        let textMsg = TextMessage.Builder()
        textMsg.text = message
        textMsg.user = userInfo
        
        let data = try! textMsg.build()
        sendMessage(data: data.data(), type: kYYServerMessageSendText)
    }
    
    // 发送礼物
    func sendGiftMessage(_ giftName: String, _ giftURL: String, _ giftCount: Int) {
        let giftMessage = GiftMessage.Builder()
        giftMessage.user = userInfo
        giftMessage.giftName = giftName
        giftMessage.giftUrl = giftURL
        giftMessage.giftCount = String(giftCount)
        
        let gift = try! giftMessage.build()
        
        sendMessage(data: gift.data(), type: kYYServerMessageSendGift)
        
    }
}
