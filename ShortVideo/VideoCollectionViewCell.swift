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
    func didTapLikeButton(cell: VideoCollectionViewCell)
}

class VideoCollectionViewCell: UICollectionViewCell {
    static let ReuseIdentifier = "VideoCollectionViewCell"
    weak var delegate: VideoCollectionViewCellDelegate?
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
        
        isVideoPlaying = true
        player?.pause()
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
