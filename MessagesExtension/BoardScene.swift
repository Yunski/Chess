//
//  BoardScene.swift
//  Chess
//
//  Created by Yun Teng on 7/19/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import SpriteKit

class BoardScene: SKScene {
    let squareLength: CGFloat = 32
    let pieceLength: CGFloat = 32
    let gameLayer = SKNode()
    let boardLayer = SKNode()
    let pieceLayer = SKNode()
    var game: Game!
    var selectedPieceNode: SKNode?
    var prevLocation: CGPoint?
    var newLocation: CGPoint?
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    struct ChessAPI {
        private static let baseURLString = "http://localhost:8080/"
        private static let newGameURL = ChessAPI.baseURLString.appending("new")
        private static let moveURL = ChessAPI.baseURLString.appending("move")
        private static let statusURL = ChessAPI.baseURLString.appending("status")
    }
    
    struct Move {
        var isCastle: Bool
        var isEnPassant: Bool
        var prevSquare: String
        
        init(_ isCastle: Bool, _ isEnPassant: Bool, _ prevSquare: String) {
            self.isCastle = isCastle
            self.isEnPassant = isEnPassant
            self.prevSquare = prevSquare
        }
    }
    
    enum GameStatus {
        case check
        case checkmate
        case repetition
        case stalemate
        case normal
    }
    
