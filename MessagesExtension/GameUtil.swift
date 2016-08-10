import Foundation

let pieceToResourceMap: [String:String] = [
    "K": "king_white",
    "Q": "queen_white",
    "B": "bishop_white",
    "N": "knight_white",
    "R": "rook_white",
    "P": "pawn_white",
    "k": "king_black",
    "q": "queen_black",
    "b": "bishop_black",
    "n": "knight_black",
    "r": "rook_black",
    "p": "pawn_black"
]

let fileNotationMap: [Int:String] = [
    0: "a",
    1: "b",
    2: "c",
    3: "d",
    4: "e",
    5: "f",
    6: "g",
    7: "h"
]

let pieceNotationMap: [String: String] = [
    "king": "K",
    "queen": "Q",
    "bishop": "B",
    "knight": "N",
    "rook": "R",
    "pawn": ""
]

enum piece: String {
    case king = "king"
    case queen = "queen"
    case bishop = "bishop"
    case knight = "knight"
    case rook = "rook"
    case pawn = "pawn"
}

func initStandardBoard() -> [String] {
    var board = [String]()
    for row in 0..<8 {
        for col in 0..<8 {
            if row == 1 {
                board.append("p")
            } else if row == 6 {
                board.append("P")
            } else if row == 0 && col == 0 || row == 0 && col == 7 {
                board.append("r")
            } else if row == 0 && col == 1 || row == 0 && col == 6 {
                board.append("n")
            } else if row == 0 && col == 2 || row == 0 && col == 5 {
                board.append("b")
            } else if row == 0 && col == 3 {
                board.append("q")
            } else if row == 0 && col == 4 {
                board.append("k")
            } else if row == 7 && col == 4 {
                board.append("K")
            } else if row == 7 && col == 3 {
                board.append("Q")
            } else if row == 7 && col == 2 || row == 7 && col == 5 {
                board.append("B")
            } else if row == 7 && col == 1 || row == 7 && col == 6 {
                board.append("N")
            } else if row == 7 && col == 0 || row == 7 && col == 7 {
                board.append("R")
            } else {
                board.append(" ")
            }
        }
    }
    return board
}

func initBoardFromBits(WP: UInt64, WR: UInt64, WN: UInt64, WB: UInt64, WQ: UInt64, WK: UInt64, BP: UInt64, BR: UInt64, BN: UInt64, BB: UInt64, BQ: UInt64, BK: UInt64) -> [String] {
    var board = [String]()
    for i in 0..<64 {
        let s = UInt64(i)
        if BP & (1 << s) != 0 {
            board.append("p")
        } else if BR & (1 << s) != 0 {
            board.append("r")
        } else if BN & (1 << s) != 0 {
            board.append("n")
        } else if BB & (1 << s) != 0 {
            board.append("b")
        } else if BQ & (1 << s) != 0 {
            board.append("q")
        } else if BK & (1 << s) != 0 {
            board.append("k")
        } else if WP & (1 << s) != 0 {
            board.append("P")
        } else if WR & (1 << s) != 0 {
            board.append("R")
        } else if WN & (1 << s) != 0 {
            board.append("N")
        } else if WB & (1 << s) != 0 {
            board.append("B")
        } else if WQ & (1 << s) != 0 {
            board.append("Q")
        } else if WK & (1 << s) != 0 {
            board.append("K")
        } else {
            board.append(" ")
        }
    }
    return board
}

func initBitBoard(board: [String], WP:inout UInt64, WR:inout UInt64, WN:inout UInt64, WB:inout UInt64, WQ:inout UInt64, WK:inout UInt64, BP:inout UInt64, BR:inout UInt64, BN:inout UInt64, BB:inout UInt64, BQ:inout UInt64, BK:inout UInt64) {
    var s: UInt64 = 0
    for i in 0..<64 {
        s = 1 << UInt64(i)
        switch (board[i]) {
        case "P":
            WP |= s
            break
        case "R":
            WR |= s
            break
        case "N":
            WN |= s
            break
        case "B":
            WB |= s
            break
        case "Q":
            WQ |= s
            break
        case "K":
            WK |= s
            break
        case "p":
            BP |= s
            break
        case "r":
            BR |= s
            break
        case "n":
            BN |= s
            break
        case "b":
            BB |= s
            break
        case "q":
            BQ |= s
            break
        case "k":
            BK |= s
            break
        default:
            break
        }
    }
}
