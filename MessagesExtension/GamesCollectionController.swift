//
//  GamesCollectionController.swift
//  Chess
//
//  Created by Yun Teng on 8/6/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import Messages

class GamesCollectionController: UIViewController {
    static let storyboardIdentifier = "GamesCollectionController"
    @IBOutlet var backgroundView: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    var stickers: [MSSticker]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initFlowLayout()
    }
}

extension GamesCollectionController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sticker = stickers[indexPath.row]
        return dequeueStickerCell(for: sticker, indexPath)
    }
    
    private func dequeueStickerCell(for sticker: MSSticker, _ indexPath: IndexPath) -> StickerCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.reuseIdentifier, for: indexPath) as! StickerCell
        cell.stickerView.sticker = sticker
        cell.stickerLabel.text = sticker.localizedDescription
        return cell
    }
    
    private func initFlowLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        let screenWidth = UIScreen.main.bounds.size.width
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        self.collectionView.collectionViewLayout = layout
    }
}

