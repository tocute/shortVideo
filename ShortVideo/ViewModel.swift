//
//  ViewModel.swift
//  ShortVideo
//
//  Created by Bill Chang on 2024/6/13.
//

import Foundation

struct VideoInfo {
    let url: URL?
    let title: String
    var isLiked: Bool
    var likeNumber: Int = 0
    let author: String
}

struct ViewModel {
    
    var videoInfos: [VideoInfo] = [
        VideoInfo(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"), title: "title 1", isLiked: false, likeNumber: 210, author: "Alex"),
        VideoInfo(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"), title: "title 2", isLiked: true, likeNumber: 452, author: "Bill"),
        VideoInfo(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"), title: "title 3", isLiked: false, likeNumber: 193, author: "Cindy")
    ]
    
    func videoInfoCount() -> Int {
        return videoInfos.count
    }
    
    func videoInfo(index: Int) -> VideoInfo? {
        guard videoInfos.indices.contains(index) else { return nil }
        return videoInfos[index]
    }
    
    mutating func updateVideoInfo(index: Int, info: VideoInfo) {
        guard videoInfos.indices.contains(index) else { return }
        videoInfos[index] = info
    }
}
