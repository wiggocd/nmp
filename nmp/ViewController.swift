//
//  ViewController.swift
//  nmp
//
//  Created by C. Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa
import HotKey

class ViewController: DefaultViewController, NSOutlineViewDelegate {
    var notificationCenter: NotificationCenter!
    var player: AudioPlayer!
    var positionTimer: Timer!
    var playlistItems: [PlaylistItem] = []
    var lastSelectedPlaylistItem = 0
    var playlistItemClickTimer = Timer()
    var draggedNode: AnyObject!
    var backgroundImageView: NSImageView!
    var defaultTitleColor: NSColor!
    var defaultDetailsColor: NSColor!
    var defaultTimeColor: NSColor!
    var defaultAppearance: NSAppearance!
    var playPauseKey: HotKey!
    var rewindKey: HotKey!
    var nextTrackKey: HotKey!
    var titleScrollTimer: Timer!
    
    @IBOutlet var titleTextView: NSTextView!
    @IBOutlet var detailsTextView: NSTextView!
    @IBOutlet weak var titleScrollView: NonUserScrollableScrollView!
    @IBOutlet weak var detailsScrollView: NonUserScrollableScrollView!
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
    @IBOutlet weak var playlistOutlineView: NSOutlineView!
    
    let application = Application.shared as? Application
    let shadowRadius = CGFloat(8)
    let coverImageSize = NSSize(width: 640, height: 640)
    let UICornerRadius = CGFloat(4)
    let bgBlurRadius = CGFloat(50)
    let coverImageCornerRadius = CGFloat(10)
    let backgroundDarknessAlpha = CGFloat(0.5)
    let doubleClickInterval = 0.2
    let pasteboardTypes = getPasteboardTypes()
    let darkAppearance = NSAppearance(named: .darkAqua)
    let mediaHotKeyModifiers: NSEvent.ModifierFlags = [.command]
    
    var buttons: [NSButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter = NotificationCenter.default
        loadBookmarkData()
        player = AudioPlayer()
        
        defaultTitleColor = titleTextView.textColor
        defaultDetailsColor = detailsTextView.textColor
        defaultTimeColor = positionLabel.textColor
        defaultAppearance = view.appearance
        
        view.wantsLayer = true
        
        buttons = [
            openButton,
            rewindButton,
            playPauseButton,
            nextTrackButton,
            playlistButton
        ]
        
        initialiseTextViews()
        setUIDefaults()
        addObservers()
        initialiseDragDrop()
        addHotKeys()
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            super.keyDown(with: $0)
            if self.alternateKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
        
        updatePlaylist()
        updateMedia()
        setVolumeFromDefaults()
        setPlaylistHiddenFromDefaults()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopTimers()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func initialiseTextViews() {
//        titleScrollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//            let visibleRect = self.titleTextView.visibleRect
//            let newRect = NSRect(x: visibleRect.minX + 10, y: visibleRect.minY + 10, width: visibleRect.width, height: visibleRect.height)
//            self.titleTextView.scrollToVisible(newRect)
//        }
    }
    
    func stopTimers() {
//        titleScrollTimer.invalidate()
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
        
        setDefaultAppearances()
        
        playlistOutlineView.indentationPerLevel = 0
        playlistOutlineView.roundCorners(withRadius: UICornerRadius)
        playlistScrollView.roundCorners(withRadius: UICornerRadius)
        
        resetCoverImage()
        resetBackgroundView()
    }
    
    func setDefaultAppearances() {
        titleTextView.textColor = defaultTitleColor
        detailsTextView.textColor = defaultDetailsColor
        positionLabel.textColor = defaultTimeColor
        durationLabel.textColor = defaultTimeColor
        playlistOutlineView.appearance = defaultAppearance
        
        playlistOutlineView.backgroundColor = playlistOutlineView.backgroundColor.withAlphaComponent(1)
        
        for button in buttons {
            button.appearance = defaultAppearance
        }
    }
    
    func setAlternateAppearances() {
        titleTextView.textColor = .white
        detailsTextView.textColor = .lightGray
        positionLabel.textColor = .gray
        durationLabel.textColor = .gray
        playlistOutlineView.appearance = darkAppearance
        
        playlistOutlineView.backgroundColor = playlistOutlineView.backgroundColor.withAlphaComponent(0.06)
        
        for button in buttons {
            button.appearance = darkAppearance
        }
    }
    
    func addObservers() {
        notificationCenter.addObserver(self, selector: #selector(playlistChanged), name: .playlistChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(mediaChanged), name: .mediaChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStarted), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackPaused), name: .playbackPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playPauseAction), name: .playPause, object: nil)
    }
    
    func removeObserver() {
        notificationCenter.removeObserver(self)
    }
    
    func initialiseDragDrop() {
        playlistOutlineView.registerForDraggedTypes(pasteboardTypes)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
    }
    
    func addHotKeys() {
        playPauseKey = HotKey(key: .f1, modifiers: [.command])
        playPauseKey.keyDownHandler = playPause
        
        rewindKey = HotKey(key: .f2, modifiers: mediaHotKeyModifiers)
        rewindKey.keyDownHandler = rewind
        
        nextTrackKey = HotKey(key: .f3, modifiers: mediaHotKeyModifiers)
        nextTrackKey.keyDownHandler = nextTrack
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
    
    func setBackgroundView() {
        if player.metadata.artwork != nil && coverImageView != nil {
            // Todo: add blurred background from artwork
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
            
            view.layer?.contents = nil
        }
    }
    
    func resetBackgroundView() {
        view.layer?.contents = nil
    }
    
    func play() {
        player.play()
        startPositionTimer()
    }
    
    func play(atIndex index: Int) {
        player.trackIndex = index
        player.play()
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
                    setBackgroundView()
                    playPauseButton.appearance = NSAppearance(named: .darkAqua)
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
    }
    
    func setVolumeFromDefaults() {
        if let volume = application?.userDefaults.float(forKey: "Volume") {
            volumeSlider.floatValue = volume
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
    
    func alternateKeyDown(with event: NSEvent) -> Bool {
        guard let locWindow = view.window,
            application?.keyWindow === locWindow else { return false }
        
        let keyCode = event.keyCode
        switch keyCode {
        case Keycode.space:
            player.playPause()
        case Keycode.returnKey:
            playAtSelectedRow()
        case Keycode.delete:
            removeMediaAtSelectedRows()
        default:
            break
        }
        
        return true
    }
}
