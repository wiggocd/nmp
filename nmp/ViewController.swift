//
//  ViewController.swift
//  nmp
//
//  Created by Kate Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate {
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
    var playlistDefaultAppearance: NSAppearance!
    
    let shadowRadius = CGFloat(8)
    let coverImageSize = NSSize(width: 640, height: 640)
    let UICornerRadius = CGFloat(4)
    let bgBlurRadius = CGFloat(50)
    let coverImageCornerRadius = CGFloat(10)
    let doubleClickInterval = 0.2
    let pasteboardTypes = getPasteboardTypes()
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var detailsLabel: NSTextField!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var positionLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var playlistButton: NSButton!
    @IBOutlet weak var playlistScrollView: NSScrollView!
    @IBOutlet weak var playlistOutlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter = NotificationCenter.default
        player = AudioPlayer()
        
        defaultTitleColor = titleLabel.textColor
        defaultDetailsColor = detailsLabel.textColor
        defaultTimeColor = positionLabel.textColor
        playlistDefaultAppearance = playlistOutlineView.appearance
        
        view.wantsLayer = true
        
        setUIDefaults()
        addObservers()
        initialiseDragDrop()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setUIDefaults() {
        titleLabel.stringValue = "Not Playing"
        detailsLabel.stringValue = "No Media"
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
    }
    
    func setDefaultAppearances() {
        titleLabel.textColor = defaultTitleColor
        detailsLabel.textColor = defaultDetailsColor
        positionLabel.textColor = defaultTimeColor
        durationLabel.textColor = defaultTimeColor
        playlistOutlineView.appearance = playlistDefaultAppearance
    }
    
    func setAlternateAppearances() {
        titleLabel.textColor = .white
        detailsLabel.textColor = .lightGray
        positionLabel.textColor = .gray
        durationLabel.textColor = .gray
        playlistOutlineView.appearance = NSAppearance(named: .darkAqua)
    }
    
    func addObservers() {
        notificationCenter.addObserver(self, selector: #selector(playlistChanged), name: .playlistChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(mediaChanged), name: .mediaChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStarted), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackPaused), name: .playbackPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
    }
    
    func initialiseDragDrop() {
        playlistOutlineView.registerForDraggedTypes(pasteboardTypes)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
        playlistOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
    }
    
    func removeObserver() {
        notificationCenter.removeObserver(self)
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
                        let bgImage = transformedImage?.nsImage().darkened(byBlackAlpha: 0.4)
                        view.layer?.contents = bgImage
                        
                        setAlternateAppearances()
                        
                        return
                    }
                }
            }
            
            view.layer?.contents = nil
        }
    }
    
    func play() {
        player.play()
        startPositionTimer()
    }
    
    func pause() {
        player.pause()
        if positionTimer != nil {
            positionTimer.invalidate()
            positionTimer = nil
        }
    }
    
    func playpause() {
        if player.state == .playing {
            pause()
        } else {
            play()
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
                playlistItems.append(PlaylistItem(name: fileDisplayName(path: urls[i].path), playlistIndex: i))
            }
        }
    }
    
    func play(atIndex index: Int) {
        player.playlistIndex = index
        player.play()
    }
    
    func playAtSelectedRow() {
        play(atIndex: playlistOutlineView.selectedRow)
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
    
    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        switch keyCode {
        case Keycode.space:
            player.playpause()
        case Keycode.returnKey:
            playAtSelectedRow()
        case Keycode.delete:
            removeMediaAtSelectedRows()
        default:
            break
        }
    }
}