    init(size: CGSize, with game: Game) {
        super.init(size: size)
        self.game = game
        if !game.isResume {
            requestNewGame()
        }
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let background = SKSpriteNode(imageNamed: "wood_background")
        background.size = size
        addChild(background)
        addChild(gameLayer)
        
        let layerPosition = CGPoint(
            x: -squareLength * CGFloat(8) / 2,
            y: -squareLength * CGFloat(8) / 2)
        
        boardLayer.position = layerPosition
        pieceLayer.position = layerPosition
        gameLayer.addChild(boardLayer)
        gameLayer.addChild(pieceLayer)
        initGUI(game.color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initGUI(_ color: Int) {
        for rank in 0..<8 {
            for file in 0..<8 {
                let squareNode = SKSpriteNode()
                squareNode.size = CGSize(width: squareLength, height: squareLength)
                
                if (rank + file) % 2 == 0 {
                    squareNode.color = UIColor(red: 209.0/255, green: 139.0/255, blue: 71.0/255, alpha: 1.0)
                } else {
                    squareNode.color = UIColor(red: 1.0, green: 206.0/255, blue: 158.0/255, alpha: 1.0)
                }
                squareNode.position = pointForCoord(file, rank)
                var rFile = file, rRank = rank
                if color == 0 {
                    (rFile, rRank) = blackCoord(file, rank)
                }
                if let imageName = pieceToResourceMap[game[rFile, rRank]] {
                    let pieceNode = SKSpriteNode(imageNamed: imageName)
                    pieceNode.size = CGSize(width: pieceLength, height: pieceLength)
                    pieceNode.name = imageName
                    pieceNode.position = pointForCoord(file, rank)
                    pieceNode.zPosition = 0
                    pieceLayer.addChild(pieceNode)
                }
                boardLayer.addChild(squareNode)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.selectedPieceNode = nil
        self.prevLocation = nil
        self.newLocation = nil
        
        let touch = touches.first
        let touchLocation = touch!.location(in: pieceLayer)

        selectedPieceNode = pieceLayer.atPoint(touchLocation)
        let (file, rank)  = squareAtPoint(selectedPieceNode!.position)
        var (rFile, rRank) = (file, rank)
        if game.color == 0 {
            (rFile, rRank) = blackCoord(file, rank)
        }
        if game[rFile, rRank] == " " {
            return
        }
        selectedPieceNode!.zPosition = 99
        let prevSquareNode = boardLayer.atPoint(touchLocation)
        prevLocation = prevSquareNode.position
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if prevLocation == nil {
            return
        }
        let touch = touches.first
        let touchLocation = touch!.location(in: pieceLayer)
        selectedPieceNode?.position.x = touchLocation.x
        selectedPieceNode?.position.y = touchLocation.y
        newLocation = boardLayer.atPoint(touchLocation).position
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if prevLocation == nil || newLocation == nil {
            return
        }
        let (prevFile, prevRank) = squareAtPoint(prevLocation!)
        let (newFile, newRank) = squareAtPoint(newLocation!)
        var rPrevFile = prevFile, rPrevRank = prevRank,
            rNewFile = newFile, rNewRank = newRank
        var rookNode: SKNode?
        var newRookPos: CGPoint?
        var oldRookFile: Int = 0, oldRookRank: Int = 0
        guard prevLocation != newLocation, squareIsValid(newFile, newRank),
            !game.isComplete else {
            selectedPieceNode!.position.x = prevLocation!.x
            selectedPieceNode!.position.y = prevLocation!.y
            newLocation = nil
            return
        }
        var selectedPieceNotation = pieceNotation(selectedPieceNode!)
        if game.color == 0 {
            (rPrevFile, rPrevRank) = blackCoord(prevFile, prevRank)
            (rNewFile, rNewRank) = blackCoord(newFile, newRank)
        }
        var moveNotation = "\(selectedPieceNotation)\(fileNotationMap[rNewFile]!)\(rNewRank+1)"
        
        let pieces = pieceLayer.nodes(at: newLocation!)
        var pieceToBeCaptured: SKNode?
        for piece in pieces {
            if piece != selectedPieceNode {
                pieceToBeCaptured = piece
            }
        }
        if pieceToBeCaptured != nil {
            if selectedPieceNotation == "" {
                selectedPieceNotation = fileNotationMap[rPrevFile]!
            }
            moveNotation = "\(selectedPieceNotation)x\(fileNotationMap[rNewFile]!)\(rNewRank+1)"
        }
        if selectedPieceNotation == "" {
            let enemyPawnRepresentation = game.color == 1 ? "p" : "P"
            if self.game[rPrevFile-1, rPrevRank] == enemyPawnRepresentation || self.game[rPrevFile+1, rPrevRank] == enemyPawnRepresentation {
                pieceToBeCaptured = SKNode()
            }
            if pieceToBeCaptured == nil && rNewFile != rPrevFile {
                print("illegal move")
                self.selectedPieceNode!.position.x = self.prevLocation!.x
                self.selectedPieceNode!.position.y = self.prevLocation!.y
                return
            } else if rNewRank == 7 || rNewRank == 0 {
                print("pawn promotion")
                moveNotation += "=Q"
            }
        }
        
        if moveNotation.contains("K") && !game.history.joined(separator: "").contains("K") {
            switch (moveNotation) {
            case "Kg1":
                rookNode = self.pieceLayer.atPoint(self.pointForCoord(7, 0))
                (oldRookFile, oldRookRank) = squareAtPoint(rookNode!.position)
                newRookPos = self.pointForCoord(5, 0)
                moveNotation = "O-O"
                break
            case "Kc1":
                rookNode = self.pieceLayer.atPoint(self.pointForCoord(0, 0))
                (oldRookFile, oldRookRank) = squareAtPoint(rookNode!.position)
                newRookPos = self.pointForCoord(3, 0)
                moveNotation = "O-O-O"
                break
            case "Kg8":
                rookNode = self.pieceLayer.atPoint(self.pointForCoord(0, 0))
                let oldRookSquare = squareAtPoint(rookNode!.position)
                (oldRookFile, oldRookRank) = blackCoord(oldRookSquare.0, oldRookSquare.1)
                newRookPos = self.pointForCoord(2, 0)
                moveNotation = "O-O"
                break
            case "Kc8":
                rookNode = self.pieceLayer.atPoint(self.pointForCoord(7, 0))
                let oldRookSquare = squareAtPoint(rookNode!.position)
                (oldRookFile, oldRookRank) = blackCoord(oldRookSquare.0, oldRookSquare.1)
                newRookPos = self.pointForCoord(4, 0)
                moveNotation = "O-O-O"
                break
            default:
                break
            }
            if let rook = rookNode, let rookPos = newRookPos {
                rook.zPosition = 99
                rook.position.x = rookPos.x
                rook.position.y = rookPos.y
                rook.zPosition = 0
            }
        }
        
        requestMove(to: moveNotation, completion: {
            (move) -> Void in
            if move == nil {
                print("Illegal move nil")
                self.selectedPieceNode!.position.x = self.prevLocation!.x
                self.selectedPieceNode!.position.y = self.prevLocation!.y
            } else {
                if move!.isEnPassant {
                    let prevPawnMove = self.game.history[self.game.history.count-1]
                    if prevPawnMove == "\(fileNotationMap[rPrevFile-1]!)\(rPrevRank+1)" {
                        print("left")
                        if self.game.color == 1 {
                            pieceToBeCaptured = self.pieceLayer.atPoint(self.pointForCoord(prevFile-1, prevRank))
                        } else {
                            pieceToBeCaptured = self.pieceLayer.atPoint(self.pointForCoord(prevFile+1, prevRank))
                        }
                        self.game[rPrevFile-1, rPrevRank] = " "
                    } else {
                        print("right")
                        if self.game.color == 1 {
                            pieceToBeCaptured = self.pieceLayer.atPoint(self.pointForCoord(prevFile+1, prevRank))
                        } else {
                            pieceToBeCaptured = self.pieceLayer.atPoint(self.pointForCoord(prevFile-1, prevRank))
                        }
                        self.game[rPrevFile+1, rPrevRank] = " "
                    }
                    moveNotation = "\(fileNotationMap[rPrevFile]!)x\(prevPawnMove)"
                }
                if pieceToBeCaptured != nil {
                    self.pieceLayer.removeChildren(in: [pieceToBeCaptured!])
                }
                self.selectedPieceNode!.position.x = self.newLocation!.x
                self.selectedPieceNode!.position.y = self.newLocation!.y
                self.selectedPieceNode!.zPosition = 0
                if moveNotation.contains("=") {
                    print("update sprite")
                    var pieceImageName: String
                    if self.game.color == 1 {
                        pieceImageName = "queen_white"
                    } else {
                        pieceImageName = "queen_black"
                    }
                    (self.selectedPieceNode as! SKSpriteNode).texture = SKTexture(imageNamed: pieceImageName)
                    self.game[rPrevFile, rPrevRank] = self.game.color == 1 ? "Q" : "q"
                }
                self.game.movePiece(rPrevFile, rPrevRank, rNewFile, rNewRank)
                if newRookPos != nil {
                    let newSquare = self.squareAtPoint(newRookPos!)
                    var newRookFile: Int, newRookRank: Int
                    if self.game.color == 0 {
                        (newRookFile, newRookRank) = self.blackCoord(newSquare.0, newSquare.1)
                    } else {
                        (newRookFile, newRookRank) = (newSquare.0, newSquare.1)
                    }
                    self.game.movePiece(oldRookFile, oldRookRank, newRookFile, newRookRank)
                }
                self.game.printBoard(for: self.game.color)
            }
            self.requestStatus(completion: {
                (status) -> Void in
                var statusString: String?
                if status == nil {
                    print("Error status is unavailable")
                } else {
                    switch status! {
                    case .check:
                        statusString = "+!"
                    case .checkmate:
                        if self.game.color == 0 {
                            self.game.result = "(0-1)"
                        } else {
                            self.game.result = "(1-0)"
                        }
                        statusString = "# - CheckMate! \(self.game.result!)"
                        self.game.isComplete = true
                    case .repetition:
                        self.game.result = "(1/2-1/2)"
                        statusString = " - 3-fold repetition \(self.game.result!)"
                        self.game.isComplete = true
                    case .stalemate:
                        self.game.result = "(1/2-1/2)"
                        statusString = " - Stalemate \(self.game.result!)"
                        self.game.isComplete = true
                    default:
                        break
                    }
                }
                if !self.game.isResume {
                    self.game.caption = "New Game Started! Move: " + moveNotation
                } else {
                    self.game.caption = "Move: " + moveNotation
                }
                if statusString != nil {
                    self.game.caption!.append(statusString!)
                }
            })
            print(moveNotation)
            self.game.history.append(moveNotation)
        })
        //board.printBoard()

        /*
        if let sideEffect = sideEffectMove {
            let oldRookPos = pointForCoord(sideEffect.0.0, sideEffect.0.1)
            let newRookPos = pointForCoord(sideEffect.1.0, sideEffect.1.1)
            let rookNode = pieceLayer.atPoint(oldRookPos)
            rookNode.zPosition = 99
            rookNode.position.x = newRookPos.x
            rookNode.position.y = newRookPos.y
            rookNode.zPosition = 0
        }*/
    }
    
    private func pointForCoord(_ column: Int, _ row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*squareLength + squareLength/2,
            y: CGFloat(row)*squareLength + squareLength/2)
    }
    
    private func squareAtPoint(_ p: CGPoint) -> (Int, Int) {
        let file = Int((p.x - squareLength/2) / squareLength)
        let rank = Int((p.y - squareLength/2) / squareLength)
        return (file, rank)
    }
    
    private func squareIsValid(_ file: Int, _ rank: Int) -> Bool {
        return file >= 0 && file < 64 && rank >= 0 && rank < 64
    }
    
    private func blackCoord(_ file: Int, _ rank: Int) -> (Int, Int) {
        return (8-file-1, 8-rank-1)
    }
    
    private func pieceNotation(_ pieceNode: SKNode) -> String {
        var notation = ""
        if pieceNode.name!.hasPrefix(piece.king.rawValue) {
            notation = pieceNotationMap[piece.king.rawValue]!
        } else if pieceNode.name!.hasPrefix(piece.queen.rawValue) {
            notation = pieceNotationMap[piece.queen.rawValue]!
        } else if pieceNode.name!.hasPrefix(piece.bishop.rawValue) {
            notation = pieceNotationMap[piece.bishop.rawValue]!
        } else if pieceNode.name!.hasPrefix(piece.knight.rawValue) {
            notation = pieceNotationMap[piece.knight.rawValue]!
        } else if pieceNode.name!.hasPrefix(piece.rook.rawValue) {
            notation = pieceNotationMap[piece.rook.rawValue]!
        } else {
            notation = pieceNotationMap[piece.pawn.rawValue]!
        }
        return notation
    }
    
    private func requestNewGame() {
        let url = newGameURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            if let json = data {
                if let jsonString = NSString(data: json, encoding: String.Encoding.utf8.rawValue) {
                    print(jsonString)
                }
            } else if let requestError = error {
                print("Error sending move request: \(requestError)")
            } else {
                print("Error with request")
            }
        }
        task.resume()
    }
    
    private func requestMove(to square: String, completion: (Move?) -> Void) {
        let url = moveURL(with: square)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "move=\(square)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        var move: Move?
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            if let jsonData = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
                    var isCastle, isEnPassant: Bool?
                    var prevSquareNotation: String?
                    if let moveObject = jsonObject?["move"] as? [String:AnyObject] {
                        if let castle = moveObject["castle"] {
                            isCastle = castle as? Bool
                        }
                        if let enPassant = moveObject["enPassant"] {
                            isEnPassant = enPassant as? Bool
                        }
                        if let prevSquare = moveObject["prevSquare"] as? [String:AnyObject] {
                            prevSquareNotation = "\(prevSquare["file"]!)\(prevSquare["rank"]!)"
                        }
                    }
                    if isCastle != nil && isEnPassant != nil && prevSquareNotation != nil {
                        move = Move(isCastle!, isEnPassant!, prevSquareNotation!)
                    }
                } catch { print("Error creating object from json") }
            } else if let requestError = error {
                print("Error sending move request: \(requestError)")
            } else {
                print("Error with request")
            }
            completion(move)
        }
        task.resume()
    }
    
    private func requestStatus(completion: (GameStatus?) -> Void) {
        let url = statusURL()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            var status: GameStatus?
            if let jsonData = data {
                do {
                    let statusObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
                    var isCheck, isCheckmate, isRepetition, isStalemate: Bool?
                    if let check = statusObject?["isCheck"] {
                        isCheck = check as? Bool
                    }
                    if let checkmate = statusObject?["isCheckmate"] {
                        isCheckmate = checkmate as? Bool
                    }
                    if let repetition = statusObject?["isRepetition"] {
                        isRepetition = repetition as? Bool
                    }
                    if let stalemate = statusObject?["isStalemate"] {
                        isStalemate = stalemate as? Bool
                    }
                    if isCheck == true {
                        status = GameStatus.check
                    } else if isCheckmate == true {
                        status = GameStatus.checkmate
                    } else if isRepetition == true {
                        status = GameStatus.repetition
                    } else if isStalemate == true {
                        status = GameStatus.stalemate
                    } else {
                        status = GameStatus.normal
                    }
                } catch { print("Error creating object from json") }
            } else if let requestError = error {
                print("Error sending move request: \(requestError)")
            } else {
                print("Error with request")
            }
            completion(status)
        }
        task.resume()
    }
    
    private func newGameURL() -> URL {
        return URL(string: ChessAPI.newGameURL)!
    }
    
    private func moveURL(with move: String) -> URL {
        let components = NSURLComponents(string: ChessAPI.moveURL)!
        var queryItems = [URLQueryItem]()
        let queryItem = URLQueryItem(name: "move", value: move)
        queryItems.append(queryItem)
        components.queryItems = queryItems
        return components.url!
    }
    
    private func statusURL() -> URL {
        return URL(string: ChessAPI.statusURL)!
    }
}
