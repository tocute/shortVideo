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
    var players = [AVPlayer]()
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
        
        setupPlayers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo(at: currentIndex)
    }
    
    private func setupPlayers() {
        players = viewModel.videoInfos.map { AVPlayer(url: $0.url!) }
        for player in players {
            player.currentItem?.preferredForwardBufferDuration = 5 // Buffer ahead duration
        }
    }
    
    private func playVideo(at index: Int) {
        guard index >= 0, index < viewModel.videoInfoCount() else { return }
        
        let prePlayer = players[oldIndex]
        prePlayer.pause()
            
        guard let cell = collectionView.cellForItem(at: IndexPath(item: Int(index), section: 0)) as? VideoCollectionViewCell else { return }
        
        if cell.player == nil {
            cell.player = players[index]
        }
        let playerLayer = AVPlayerLayer(player: cell.player)
        cell.playerLayer = playerLayer
        cell.playerLayer?.frame = cell.contentView.bounds
        cell.contentView.layer.insertSublayer(playerLayer, at: 0)
        
        cell.playVideo()
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.videoInfoCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.ReuseIdentifier, for: indexPath) as! VideoCollectionViewCell
        if let info = viewModel.videoInfo(index: indexPath.row) {
            cell.updateVideoInfo(info)
        }
        cell.delegate = self
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visibleIndexPath = collectionView.indexPathsForVisibleItems.first else { return }

        if currentIndex != visibleIndexPath.item {
            oldIndex = currentIndex
            currentIndex = visibleIndexPath.item
            
            playVideo(at: currentIndex)
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

extension ViewController: VideoCollectionViewCellDelegate {
    func didTapLikeButton(cell: VideoCollectionViewCell, videoInfo: VideoInfo) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        viewModel.updateVideoInfo(index: indexPath.row, info: videoInfo)
    }
}
