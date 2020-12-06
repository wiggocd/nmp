//
//  ViewController.swift
//  nmp
//
//  Created by Kate Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    var notificationCenter: NotificationCenter!
    var player: AudioPlayer!
    var positionTimer: Timer!
    var playlistItems: [PlaylistItem] = []
    var lastSelectedPlaylistItem = 0
    var playlistItemClickTimer = Timer()
    
    let shadowRadius = CGFloat(8)
    let coverImageSize = NSSize(width: 640, height: 640)
    let UICornerRadius = CGFloat(4)
    let bgBlurRadius = CGFloat(50)
    let coverImageCornerRadius = CGFloat(10)
    let doubleClickInterval = 0.2
    
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
        setUIDefaults()
        addObservers()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func addObservers() {
        notificationCenter.addObserver(self, selector: #selector(playlistChanged), name: .playlistChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(mediaChanged), name: .mediaChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStarted), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackPaused), name: .playbackPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
    }
    
    func removeObserver() {
        notificationCenter.removeObserver(self)
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
        
        resetCoverImage()
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
    }
    
    func setCoverImageShadow() {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.lightGray
        shadow.shadowBlurRadius = 10
        coverImageView.shadow = shadow
    }
    
    func setBackgroundView() {
        if coverImageView != nil && coverImageView.image != nil {
            // Todo: add blurred background from artwork
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
        for i in 0...urls.count-1 {
            playlistItems.append(PlaylistItem(name: fileDisplayName(path: urls[i].path), playlistIndex: i))
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if ((item as? PlaylistItem) != nil) {
            return 1
        } else {
            return playlistItems.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? PlaylistItem {
            return item
        } else {
            return playlistItems[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: tableColumn?.headerCell) as? NSTableCellView // Returns nil if no view cell is in place within interface builder
        
        if let item = item as? PlaylistItem {
            cell?.textField?.stringValue = item.name
        }
        
        cell?.textField?.textColor = NSColor.controlTextColor
        
        return cell
    }
    
    func play(atIndex index: Int) {
        player.playlistIndex = index
        player.play()
    }
    
    // Todo: add drag and drop data sources
    
    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        switch keyCode {
        case Keycode.space:
            player.playpause()
        case Keycode.returnKey:
            play(atIndex: playlistOutlineView.selectedRow)
        case Keycode.delete:
            player.removeMedia(atIndex: playlistOutlineView.selectedRow)
        default:
            break
        }
    }
    
    @IBAction func playlistOutlineViewDoubleAction(_ sender: Any) {
        if let sender = sender as? NSOutlineView {
            play(atIndex: sender.selectedRow)
        }
    }
    
    @IBAction func openAction(_ sender: Any) {
        player.addMedia(urls: openMedia())
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
    
    @objc func updatePosition() {
        timeSlider.doubleValue = player.position()
        positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        createPlaylistItems(urls: player.playlist)
        playlistOutlineView.reloadData()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        if player.playlistHasMedia() {
            if player.metadata != nil {
                titleLabel.stringValue = player.metadata.title
                detailsLabel.stringValue = player.metadata.detailsString()
                if player.metadata.artwork != nil {
                    setCoverImage(image: player.metadata.artwork)
                    setBackgroundView()
                } else {
                    resetCoverImage()
                }
            }
        }
        
        timeSlider.maxValue = player.duration()
        timeSlider.reset()
        positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        durationLabel.stringValue = to_hhmmss(seconds: player.duration())
        startPositionTimer()
    }
    
    @objc func playbackStarted(_ notification: Notification) {
        playPauseButton.title = "Pause"
    }
    
    @objc func playbackPaused(_ notification: Notification) {
        playPauseButton.title = "Play"
    }
    
    @objc func playbackStopped(_ notification: Notification) {
        playPauseButton.title = "Play"
    }
    
    @IBAction func playlistAction(_ sender: Any) {
        if playlistScrollView.isHidden {
            playlistScrollView.isHidden = false
        } else {
            playlistScrollView.isHidden = true
        }
    }
    
}

class PlaylistItem: NSObject {
    var name: String
    var playlistIndex: Int
    
    init(name: String = "", playlistIndex: Int = 0) {
        self.name = name
        self.playlistIndex = playlistIndex
    }
}

extension NSImage {
    func roundCorners(withRadius radius: CGFloat) -> NSImage {
        let rect = NSRect(origin: .zero, size: size)
        
        let cgImage = self.cgImage
        let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.beginPath()
        context?.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context?.closePath()
        context?.clip()
        context?.draw(cgImage!, in: rect)
        
        if let composedImage = context?.makeImage() {
            return NSImage(cgImage: composedImage, size: size)
        }
        
        return self
    }
}

fileprivate extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}

extension NSSlider {
    func reset() {
        doubleValue = minValue
    }
}

