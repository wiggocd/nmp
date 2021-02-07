//
//  ViewController.swift
//  nmp
//
//  Created by C. Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa
import MediaPlayer

class PlayerViewController: NSViewController, NSOutlineViewDelegate {
    let notificationCenter = NotificationCenter.default
    let application = Application.shared as? Application
    let player = AudioPlayer()
    let coverImageMinimumSize = NSSize(width: 640, height: 640)
    let coverImageCornerRadius: CGFloat = 10
    let backgroundDarknessAlpha: CGFloat = 0.55
    let darkAppearance = NSAppearance(named: .darkAqua)
    let mediaHotKeyModifiers: NSEvent.ModifierFlags = [.command]
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let defaultCoverImage = NSImage(named: "AppIcon")
    
    var positionTimer = Timer()
    var playlistItems: [PlaylistItem] = []
    var lastSelectedPlaylistItem = 0
    var playlistItemClickTimer = Timer()
    var draggedNodes: [AnyObject]!
    var backgroundImageView: NSImageView!
    var defaultTitleColor: NSColor!
    var defaultDetailsColor: NSColor!
    var defaultTimeColor: NSColor!
    var defaultTransparentBoxColor: NSColor!
    var buttons: [NSButton] = []
    var boxes: [NSBox] = []
    var sliders: [NSSlider] = []
    var newPlaybackPositionTime: TimeInterval! = nil
    var lastURL: URL?
    
    @IBOutlet var titleTextView: NSTextView!
    @IBOutlet var detailsTextView: NSTextView!
    @IBOutlet weak var coverImageBox: NSBox!
    @IBOutlet weak var coverImageView: NSImageView!
    
    @IBOutlet weak var controlBox: NSBox!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var rewindButton: NSButton!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    @IBOutlet weak var playlistButton: NSButton!
    
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var positionLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    
    @IBOutlet weak var playlistBox: NSBox!
    @IBOutlet weak var playlistScrollView: NSScrollView!
    @IBOutlet weak var playlistOutlineView: PlaylistOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        
        self.getDefaultColors()
        self.createObjectGroups()
        self.setUIDefaults()
        
        self.addObservers()
        self.initialiseDragAndDrop()
        
        self.addLocalMonitorsForEvents()
        
        self.updatePlaylist()
        self.initialiseMediaSession()
    
