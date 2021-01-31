//
//  Notifications.swift
//  nmp
//
//  Created by C. Wiggins on 21/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation

extension Notification.Name {
    static var preferencesChanged: Notification.Name {
        return .init("Application.preferencesChanged")
    }
    
    static var mediaChanged: Notification.Name {
        return .init("AudioPlayer.mediaChanged")
    }
    
    static var playlistChanged: Notification.Name {
        return .init("AudioPlayer.playlistChanged")
    }
    
    static var rateChanged: Notification.Name {
        return .init("AudioPlayer.rateChanged")
    }
    
    static var playbackStarted: Notification.Name {
        return .init("AudioPlayer.playbackStarted")
    }
    
    static var playbackPaused: Notification.Name {
        return .init("AudioPlayer.playbackPaused")
    }
    
    static var playbackStopped: Notification.Name {
        return .init("AudioPlayer.playbackStopped")
    }
    
    static var positionSet: Notification.Name {
        return .init("AudioPlayer.positionSet")
    }
    
    static var playPause: Notification.Name {
        return .init("ViewController.playPause")
    }
    
    static var nextTrack: Notification.Name {
        return .init("ViewController.nextTrack")
    }
    
    static var playlistIndexesRemoved: Notification.Name {
        return .init("ViewController.playlistIndexesRemoved")
    }
}

