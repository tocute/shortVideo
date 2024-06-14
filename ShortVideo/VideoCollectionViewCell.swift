//
//  VideoCollectionViewCell.swift
//  ShortVideo
//
//  Created by Bill Chang on 2024/6/13.
//

import Foundation
import AVKit

protocol VideoCollectionViewCellDelegate: AnyObject {
//    func didTapPlayButton(cell: VideoCollectionViewCell)
    func didTapLikeButton(cell: VideoCollectionViewCell, videoInfo: VideoInfo)
}

class VideoCollectionViewCell: UICollectionViewCell {
    static let ReuseIdentifier = "VideoCollectionViewCell"
    weak var delegate: VideoCollectionViewCellDelegate?
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    var isVideoPlaying = true
    var videoInfo = VideoInfo(url: nil, title: "", isLiked: false, likeNumber: 0, author: "")
    
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
        label.textColor = .white
        label.font = .systemFont(ofSize: 17.0)
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

        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    func updateVideoInfo(_ info: VideoInfo) {
        videoInfo = info

        if let url = info.url {
            player = AVPlayer(url: url)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.likeLabel.text = "\(info.likeNumber)"
            isVideoPlaying = true
            self.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            if self.videoInfo.isLiked {
                let imageIcon = UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
                self.likeButton.setImage(imageIcon, for: .normal)
            } else {
                self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            }
        }
    }
    
    func playVideo() {
        isVideoPlaying = true
        player?.play()
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
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
        videoInfo.isLiked.toggle()
        if videoInfo.isLiked {
            videoInfo.likeNumber += 1
            let imageIcon = UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
            likeButton.setImage(imageIcon, for: .normal)
        } else {
            videoInfo.likeNumber -= 1
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        }
        likeLabel.text = "\(videoInfo.likeNumber)"
        delegate?.didTapLikeButton(cell: self,videoInfo: videoInfo)
    }
}
