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
        self.player.addMedia(urls: openMedia(), updateIndexIfNew: true, shouldPlay: false)
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
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.application!.animationDuration
                if let window = self.view.window, let previousHeight = previousWindowHeightWithPlaylist {
                    for constraint in windowWithPlaylistConstraints {
                        constraint.isActive = true
                    }
                    
                    let lastFrame = window.frame
                    let displayRect = NSRect(x: lastFrame.minX, y: lastFrame.minY, width: lastFrame.width, height: previousHeight)
                    
                    window.animator().setFrame(displayRect, display: true)
                }
            })
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.application!.animationDuration // 0.4
                self.playlistBox.animator().alphaValue = 0
            }) {
                self.playlistBox.isHidden = true
                self.application?.userDefaults.set(true, forKey: "PlaylistHidden")
            }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.application!.animationDuration
                if let window = self.view.window {
                    for constraint in windowWithPlaylistConstraints {
                        constraint.isActive = false
                    }
                    
                    let lastFrame = window.frame
                    let displayRect = NSRect(x: lastFrame.minX, y: lastFrame.minY, width: lastFrame.width, height: lastFrame.height - self.playlistBox.frame.height)
                    self.previousWindowHeightWithPlaylist = lastFrame.height;
                    
                    window.animator().setFrame(displayRect, display: true)
                }
            })
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
        let event = self.application?.currentEvent
        if let event = event, event.type != NSEvent.EventType.leftMouseUp {
            if let sender = sender as? NSSlider {
                self.player.position = sender.doubleValue
                self.positionLabel.stringValue = to_hhmmss(seconds: self.player.position)
            }
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
