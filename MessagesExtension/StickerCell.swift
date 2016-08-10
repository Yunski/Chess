//
//  StickerCell.swift
//  Chess
//
//  Created by Yun Teng on 8/7/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import Messages

class StickerCell: UICollectionViewCell {
    static let reuseIdentifier = "StickerCell"
    @IBOutlet var stickerView: MSStickerView!
    @IBOutlet var stickerLabel: UILabel!
}
