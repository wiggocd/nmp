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
    let shadowRadius = CGFloat(8)
    let coverImageSize = NSSize(width: 640, height: 640)
    let UICornerRadius = CGFloat(4)
    let bgBlurRadius = CGFloat(50)
    let coverImageCornerRadius = CGFloat(10)
    let backgroundDarknessAlpha = CGFloat(0.5)
    let doubleClickInterval = 0.2
    let darkAppearance = NSAppearance(named: .darkAqua)
    let mediaHotKeyModifiers: NSEvent.ModifierFlags = [.command]
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    var player: AudioPlayer!
    var positionTimer: Timer!
    var playlistItems: [PlaylistItem] = []
    var lastSelectedPlaylistItem = 0
    var playlistItemClickTimer = Timer()
    var draggedNodes: [AnyObject]!
    var backgroundImageView: NSImageView!
    var defaultTitleColor: NSColor!
    var defaultDetailsColor: NSColor!
    var defaultTimeColor: NSColor!
    var hasShownTransparentAppearance = false
    
    @IBOutlet var titleTextView: NSTextView!
    @IBOutlet var detailsTextView: NSTextView!
    @IBOutlet weak var coverImageView: NSImageView!
    
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var rewindButton: NSButton!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var nextTrackButton: NSButton!
    @IBOutlet weak var playlistButton: NSButton!
    
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var positionLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var playlistScrollView: NSScrollView!
    @IBOutlet weak var playlistOutlineView: PlaylistOutlineView!
    
    var buttons: [NSButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = AudioPlayer()
        
        defaultTitleColor = titleTextView.textColor
        defaultDetailsColor = detailsTextView.textColor
        defaultTimeColor = positionLabel.textColor
        
        view.wantsLayer = true
        
        buttons = [
            openButton,
            rewindButton,
            playPauseButton,
            nextTrackButton,
            playlistButton
        ]
        
        setUIDefaults()
        addObservers()
        initialiseDragAndDrop()
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            super.keyDown(with: $0)
            if self.alternateKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
    }
    
    override func viewWillAppear() {
        updatePlaylist()
        initialisePlayerSession()
        updateMedia()
        setVolumeFromDefaults()
        setPlaylistHiddenFromDefaults()
        initialiseDragAndDrop()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewWillDisappear() {
        killPlayer()
        killNowPlaying()
        killTimers()
    }
    
    func setUIDefaults() {
        titleTextView.string = "Not Playing"
        detailsTextView.string = "No Media"
        positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        durationLabel.stringValue = to_hhmmss(seconds: 0.0)
        timeSlider.minValue = 0
        timeSlider.maxValue = 0
        timeSlider.doubleValue = 0.0
        playlistOutlineView.delegate = self
        playlistOutlineView.dataSource = self
        
        playlistOutlineView.indentationPerLevel = 0
        playlistOutlineView.roundCorners(withRadius: UICornerRadius)
        playlistScrollView.roundCorners(withRadius: UICornerRadius)
        
        resetCoverImage()
        resetBackgroundViewAndAppearance()
    }
    
    func setDefaultAppearances() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            
            let lastAlphaValue = view.alphaValue
            view.alphaValue = 0
            
            titleTextView.textColor = defaultTitleColor
            detailsTextView.textColor = defaultDetailsColor
            positionLabel.textColor = defaultTimeColor
            durationLabel.textColor = defaultTimeColor
            
            playlistOutlineView.appearance = NSApp.appearance
            if let showTransparentAppearance = application?.userDefaults.bool(forKey: "ShowTransparentAppearance") {
                if showTransparentAppearance || hasShownTransparentAppearance {
                    playlistOutlineView.backgroundColor = .controlBackgroundColor
                }
            }
            
            for button in buttons {
                button.appearance = NSApp.appearance
            }
            
            view.window?.appearance = NSApp.appearance
            view.animator().alphaValue = lastAlphaValue
        }
    }
    
    func setAlternateAppearances() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            
            let lastAlphaValue = view.alphaValue
            view.alphaValue = 0
            
            titleTextView.textColor = .white
            detailsTextView.textColor = .lightGray
            positionLabel.textColor = .gray
            durationLabel.textColor = .gray
            
            playlistOutlineView.appearance = darkAppearance
            if let showTransparentAppearance = application?.userDefaults.bool(forKey: "ShowTransparentAppearance") {
                hasShownTransparentAppearance = true
                if showTransparentAppearance {
                    let appearance = NSApp.effectiveAppearance
                    if appearance.name == NSAppearance.Name.aqua {
                        playlistOutlineView.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.02)
                    } else {
                        playlistOutlineView.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.2)
                    }
                } else {
                    playlistOutlineView.backgroundColor = .controlBackgroundColor
                }
            } else {
                playlistOutlineView.backgroundColor = .controlBackgroundColor
            }
            
            for button in buttons {
                button.appearance = darkAppearance
            }
            
            view.window?.appearance = darkAppearance
            view.animator().alphaValue = lastAlphaValue
        }
    }
    
    func addObservers() {
        notificationCenter.addObserver(self, selector: #selector(refresh), name: .preferencesChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playlistChanged), name: .playlistChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(mediaChanged), name: .mediaChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStarted), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackPaused), name: .playbackPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playPauseAction), name: .playPause, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playlistIndexesRemoved), name: .playlistIndexesRemoved, object: playlistOutlineView)
    }
    
    func removeObserver() {
        notificationCenter.removeObserver(self)
    }
    
    func initialiseDragAndDrop() {
        playlistOutlineView.registerForDraggedTypes(playlistPasteboardTypes)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
    }
    
    func initialisePlayerSession() {
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(togglePlayPauseCommandAction))
        
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.playCommand.addTarget(self, action: #selector(playCommandAction))
        
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommandAction))
        
        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrackCommandAction))
            
        remoteCommandCenter.nextTrackCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrackCommandAction))
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommandAction))
        
        preparePlayback()
        nowPlayingInfoCenter.nowPlayingInfo = [:]
    }
    
    func preparePlayback() {
        player.toggleMute()
        play()
        pause()
        player.toggleMute()
    }
    
    func setCoverImage(image: CGImage) {
        let scale = coverImageSize.height / CGFloat(image.height)
        let size = NSSize(width: coverImageSize.width * scale, height: coverImageSize.height * scale)
        
        coverImageView.image = NSImage(cgImage: image, size: size).roundCorners(withRadius: coverImageCornerRadius)
        setCoverImageShadow()
    }
    
    func resetCoverImage() {
        let image = NSImage()
        image.size = coverImageSize
        image.lockFocus()
        NSColor(red: 0, green: 0, blue: 0, alpha: 0.1).set()

        let imageRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageRect.fill()
        image.unlockFocus()

        coverImageView.image = image.roundCorners(withRadius: coverImageCornerRadius)
        setDefaultAppearances()
    }
    
    func setCoverImageShadow() {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(white: 0.2, alpha: 0.5)
        shadow.shadowBlurRadius = 10
        coverImageView.shadow = shadow
    }
    
    func setBackgroundViewAndAppearance() {
        if application!.colorBg! {
            if player.metadata != nil && player.metadata.artwork != nil && coverImageView != nil {
                let artwork = player.metadata.artwork
                let blurredImage = CIImage(cgImage: artwork!).blurred(radius: 64)
                
                if blurredImage != nil {
                    let cropRect = CIVector(x: 125, y: 125, z: CGFloat(artwork!.width) / CGFloat(2), w: CGFloat(artwork!.height) / CGFloat(2))
                    let croppedImage = blurredImage?.cropped(toRect: cropRect)
                    
                    if croppedImage != nil {
                        let transformedImage = croppedImage?.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
                        
                        if transformedImage != nil {
                            let bgImage = transformedImage?.nsImage().darkened(byBlackAlpha: backgroundDarknessAlpha)
                            view.layer?.contents = bgImage
                            
                            setAlternateAppearances()
                            
                            return
                        }
                    }
                }
            }
        }
        
        resetBackgroundViewAndAppearance()
    }
    
    func resetBackgroundViewAndAppearance() {
        view.layer?.contents = nil
        setDefaultAppearances()
    }
    
    func play() {
        player.play()
        startPositionTimer()
        nowPlayingInfoCenter.playbackState = .playing
    }
    
    func play(atIndex index: Int) {
        player.trackIndex = index
        player.play()
        startPositionTimer()
        nowPlayingInfoCenter.playbackState = .playing
    }
    
    func playAtSelectedRow() {
        play(atIndex: playlistOutlineView.selectedRow)
    }
    
    func pause() {
        player.pause()
        if positionTimer != nil {
            positionTimer.invalidate()
            positionTimer = nil
        }
        nowPlayingInfoCenter.playbackState = .paused
    }
    
    func playPause() {
        if player.state == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func nextTrack() {
        player.nextTrack()
    }
    
    func rewind() {
        if player.position > 1 {
            player.setPosition(position: 0)
        } else {
            player.previousTrack()
        }
    }
    
    func updatePlaylist() {
        createPlaylistItems(urls: player.playlist)
        playlistOutlineView.reloadData()
    }
    
    func updateMedia() {
        if player.playlistHasMedia() {
            if player.metadata != nil {
                titleTextView.string = player.metadata.title
                detailsTextView.string = player.metadata.detailsString()
                if player.metadata.artwork != nil {
                    setCoverImage(image: player.metadata.artwork)
                    setBackgroundViewAndAppearance()
                } else {
                    resetCoverImage()
                }
            }
        } else {
            setDefaultAppearances()
        }
        
        timeSlider.maxValue = player.duration()
        timeSlider.reset()
        positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        durationLabel.stringValue = to_hhmmss(seconds: player.duration())
        startPositionTimer()
        
        updateNowPlayingInfoCenter()
    }
    
    func updateNowPlayingInfoCenter() {
        if let audioPlayer = player.player {
            if player.metadata != nil, let metadata = player.metadata, let artwork = metadata.artwork {
                let coverArt = MPMediaItemArtwork(boundsSize: coverImageSize) { (size) -> NSImage in
                    return NSImage(cgImage: artwork, size: size)
                }
                
                let dict: [String: Any] = [
                    MPMediaItemPropertyArtwork: coverArt,
                    MPMediaItemPropertyTitle: metadata.title,
                    MPMediaItemPropertyArtist: metadata.artist,
                    MPMediaItemPropertyAlbumTitle: metadata.album,
                    MPNowPlayingInfoPropertyPlaybackRate: audioPlayer.rate,
                    MPNowPlayingInfoPropertyPlaybackProgress: audioPlayer.currentTime,
                    MPMediaItemPropertyPlaybackDuration: audioPlayer.duration
                ]
                
                nowPlayingInfoCenter.nowPlayingInfo = dict
            }
        } else {
            nowPlayingInfoCenter.nowPlayingInfo = [:]
        }
    }
    
    func setVolumeFromDefaults() {
        if let volume = application?.userDefaults.float(forKey: "Volume") {
            volumeSlider.floatValue = volume
            player.volume = volume
        }
    }
    
    func setPlaylistHiddenFromDefaults() {
        if let playlistHidden = application?.userDefaults.bool(forKey: "PlaylistHidden") {
            playlistScrollView.isHidden = playlistHidden
        }
    }
    
    func startPositionTimer() {
        if positionTimer == nil || !positionTimer.isValid {
            positionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePosition), userInfo: nil, repeats: true)
        }
    }
    
    func createPlaylistItems(urls: [URL]) {
        playlistItems = []
        if urls.count > 0 {
            for i in 0...urls.count-1 {
                playlistItems.append(PlaylistItem(name: fileDisplayName(path: urls[i].path), trackIndex: i))
            }
        }
    }
    
    func removeMediaAtSelectedRows() {
        if playlistOutlineView.selectedRowIndexes.count > 0 {
            var selectedRows: [Int] = []
            for index in playlistOutlineView.selectedRowIndexes {
                selectedRows.append(index)
            }
            player.removeMedia(atIndexes: selectedRows)
        }
    }
    
    func killPlayer() {
        player.stop()
        player = nil
    }
    
    func killNowPlaying() {
        nowPlayingInfoCenter.nowPlayingInfo = [:]
        nowPlayingInfoCenter.playbackState = .unknown
    }
    
    func killTimers() {
        positionTimer.invalidate()
    }
    
    func alternateKeyDown(with event: NSEvent) -> Bool {
        guard let locWindow = view.window,
        application?.keyWindow === locWindow else { return false }
        
        let keyCode = event.keyCode
        switch keyCode {
        case Keycode.space:
            playPause()
        case Keycode.returnKey:
            playAtSelectedRow()
        case Keycode.delete:
            if event.modifierFlags.contains(.command) {
                playlistOutlineView.removeSelectedRows()
            }
        default:
            break
        }
        
        return true
    }
}
