//
//  ViewActions.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension PlayerViewController {
    @IBAction func clearPlaylist(_ sender: Any) {
        self.player.clear()
        self.setUIDefaults()
    }
    
    @IBAction func openAction(_ sender: Any) {
        self.player.addMedia(urls: openMedia(), updateIndexIfNew: true, shouldPlay: true)
    }
    
    @IBAction func playlistAction(_ sender: Any) {
        if self.playlistBox.isHidden {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.application!.animationDuration // 0.4
                
                self.playlistBox.alphaValue = 0
                self.playlistBox.isHidden = false
                self.playlistBox.animator().alphaValue = 1
                
                self.application?.userDefaults.set(false, forKey: "PlaylistHidden")
            })
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.application!.animationDuration // 0.4
                self.playlistBox.animator().alphaValue = 0
            }) {
                self.playlistBox.isHidden = true
                self.application?.userDefaults.set(true, forKey: "PlaylistHidden")
            }
        }
    }
    
    @IBAction func playPauseAction(_ sender: Any) {
        self.playPause()
    }
    
    @IBAction func nextTrackAction(_ sender: Any) {
        self.nextTrack()
    }
    
    @IBAction func rewindAction(_ sender: Any) {
        self.rewind()
    }
    
    @IBAction func timeSliderMoved(_ sender: Any) {
        if let sender = sender as? NSSlider {
            self.player.setPosition(position: sender.doubleValue)
            self.positionLabel.stringValue = to_hhmmss(seconds: self.player.position)
        }
    }
    
    @IBAction func volumeSliderMoved(_ sender: Any) {
        if let sender = sender as? NSSlider {
            self.player.volume = sender.floatValue
            self.application?.userDefaults.set(sender.floatValue, forKey: "Volume")
        }
    }
    
    @IBAction func playlistOutlineViewDoubleAction(_ sender: Any) {
        if let sender = sender as? NSOutlineView {
            self.play(atIndex: sender.selectedRow)
        }
    }
}
