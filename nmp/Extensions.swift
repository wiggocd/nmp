//
//  Extensions.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AppKit

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
    
    func darkened(byBlackAlpha alpha: CGFloat) -> NSImage {
        let rect = NSRect(origin: .zero, size: size)
        
        let cgImage = self.cgImage
        let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context?.draw(cgImage!, in: rect)
        context?.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: alpha))
        context?.fill(rect)
        
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

extension CIImage {
    func blurred(radius: NSNumber) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(self, forKey: "inputImage")
        filter?.setValue(radius, forKey: "inputRadius")
        return filter?.value(forKey: "outputImage") as? CIImage
    }
    
    func cropped(toRect rect: CIVector) -> CIImage? {
        let filter = CIFilter(name: "CICrop")
        filter?.setValue(self, forKey: "inputImage")
        filter?.setValue(rect, forKey: "inputRectangle")
        return filter?.value(forKey: "outputImage") as? CIImage
    }
    
    func transformedAlternate(scale: NSNumber) -> CIImage? {
        let filter = CIFilter(name: "CILanczosScaleTransform")
        filter?.setValue(self, forKey: "inputImage")
        filter?.setValue(scale, forKey: "inputScale")
        return filter?.value(forKey: "outputImage") as? CIImage
    }
    
    func nsImage() -> NSImage {
        let rep = NSCIImageRep(ciImage: self)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}

extension NSSlider {
    func reset() {
        doubleValue = minValue
    }
}

extension NSView {
    func roundCorners(withRadius radius: CGFloat) {
        wantsLayer = true
        layer?.cornerRadius = radius
    }
}
