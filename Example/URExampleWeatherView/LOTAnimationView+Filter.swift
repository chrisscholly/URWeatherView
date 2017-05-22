//
//  LOTAnimationView+Filter.swift
//  URExampleWeatherView
//
//  Created by DongSoo Lee on 2017. 5. 19..
//  Copyright © 2017년 zigbang. All rights reserved.
//

import Lottie

class URLOTAnimationView: LOTAnimationView, URToneCurveAppliable {
    var originalImages: [UIImage]!
}

struct AssociatedKey {
    static var extensionAddress: UInt8 = 0
}

class URRawImages: NSObject {
    var rawImages: [UIImage]

    override init() {
        self.rawImages = [UIImage]()
        super.init()
    }
}

extension URToneCurveAppliable where Self: LOTAnimationView {
    var originals: URRawImages {
        guard let originals = objc_getAssociatedObject(self, &AssociatedKey.extensionAddress) as? URRawImages else {
            let originals: URRawImages = URRawImages()
            objc_setAssociatedObject(self, &AssociatedKey.extensionAddress, originals, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return originals
        }

        return originals
    }

    func applyToneCurveFilter(filterValues: [String: [CGPoint]], filterValuesSub: [String: [CGPoint]]? = nil) {
        if self.imageSolidLayers != nil {
//            if self.rawImages == nil {
//                self.rawImages = [UIImage]() as NSArray
//            }
            for (index, imageLayer) in self.imageSolidLayers.enumerated() {
                guard imageLayer.contents != nil else { continue }
                print("imageLayer before ====> \(imageLayer.contents!)")
                let cgImage = imageLayer.contents as! CGImage
//                self.originalImages[self.originalImages.count] = UIImage(cgImage: cgImage)
                self.originals.rawImages.append(UIImage(cgImage: cgImage))
//                self.originals.rawImages[self.originalImages.count] = UIImage(cgImage: cgImage)

                var values = filterValues
                if let subValues = filterValuesSub, index != 0 && index != (self.imageSolidLayers.count - 1) {
                    values = subValues
                }
                let red = URToneCurveFilter(cgImage: cgImage, with: values["R"]!).outputImage!
                let green = URToneCurveFilter(cgImage: cgImage, with: values["G"]!).outputImage!
                let blue = URToneCurveFilter(cgImage: cgImage, with: values["B"]!).outputImage!

                guard let resultImage: CIImage = URToneCurveFilter.colorKernel.apply(withExtent: red.extent, arguments: [red, green, blue]) else {
                    return
                }

                let context = CIContext(options: nil)
                guard let resultCGImage = context.createCGImage(resultImage, from: resultImage.extent) else {
                    fatalError("Not able to make CGImage of the result Filtered Image!!")
                }
                imageLayer.contents = resultCGImage
                self.replaceLayer(imageLayer, with: resultCGImage)
                print("imageLayer after  ====> \(imageLayer.contents!)")
//                guard let superLayer = imageLayer.superlayer else { return }
//                superLayer.display()
            }
        }
    }

    func replaceLayer(_ targetLayer: CALayer, with cgImage: CGImage) {
        guard let superLayer = targetLayer.superlayer else { return }
        let newLayer: CALayer = CALayer()
        newLayer.frame = targetLayer.frame
        newLayer.masksToBounds = targetLayer.masksToBounds
        newLayer.contents = cgImage
        superLayer.addSublayer(newLayer)
        superLayer.display()
    }

    func removeToneCurveFilter() {
        if self.imageSolidLayers != nil {
            for (index, imageLayer) in self.imageSolidLayers.enumerated() {
                guard imageLayer.contents != nil else { continue }
//                imageLayer.contents = self.originals.rawImages[index].cgImage
                self.replaceLayer(imageLayer, with: self.originals.rawImages[index].cgImage!)
            }
        }
    }
}
