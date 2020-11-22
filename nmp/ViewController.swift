//
//  ViewController.swift
//  nmp
//
//  Created by Kate Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var notificationCenter: NotificationCenter!
    var player: AudioPlayer!
    var positionTimer: Timer!
    var playlistItems: [PlaylistItem] = []
    
    let shadowRadius = CGFloat(8)
    let artworkSize = NSSize(width: 100, height: 100)
    let stdUICornerRadius = CGFloat(4)
    let bgBlurRadius = CGFloat(50)
    let coverImageCornerRadius = CGFloat(12)
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var detailsLabel: NSTextField!
    @IBOutlet weak var playlistView: NSScrollView!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var positionLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.notificationCenter = NotificationCenter.default
        self.player = AudioPlayer()
        self.timeSlider.minValue = 0
        titleLabel.stringValue = ""
        detailsLabel.stringValue = ""
        positionLabel.stringValue = ""
        durationLabel.stringValue = ""
        positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        durationLabel.stringValue = to_hhmmss(seconds: 0.0)
        timeSlider.doubleValue = 0.0
        addObservers()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func addObservers() {
        notificationCenter.addObserver(self, selector: #selector(mediaChanged), name: .mediaChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStarted), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackPaused), name: .playbackPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
    }
    
    func removeObserver() {
        notificationCenter.removeObserver(self)
    }
    
    func setCoverImage(image: CGImage) {
        let scale = CGFloat(image.height) / self.artworkSize.height
        let size = NSSize(width: artworkSize.width * scale, height: artworkSize.height * scale)
        
        coverImageView.image = NSImage(cgImage: image, size: size).roundCorners(withRadius: coverImageCornerRadius)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.lightGray
        shadow.shadowBlurRadius = 10
        coverImageView.shadow = shadow
    }
    
    func removeCoverImage() {
        coverImageView.image = nil
    }
    
    func setBackgroundView() {
        if coverImageView != nil && coverImageView.image != nil {
            let imageView = coverImageView.copy() as! NSImageView
            let scale = NSScreen.main!.frame.height / CGFloat(self.player.metadata.artwork.height)
            imageView.setFrameSize(NSSize(width: imageView.image!.size.width * scale, height: imageView.image!.size.height * scale))
            view.addSubview(imageView, positioned: .below, relativeTo: view.subviews[0])
        }
    }
    
    func play() {
        self.player.play()
        self.startPositionTimer()
    }
    
    func pause() {
        self.player.pause()
        if self.positionTimer != nil {
            self.positionTimer.invalidate()
            self.positionTimer = nil
        }
    }
    
    func playpause() {
        if self.player.state == .playing {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func startPositionTimer() {
        if self.positionTimer == nil || !self.positionTimer.isValid {
            self.positionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updatePosition), userInfo: nil, repeats: true)
        }
    }
    
    func createPlaylistItems(urls: [URL]) {
        for i in 0...urls.count-1 {
            playlistItems.append(PlaylistItem(name: fileDisplayName(path: urls[i].path), playlistIndex: i))
        }
    }
    
    func addPlaylistItemsToView(items: [PlaylistItem]) {
        for item in items {
            let contentSize = playlistView.contentSize
            let view = NSTextView()
            view.minSize = NSMakeSize(contentSize.width, 0.0)
            view.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
            view.insertText(item.name, replacementRange: NSMakeRange(0, 0))
            
            let documentView = NSView()
            playlistView.documentView = documentView
            documentView.addSubview(view)
        }
    }
    
    @IBAction func openAction(_ sender: Any) {
        player.addMedia(urls: openMedia())
    }
    
    @IBAction func playPauseAction(_ sender: Any) {
        self.playpause()
    }
    
    @IBAction func nextTrackAction(_ sender: Any) {
        self.player.nextTrack()
    }
    
    @IBAction func previousTrackAction(_ sender: Any) {
        self.player.previousTrack()
    }
    
    @IBAction func timeSliderMoved(_ sender: Any) {
        self.player.setPosition(position: timeSlider.doubleValue)
        self.positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @objc func updatePosition() {
        self.timeSlider.doubleValue = player.position()
        self.positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        if self.player.playlistHasMedia() {
//            titleLabel.isHidden = false
//            detailsLabel.isHidden = false
//            playlistView.isHidden = false
//            coverImageView.isHidden = false
//            timeSlider.isHidden = false
//            positionLabel.isHidden = false
//            durationLabel.isHidden = false
            
            if self.player.metadata != nil {
                titleLabel.stringValue = player.metadata.title
                detailsLabel.stringValue = player.metadata.detailsString()
                if self.player.metadata.artwork != nil {
                    setCoverImage(image: player.metadata.artwork)
                    //setBackgroundView()
                }
            }
            
            createPlaylistItems(urls: player.playlist)
            addPlaylistItemsToView(items: playlistItems)
        } else {
            titleLabel.stringValue = ""
            detailsLabel.stringValue = ""
            positionLabel.stringValue = to_hhmmss(seconds: 0.0)
            durationLabel.stringValue = to_hhmmss(seconds: 0.0)
            timeSlider.doubleValue = 0.0
            removeCoverImage()
//            titleLabel.isHidden = true
//            detailsLabel.isHidden = true
//            playlistView.isHidden = true
//            coverImageView.isHidden = true
//            timeSlider.isHidden = true
//            positionLabel.isHidden = true
//            durationLabel.isHidden = true
        }
        
        timeSlider.maxValue = self.player.duration()
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
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}

extension NSSlider {
    func reset() {
        doubleValue = minValue
    }
}

class PlaylistItem {
    var name: String
    var playlistIndex: Int
    
    init(name: String = "", playlistIndex: Int = 0) {
        self.name = name
        self.playlistIndex = playlistIndex
    }
}