        self.setVolumeFromDefaults()
        self.setPlaylistHiddenFromDefaults()
        self.initialiseDragAndDrop()
    }
    
    override func viewWillAppear() {
        self.updateMedia()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    deinit {
        self.killPlayer()
        self.killNowPlaying()
        self.killTimers()
        
        self.removeObservers()
        self.removeMediaListeners()
    }
    
    func getDefaultColors() {
        self.defaultTitleColor = self.titleTextView.textColor
        self.defaultDetailsColor = self.detailsTextView.textColor
        self.defaultTimeColor = self.positionLabel.textColor
        self.defaultTransparentBoxColor = self.controlBox.fillColor
    }
    
    func createObjectGroups() {
        self.boxes = [
            self.controlBox,
            self.playlistBox
        ]
        
        self.buttons = [
            self.openButton,
            self.rewindButton,
            self.playPauseButton,
            self.nextTrackButton,
            self.playlistButton
        ]
        
        self.sliders = [
            self.timeSlider,
            self.volumeSlider
        ]
    }
    
    func setUIDefaults() {
        self.titleTextView.string = "Not Playing"
        self.detailsTextView.string = "No Media"
        self.positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        self.durationLabel.stringValue = to_hhmmss(seconds: 0.0)
        self.timeSlider.minValue = 0
        self.timeSlider.maxValue = 0
        self.timeSlider.doubleValue = 0.0
        self.playlistOutlineView.delegate = self
        self.playlistOutlineView.dataSource = self
        
        self.playlistOutlineView.indentationPerLevel = 0
        self.playlistOutlineView.roundCorners(withRadius: self.application!.UICornerRadius)
        self.playlistScrollView.roundCorners(withRadius: self.application!.UICornerRadius)
        
        self.resetCoverImage()
        self.resetBackgroundViewAndAppearance()
    }
    
    func setDefaultAppearances() {
        self.titleTextView.textColor = self.defaultTitleColor
        self.detailsTextView.textColor = self.defaultDetailsColor
        self.positionLabel.textColor = self.defaultTimeColor
        self.durationLabel.textColor = self.defaultTimeColor
        
        self.controlBox.appearance = NSApp.appearance
        self.playlistBox.appearance = NSApp.appearance
        
        self.playlistOutlineView.appearance = NSApp.appearance
        self.playlistOutlineView.backgroundColor = .controlBackgroundColor
        
        for box in self.boxes {
            box.isTransparent = true
        }
        
        for button in self.buttons {
            button.appearance = NSApp.appearance
        }
        
        self.view.window?.appearance = NSApp.appearance
    }
    
    func setAlternateAppearances() {
        self.titleTextView.textColor = .white
        self.detailsTextView.textColor = .lightGray
        self.positionLabel.textColor = .gray
        self.durationLabel.textColor = .gray
        
//        self.controlBox.appearance = self.darkAppearance
        self.playlistBox.appearance = self.darkAppearance
        
        self.playlistOutlineView.appearance = self.darkAppearance
        if let showTransparentAppearance = self.application?.userDefaults.bool(forKey: "ShowTransparentAppearance") {
            if showTransparentAppearance {
                self.controlBox.fillColor = self.defaultTransparentBoxColor
                self.playlistOutlineView.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0)
                self.controlBox.isTransparent = false
            } else {
                self.controlBox.fillColor = .controlBackgroundColor
                self.playlistOutlineView.backgroundColor = .controlBackgroundColor
            }
        } else {
            self.controlBox.fillColor = .controlBackgroundColor
            self.playlistOutlineView.backgroundColor = .controlBackgroundColor
        }
        
//        for button in self.buttons {
//            button.appearance = self.darkAppearance
//        }
        
        self.view.window?.appearance = self.darkAppearance
    }
    
    func addObservers() {
        self.notificationCenter.addObserver(self, selector: #selector(self.refresh), name: .preferencesChanged, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playlistChanged), name: .playlistChanged, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.mediaChanged), name: .mediaChanged, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.rateChanged), name: .rateChanged, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.positionSet), name: .positionSet, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playbackStarted), name: .playbackStarted, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playbackPaused), name: .playbackPaused, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playbackStopped), name: .playbackStopped, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playPauseAction), name: .playPause, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(self.playlistIndexesRemoved), name: .playlistIndexesRemoved, object: self.playlistOutlineView)
    }
    
    func removeObservers() {
        self.notificationCenter.removeObserver(self)
    }
    
    func removeMediaListeners() {
        self.remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        self.remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
        
        self.remoteCommandCenter.playCommand.isEnabled = false
        self.remoteCommandCenter.playCommand.removeTarget(self)
        
        self.remoteCommandCenter.pauseCommand.isEnabled = false
        self.remoteCommandCenter.pauseCommand.removeTarget(self)
        
        self.remoteCommandCenter.previousTrackCommand.isEnabled = false
        self.remoteCommandCenter.previousTrackCommand.removeTarget(self)
        
        self.remoteCommandCenter.nextTrackCommand.isEnabled = false
        self.remoteCommandCenter.nextTrackCommand.removeTarget(self)
        
        self.remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
        self.remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self)
        
        self.nowPlayingInfoCenter.nowPlayingInfo = [:]
    }
    
    func initialiseDragAndDrop() {
        self.playlistOutlineView.registerForDraggedTypes(playlistPasteboardTypes)
        self.playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
        self.playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
    }
    
    func initialiseMediaSession() {
        self.remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        self.remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(self.togglePlayPauseCommandAction))
        
        self.remoteCommandCenter.playCommand.isEnabled = true
        self.remoteCommandCenter.playCommand.addTarget(self, action: #selector(self.playCommandAction))
        
        self.remoteCommandCenter.pauseCommand.isEnabled = true
        self.remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(self.pauseCommandAction))
        
        self.remoteCommandCenter.previousTrackCommand.isEnabled = true
        self.remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(self.previousTrackCommandAction))
            
        self.remoteCommandCenter.nextTrackCommand.isEnabled = true
        self.remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(self.nextTrackCommandAction))
        
        self.remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        self.remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(self.changePlaybackPositionCommandAction))
        
        self.preparePlayback()
        self.nowPlayingInfoCenter.nowPlayingInfo = [:]
    }
    
    func addLocalMonitorsForEvents() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.alternateKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
    }
    
    func preparePlayback() {
        self.pause()
    }
    
    func setCoverImage(image: CGImage) {
        self.resetCoverImage()
        
        let scale = self.coverImageView.fittingSize.height / (CGFloat(image.height) / 1.5)
        let size = NSSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = self.application!.animationDuration
            self.coverImageView.image = NSImage(cgImage: image, size: size).roundCorners(withRadius: self.coverImageCornerRadius)
            self.setCoverImageShadow()
        }
    }
    
    func resetCoverImage() {
        self.coverImageView.image = self.defaultCoverImage
        self.setCoverImageShadow()
    }
    
    func setCoverImageShadow() {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(white: 0.2, alpha: 0.5)
        shadow.shadowBlurRadius = 10
        self.coverImageBox.shadow = shadow
    }
    
    func setBackgroundViewAndAppearance() {
        if self.application!.colorBg! {
            if let metadata = self.player.metadata,
                metadata.artwork != nil && self.coverImageView != nil {
                let artwork = metadata.artwork
                let blurredImage = CIImage(cgImage: artwork!).blurred(radius: 64)
                
                if blurredImage != nil {
                    let cropRect = CIVector(x: 125, y: 125, z: CGFloat(artwork!.width) / CGFloat(2), w: CGFloat(artwork!.height) / CGFloat(2))
                    let croppedImage = blurredImage?.cropped(toRect: cropRect)
                    
                    if croppedImage != nil {
                        let transformedImage = croppedImage?.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
                        
                        if transformedImage != nil {
                            let bgImage = transformedImage?.nsImage().darkened(byBlackAlpha: self.backgroundDarknessAlpha)
                            
                            view.layer?.contents = bgImage
                            setAlternateAppearances()
                            
                            return
                        }
                    }
                }
            }
        }
        
        self.resetBackgroundViewAndAppearance()
    }
    
    func resetBackgroundViewAndAppearance() {
        self.view.layer?.contents = nil
        self.setDefaultAppearances()
    }
    
    func play() {
        self.player.play()
        self.startPositionTimer()
        self.nowPlayingInfoCenter.playbackState = .playing
    }
    
    func play(atIndex index: Int) {
        self.player.playlistIndex = index
        self.player.play()
        self.startPositionTimer()
        self.nowPlayingInfoCenter.playbackState = .playing
    }
    
    func playAtSelectedRow() {
        self.play(atIndex: playlistOutlineView.selectedRow)
    }
    
    func pause() {
        self.player.pause()
        self.positionTimer.invalidate()
        self.nowPlayingInfoCenter.playbackState = .paused
    }
    
    func playPause() {
        if self.player.state == .playing {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func nextTrack() {
        self.player.nextTrack()
    }
    
    func rewind() {
//        if self.player.position > 1 {
//            self.player.position = 0
//        } else {
            self.player.previousTrack()
//        }
    }
    
    func updatePlaylist() {
        self.createPlaylistItems(urls: self.player.playlist)
        self.playlistOutlineView.reloadData()
    }
    
    func updateMedia() {
        if self.player.playlistHasMedia() {
            if let metadata = self.player.metadata {
                self.titleTextView.string = metadata.title
                self.detailsTextView.string = metadata.detailsString()
                if metadata.artwork != nil {
                    self.setCoverImage(image: metadata.artwork)
                    self.setBackgroundViewAndAppearance()
                } else {
                    self.resetCoverImage()
                    self.resetBackgroundViewAndAppearance()
                }
            } else {
                self.setUIDefaults()
            }
        } else {
            self.setDefaultAppearances()
        }
        
        self.updateDuration()
        self.startPositionTimer()
        self.updatePosition()
        
        self.updateNowPlayingInfoCenter()
        self.lastURL = self.player.currentURL
    }
    
    func updateDuration() {
        self.timeSlider.maxValue = self.player.duration
        self.durationLabel.stringValue = to_hhmmss(seconds: self.player.duration)
    }
    
    func setVolumeFromDefaults() {
        if let volume = self.application?.userDefaults.float(forKey: "Volume") {
            self.volumeSlider.floatValue = volume
            self.player.volume = volume
        }
    }
    
    func setPlaylistHiddenFromDefaults() {
        if let playlistHidden = self.application?.userDefaults.bool(forKey: "PlaylistHidden") {
            self.playlistBox.isHidden = playlistHidden
        }
    }
    
    func startPositionTimer() {
        self.positionTimer.invalidate()
        self.positionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updatePosition), userInfo: nil, repeats: true)
    }
    
    func createPlaylistItems(urls: [URL]) {
        self.playlistItems = []
        if urls.count > 0 {
            for i in 0...urls.count-1 {
                self.playlistItems.append(PlaylistItem(url: urls[i], trackIndex: i))
            }
        }
    }
    
    func removeMediaAtSelectedRows() {
        if self.playlistOutlineView.selectedRowIndexes.count > 0 {
            var selectedRows: [Int] = []
            for index in self.playlistOutlineView.selectedRowIndexes {
                selectedRows.append(index)
            }
            self.player.removeMedia(atIndexes: selectedRows)
        }
    }
    
    func killPlayer() {
        self.player.stop()
    }
    
    func killNowPlaying() {
        self.nowPlayingInfoCenter.nowPlayingInfo = [:]
        self.nowPlayingInfoCenter.playbackState = .unknown
    }
    
    func killTimers() {
        self.positionTimer.invalidate()
    }
    
    func alternateKeyDown(with event: NSEvent) -> Bool {
        guard let locWindow = view.window,
            self.application?.keyWindow === locWindow else { return false }
        let keyCode = event.keyCode
        
        switch keyCode {
        case Keycode.space:
            self.playPause()
            return true
        case Keycode.returnKey:
            self.playAtSelectedRow()
            return true
        case Keycode.delete:
            let flags = event.modifierFlags
            
            if isCommandModifierFlag(flags: flags) {
                self.playlistOutlineView.removeSelectedRows()
                return true
            }
        case Keycode.forwardDelete:
            self.playlistOutlineView.removeSelectedRows()
            return true
        default:
            break
        }
        
        return false
    }
}
