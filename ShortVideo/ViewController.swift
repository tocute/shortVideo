//
//  ViewController.swift
//  ShortVideo
//
//  Created by Bill Chang on 2024/6/13.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    var viewModel = ViewModel()

    private var currentIndex: Int = 0
    private var oldIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.ReuseIdentifier)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo(at: currentIndex)
    }
    
    private func playVideo(at index: Int) {
        guard index < viewModel.getVideoInfoCount() else { return }
        
        if let cell = collectionView.cellForItem(at: IndexPath(item: Int(oldIndex), section: 0)) as? VideoCollectionViewCell {
            cell.player?.pause()
            cell.playerLayer?.removeFromSuperlayer()
            cell.playerLayer = nil
        }
            
        guard let url = viewModel.getVideoInfo(index: index)?.url,
              let cell = collectionView.cellForItem(at: IndexPath(item: Int(index), section: 0)) as? VideoCollectionViewCell else { return }
        
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        cell.player = player
        cell.playerLayer = playerLayer
        cell.playerLayer?.frame = cell.contentView.bounds
        cell.contentView.layer.insertSublayer(playerLayer, at: 0)
        
        cell.player?.play()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getVideoInfoCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.ReuseIdentifier, for: indexPath) as! VideoCollectionViewCell
        if let likeNumber = viewModel.getVideoInfo(index: indexPath.row)?.likeNumber {
            cell.updateLikeCount(likeNumber)
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visibleIndexPath = collectionView.indexPathsForVisibleItems.first else { return }
        if currentIndex != visibleIndexPath.item {
            oldIndex = currentIndex
            currentIndex = visibleIndexPath.item
            playVideo(at: currentIndex)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

extension ViewController: VideoCollectionViewCellDelegate {
    func didTapLikeButton(cell: VideoCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        if var info = viewModel.getVideoInfo(index: indexPath.row) {
            info.likeNumber += 1
            viewModel.updateVideoInfo(index: currentIndex, info: info)
            collectionView.reloadData()
        }
    }
}


