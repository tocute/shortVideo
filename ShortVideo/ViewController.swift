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
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.ReuseIdentifier)
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
        
        if let cell = collectionView.cellForItem(at: IndexPath(item: Int(oldIndex), section: 0)) as? VideoCell {
            cell.player?.pause()
            cell.playerLayer?.removeFromSuperlayer()
            cell.playerLayer = nil
        }
            
        guard let url = viewModel.getVideoInfo(index: index)?.url,
              let cell = collectionView.cellForItem(at: IndexPath(item: Int(index), section: 0)) as? VideoCell else { return }
        
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.ReuseIdentifier, for: indexPath) as! VideoCell
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

extension ViewController: VideoCellDelegate {
    func didTapLikeButton(cell: VideoCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        if var info = viewModel.getVideoInfo(index: indexPath.row) {
            info.likeNumber += 1
            viewModel.updateVideoInfo(index: currentIndex, info: info)
            collectionView.reloadData()
        }
    }
}

protocol VideoCellDelegate: AnyObject {
//    func didTapPlayButton(cell: VideoCell)
    func didTapLikeButton(cell: VideoCell)
}

class VideoCell: UICollectionViewCell {
    static let ReuseIdentifier = "VideoCell"
    weak var delegate: VideoCellDelegate?
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    var isVideoPlaying = true
    let playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        button.tintColor = .white
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let likeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        button.tintColor = .white
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let likeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0"
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 17.0)
        label.textAlignment = .left
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupViews()
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(playButton)
        contentView.addSubview(likeButton)
        contentView.addSubview(likeLabel)
        
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            likeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            likeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 20),
            likeButton.widthAnchor.constraint(equalToConstant: 50),
            likeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            likeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            likeLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: 10),
            likeLabel.widthAnchor.constraint(equalToConstant: 50),
            likeLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    func updateLikeCount(_ count: Int) {
        likeLabel.text = "\(count)"
    }
    
    @objc
    private func playButtonTapped() {
        if isVideoPlaying {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
        
        isVideoPlaying.toggle()
    }
    
    @objc
    private func likeButtonTapped() {
        delegate?.didTapLikeButton(cell: self)
    }
    
}
