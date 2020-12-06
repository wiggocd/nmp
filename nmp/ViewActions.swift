//
//  ViewActions.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AppKit

extension ViewController {
    @IBAction func openAction(_ sender: Any) {
        player.addMedia(urls: openMedia())
    }
    
    @IBAction func playlistAction(_ sender: Any) {
        if playlistScrollView.isHidden {
            playlistScrollView.isHidden = false
        } else {
            playlistScrollView.isHidden = true
        }
    }
    
    @IBAction func playPauseAction(_ sender: Any) {
        playpause()
    }
    
    @IBAction func nextTrackAction(_ sender: Any) {
        player.nextTrack()
    }
    
    @IBAction func previousTrackAction(_ sender: Any) {
        player.previousTrack()
    }
    
    @IBAction func timeSliderMoved(_ sender: Any) {
        player.setPosition(position: timeSlider.doubleValue)
        positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @IBAction func playlistOutlineViewDoubleAction(_ sender: Any) {
        if let sender = sender as? NSOutlineView {
            play(atIndex: sender.selectedRow)
        }
    }
}
