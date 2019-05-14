# Swim
Image library for Swift.

## Generic `Image` type
```swift
struct Image<P: PixelType, T: DataType>
```

Supported types  
PixelType: `Intensity`, `IntensityAlpha`, `RGB`, `RGBA`, `ARGB`  
DataType: `Bool`, `UInt8`, `Int`, `Float`, `Double`  

## Creation
```swift
let image = Image<RGBA, UInt8>(width: 3, height: 5, data: uint8Array])

// Can use type inference
let intensity = Image(width: 3, height: 20, intensity: intArray)
let rgb = Image(width: 4, height: 5, rgb: floatArray)
let rgba = Image(width: 3, height: 5, rgba: doubleArray)
let argb = Image(width: 5, height: 3, argb: uint8Array)
```

## Save/Load image
```swift
let image = Image<RGBA, UInt8>(contentsOf: url)!
try? image.write(path: dstPath)
```

## Associate with CoreGraphics
```swift
let image = Image<RGBA, UInt8>(contentsOf: url)!

// on macOS
let nsImage = image.nsImage()
let imageFromNS = Image<RGBA, UInt8>(nsImage: nsImage)!

// on iOS
let uiImage = image.uiImage()
let imageFromUI = Image<RGBA, UInt8>(uiImage: uiImage)!
```

## Subscriptions
### Pixel manipulation
```swift
let image = Image<RGBA, UInt8>(contentsOf: url)!
let px: Pixel<RGBA, UInt8> = image[0, 0]
let red: UInt8 = image[0, 0, 0] // red channel of (x: 0, y: 0)
let red2: UInt8 = image[0, 0, .red] // ditto
let red3: UInt8 = image[0, 0][.red] // ditto

image[1, 0] += 1 // Add 1 for R,G,B,A respectively
image[1, 0, .green] += 1 // Add 1 for Green channel
```

### Subimage
```swift
let image = Image<RGBA, UInt8>(contentsOf: url)!
let sub1: Image<RGBA, UInt8> = image[0..<100, 0..<100]
let sub2: Image<RGBA, UInt8> = image[rows: 0..<100]
image[col: 2] += 1
```

### Channel extraction
```swift
let image = Image<RGBA, UInt8>(contentsOf: url)!
let red: Image<Intensity, UInt8> = image[channel: 0]
image[channel: .blue] += 1
```

## Conversion

```swift
let image = Image<RGB, Float>(contentsOf: url)!

// to gray scale
let brightness: Image<Intensity, Float> = image.toBrightness()
let luminance: Image<Intensity, Float> = image.toLuminance()

// type conversion
let doubleImage1: Image<RGB, Double> = image.cast()
let doubleImage2 = image.cast(to: Double.self) // ditto

// pixel conversion
let redOnlyRGBA = image.pixelwiseConverted { px in 
    Pixel(r: px[.red], g: 0, b: 0, a: 1)
}
```

## Resize
```swift 
let image = Image<RGB, Float>(contentsOf: url)!
let resizedBL = image.resize(width: 512, height: 512) // default bilinear
let resizedNN = image.resize(width: 512, height: 512, method: .nearestNeighbor)
let resizedBC = image.resize(width: 512, height: 512, method: .bicubic)
let resizedAA = image.resize(width: 512, height: 512, method: .areaAverage)
```

[Example: NearestNeighbor / Bilinear / Bicubic](https://github.com/t-ae/swim/blob/7a055c45e4a1db9755f04a785599e18fde1f86bd/Tests/VisualTests/ResizeVisualTests.swift#L29-L44)

![resize](https://user-images.githubusercontent.com/12446914/56634980-dbccaa80-669e-11e9-90f7-5046d85e9f29.png)

## Warp
```swift
let image = Image<RGBA, Double>(contentsOf: url)!
let affine = AffineTransformation<Double>(scale: (1, 1.5), rotation: .pi/6. translation: (100, 120))
// `edgeMode` specifies how to fill pixels outside the base image.
let interpolator = BilinearInterpolator<RGBA, Double>(edgeMode: .edge)
let warpedImage = image.warp(transformation: affine, outputSize: (500, 500), interpolator: interpolator)
```

[Example: NN+Wrap / BL+Constant / BC+Reflect](https://github.com/t-ae/swim/blob/7a055c45e4a1db9755f04a785599e18fde1f86bd/Tests/VisualTests/WarpVisualTests.swift#L140-L172)

![warp](https://user-images.githubusercontent.com/12446914/56634776-2a2d7980-669e-11e9-8ff2-179dbdb3dff4.png)

## Advanced

### Correlation
```swift
let image1 = Image<Intensity, Float>(contentsOf: url1)!
let image2 = Image<Intensity, Float>(contentsOf: url2)!

let ssd = Correlation.ssd(image1, image2)
let sad = Correlation.sad(image1, image2)
let ncc = Correlation.ncc(image1, image2)
let zncc = Correlation.zncc(image1, image2)
```

### Blending
```swift
var imageBase = Image<RGB, Float>(width: 100,
                                  height: 100,
                                  data: [Float](repeating: 1, count: 100*100*3))
imageBase[30..<70, 20..<60].fill(Pixel(r: 1, g: 0, b: 0))

var imageGreen = Image<RGBA, Float>(width: 100,
                                    height: 100,
                                    data: [Float](repeating: 0, count: 100*100*4))
imageGreen[20..<60, 40..<80].fill(Pixel(r: 0, g: 1, b: 0, a: 0.5))

// Alpha blending
Blender.alphaBlend(top: imageGreen, bottom: &imageBase)

// or other blend modes
Blender.multiplyBlend(top: imageGreen, bottom: &imageBase)
Blender.additiveBlend(top: imageGreen, bottom: &imageBase)
Blender.screenBlend(top: imageGreen, bottom: &imageBase)
Blender.overlayBlend(top: imageGreen, bottom: &imageBase)
```

### Integral image
```swift 
let image = Image<Intensity, Float>(contentsOf: url)!
let integral = IntegralImageConverter.convert(image: image)
```

### Convolution/Filter

```swift 
let image = Image<Intensity, Float>(contentsOf: url)!
let blur = image.convoluted(Filter.gaussian3x3)
let maximum = image.rankFilter(.maximum, kernelSize: 3)
```

[Example: Gaussian x10 / Mean x10 / Emboss / Sobel(Horizontal) / Laplacian](https://github.com/t-ae/swim/blob/af1fa115cffe7c20513cb37e91e1549790fb2a5c/Tests/VisualTests/FilterVisualTests.swift#L68-L98)

![filter](https://user-images.githubusercontent.com/12446914/56787940-00f52080-6839-11e9-8171-22d8dab37910.png)

### Bayer filter
```swift 
let image = Image<RGB, Float>(contentsOf: url)!
let converter = BayerConverter(pattern: .bggr)
let bayer = converter.convert(image: image)
let reconstruct = converter.demosaic(image: bayer)
```

[Example: Base / Bayer format / Reconstructed](https://github.com/t-ae/swim/blob/7a055c45e4a1db9755f04a785599e18fde1f86bd/Tests/VisualTests/BayerVisualTests.swift#L12-L27)

![bayer_bggr](https://user-images.githubusercontent.com/12446914/56634959-cce5f800-669e-11e9-89a2-ce49121a44bc.png)

---

[VisualTests](https://github.com/t-ae/swim/blob/master/Tests/VisualTests) contains examples (works only on macOS).

## License

[The MIT License](https://github.com/t-ae/swim/blob/master/LICENSE)
