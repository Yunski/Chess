//
//  GUI.swift
//  Chess
//
//  Created by Yun Teng on 8/5/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import Messages

class Game: NSObject {
    private let N: Int = 8
    var board: [String]!
    var color: Int
    var isResume: Bool
    var isComplete: Bool
    var history: [String]
    var caption: String?
    var result: String?
    
    public override init() {
        board = [String]()
        board = initStandardBoard()
        color = 1
        isResume = false
        isComplete = false
        history = [String]()
    }
    
    public init(_ board: [String], _ color: Int, _ isResume: Bool, _ isComplete: Bool, _ history: [String]) {
        self.board = board
        self.color = color
        self.isResume = isResume
        self.isComplete = isComplete
        self.history = history
    }
    
    public convenience init?(message: MSMessage?) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = NSURLComponents(url: messageURL, resolvingAgainstBaseURL: false), let queryItems = urlComponents.queryItems else { return nil }
        
        self.init(queryItems)
    }
    
    public convenience init?(_ queryItems: [URLQueryItem]) {
        var board = Array(repeatElement(" ", count: 64))
        var color: Int = 0
        var isComplete: Bool = false
        var history = [String]()
        for queryItem in queryItems {
            let name = queryItem.name
            guard let value = queryItem.value else { return nil }
            switch(name) {
            case "board":
                let layout = value
                var i = 0
                for c in layout.characters {
                    board[i] = String(c)
                    i += 1
                }
                break
            case "color":
                color = Int(value)!
                break
            case "complete":
                isComplete = Int(value) == 1 ? true : false
            case "history":
                history = value.components(separatedBy: "|")
            default:
                break
            }
        }
        self.init(board, color, true, isComplete, history)
    }
    
    private func coordToIndex(_ file: Int, _ rank: Int) -> Int {
        return (N-rank-1) * N + file
    }
    
    public func movePiece(_ prevFile: Int, _ prevRank: Int, _ newFile: Int, _ newRank: Int) {
        self[newFile, newRank] = self[prevFile, prevRank]
        self[prevFile, prevRank] = " "
    }
    
    public func printBoard(for color: Int) {
        for row in 0..<N {
            for col in 0..<N {
                if color == 1 {
                    print(board[row*N + col], terminator: "")
                } else {
                    let rotatedRow = N-row-1
                    let rotatedCol = N-col-1
                    print(board[rotatedRow*N + rotatedCol], terminator: "")
                }
            }
            print()
        }
    }
    
    public func rotateBoardForWhite() -> [String] {
        var rotatedBoard = Array(repeating: " ", count: 64)
        for row in 0..<N {
            for col in 0..<N {
                rotatedBoard[row*N + col] = self[col, N-row-1]
            }
        }
        return rotatedBoard
    }
    
    public func rotateBoardForBlack() -> [String] {
        var rotatedBoard = Array(repeating: " ", count: 64)
        for row in 0..<N {
            for col in 0..<N {
                rotatedBoard[row*N + col] = self[N-col-1, row]
            }
        }
        return rotatedBoard
    }
    
    public func renderImage() -> UIImage {
        let size = CGSize(width: 300.0, height: 300.0)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            var square = CGRect.zero
            let sideLength: CGFloat = 36
            square.size = CGSize(width: sideLength, height: sideLength)
            let offset: CGFloat = 10.0
            var rotatedBoard: [String]
            if color == 1 {
                rotatedBoard = self.rotateBoardForWhite()
            } else {
                rotatedBoard = self.rotateBoardForBlack()
            }
            for file in 0..<N {
                for rank in 0..<N {
                    square.origin.x = CGFloat(rank) * sideLength
                    square.origin.y = CGFloat(file) * sideLength + offset
                    var squareColor: UIColor
                    if (rank + file) % 2 == 0 {
                        squareColor = UIColor(red: 1.0, green: 206.0/255, blue: 158.0/255, alpha: 1.0)
                    } else {
                        squareColor = UIColor(red: 209.0/255, green: 139.0/255, blue: 71.0/255, alpha: 1.0)
                    }
                    squareColor.setFill()
                    context.fill(square)
                    if let imageName = pieceToResourceMap[rotatedBoard[file*N + rank]] {
                        let pieceImage = UIImage(named: imageName)!
                        pieceImage.draw(in: square)
                    }
                }
            }
        }
        return image
    }
    
    subscript(_ file: Int, _ rank: Int) -> String {
        get {
            let i = coordToIndex(file, rank)
            if i < 0 || i >= 64 {
                return " "
            }
            return board[coordToIndex(file, rank)]
        }
        set(newValue) {
            board[coordToIndex(file, rank)] = newValue
        }
    }
}
