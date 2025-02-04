public struct BayerConverter {
    public enum Pattern {
        case bggr, gbrg, grbg, rggb
    }
    
    public var pattern: Pattern
    
    public init(pattern: Pattern) {
        self.pattern = pattern
    }
}

extension BayerConverter.Pattern {
    @inlinable
    var offsetToBGGR: (x: Int, y: Int) {
        switch self {
        case .bggr:
            return (0, 0)
        case .gbrg:
            return (1, 0)
        case .grbg:
            return (0, 1)
        case .rggb:
            return (1, 1)
        }
    }
}

extension BayerConverter {
    /// Convert color image to bayer format.
    @inlinable
    public func convert<T>(image: Image<RGB, T>) -> Image<Gray, T> {
        let (offsetX, offsetY) = pattern.offsetToBGGR
        
        return .createWithUnsafeMutableBufferPointer(width: image.width, height: image.height) { bp in
            var i = 0
            var redRow = offsetY % 2 != 0 // or blue row
            for y in 0..<image.height {
                var oddCol = offsetX % 2 != 0
                for x in 0..<image.width {
                    switch (oddCol, redRow) {
                    case (true, true): // r
                        bp[i] = image[x, y, .red]
                    case (false, true), (true, false): // g
                        bp[i] = image[x, y, .green]
                    case (false, false): // b
                        bp[i] = image[x, y, .blue]
                    }
                    i += 1
                    
                    oddCol.toggle()
                }
                
                redRow.toggle()
            }
        }
    }
}

extension BayerConverter {
    /// Convert color image to bayer format.
    @inlinable
    public func demosaic<T: BinaryInteger>(image: Image<Gray, T>) -> Image<RGB, T> {
        let (offsetX, offsetY) = pattern.offsetToBGGR
        
        func crossMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            var sum = 0
            var count = 0
            if x-1 >= 0 {
                sum += Int(image.data[index - 1])
                count += 1
            }
            if x+1 < image.width {
                sum += Int(image.data[index + 1])
                count += 1
            }
            if y-1 >= 0 {
                sum += Int(image.data[index - image.width])
                count += 1
            }
            if y+1 < image.height {
                sum += Int(image.data[index + image.width])
                count += 1
            }
            return T(sum / count)
        }
        
        func diagMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            var sum = 0
            var count = 0
            
            if y-1 >= 0 {
                if x-1 >= 0 {
                    sum += Int(image.data[index - image.width - 1])
                    count += 1
                }
                if x+1 < image.width {
                    sum += Int(image.data[index - image.width + 1])
                    count += 1
                }
            }
            
            if y+1 < image.height {
                if x-1 >= 0 {
                    sum += Int(image.data[index + image.width - 1])
                    count += 1
                }
                if x+1 < image.width {
                    sum += Int(image.data[index + image.width + 1])
                    count += 1
                }
            }
            
            return T(sum / count)
        }
        
        func horizontalMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            guard x-1 >= 0 else {
                return image.data[index + 1]
            }
            guard x+1 < image.width else {
                return image.data[index - 1]
            }
            return T((Int(image.data[index - 1]) + Int(image.data[index + 1])) / 2)
        }
        
        func verticalMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            guard y-1 >= 0 else {
                return image.data[index + image.width]
            }
            guard y+1 < image.height else {
                return image.data[index - image.width]
            }
            return T((Int(image.data[index - image.width]) + Int(image.data[index + image.width])) / 2)
        }
        
        func getPixelValue(x: Int, y: Int, channel: RGB) -> T {
            let xOdd = (x + offsetX) % 2 == 1
            let yOdd = (y + offsetY) % 2 == 1
            
            switch (xOdd, yOdd, channel) {
            case (false, false, .red):
                return diagMean(x: x, y: y)
            case (false, false, .green):
                return crossMean(x: x, y: y)
            case (false, false, .blue):
                return image[x, y, .gray]
            case (true, false, .red):
                return verticalMean(x: x, y: y)
            case (true, false, .green):
                return image[x, y, .gray]
            case (true, false, .blue):
                return horizontalMean(x: x, y: y)
            case (false, true, .red):
                return horizontalMean(x: x, y: y)
            case (false, true, .green):
                return image[x, y, .gray]
            case (false, true, .blue):
                return verticalMean(x: x, y: y)
            case (true, true, .red):
                return image[x, y, .gray]
            case (true, true, .green):
                return crossMean(x: x, y: y)
            case (true, true, .blue):
                return diagMean(x: x, y: y)
            }
        }
        
        return .createWithPixelRef(width: image.width, height: image.height) { ref in
            ref[.red] = getPixelValue(x: ref.x, y: ref.y, channel: .red)
            ref[.green] = getPixelValue(x: ref.x, y: ref.y, channel: .green)
            ref[.blue] = getPixelValue(x: ref.x, y: ref.y, channel: .blue)
        }
    }
    
    /// Reconstruct color image from bayer format image.
    @inlinable
    public func demosaic<T: BinaryFloatingPoint>(image: Image<Gray, T>) -> Image<RGB, T> {
        let (offsetX, offsetY) = pattern.offsetToBGGR
        
        func crossMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            var sum: T = 0
            var count = 0
            if x-1 >= 0 {
                sum += image.data[index - 1]
                count += 1
            }
            if x+1 < image.width {
                sum += image.data[index + 1]
                count += 1
            }
            if y-1 >= 0 {
                sum += image.data[index - image.width]
                count += 1
            }
            if y+1 < image.height {
                sum += image.data[index + image.width]
                count += 1
            }
            return sum / T(count)
        }
        
        func diagMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            var sum: T = 0
            var count = 0
            
            if y-1 >= 0 {
                if x-1 >= 0 {
                    sum += image.data[index - image.width - 1]
                    count += 1
                }
                if x+1 < image.width {
                    sum += image.data[index - image.width + 1]
                    count += 1
                }
            }
            
            if y+1 < image.height {
                if x-1 >= 0 {
                    sum += image.data[index + image.width - 1]
                    count += 1
                }
                if x+1 < image.width {
                    sum += image.data[index + image.width + 1]
                    count += 1
                }
            }
            
            return sum / T(count)
        }
        
        func horizontalMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            guard x-1 >= 0 else {
                return image.data[index + 1]
            }
            guard x+1 < image.width else {
                return image.data[index - 1]
            }
            return (image.data[index - 1] + image.data[index + 1]) / 2
        }
        
        func verticalMean(x: Int, y: Int) -> T {
            let index = image.dataIndex(x: x, y: y)
            guard y-1 >= 0 else {
                return image.data[index + image.width]
            }
            guard y+1 < image.height else {
                return image.data[index - image.width]
            }
            return (image.data[index - image.width] + image.data[index + image.width]) / 2
        }
        
        func getPixelValue(x: Int, y: Int, channel: RGB) -> T {
            let xOdd = (x + offsetX) % 2 == 1
            let yOdd = (y + offsetY) % 2 == 1
            
            switch (xOdd, yOdd, channel) {
            case (false, false, .red):
                return diagMean(x: x, y: y)
            case (false, false, .green):
                return crossMean(x: x, y: y)
            case (false, false, .blue):
                return image[x, y, .gray]
            case (true, false, .red):
                return verticalMean(x: x, y: y)
            case (true, false, .green):
                return image[x, y, .gray]
            case (true, false, .blue):
                return horizontalMean(x: x, y: y)
            case (false, true, .red):
                return horizontalMean(x: x, y: y)
            case (false, true, .green):
                return image[x, y, .gray]
            case (false, true, .blue):
                return verticalMean(x: x, y: y)
            case (true, true, .red):
                return image[x, y, .gray]
            case (true, true, .green):
                return crossMean(x: x, y: y)
            case (true, true, .blue):
                return diagMean(x: x, y: y)
            }
        }
        
        return .createWithPixelRef(width: image.width, height: image.height)  { ref in
            ref[.red] = getPixelValue(x: ref.x, y: ref.y, channel: .red)
            ref[.green] = getPixelValue(x: ref.x, y: ref.y, channel: .green)
            ref[.blue] = getPixelValue(x: ref.x, y: ref.y, channel: .blue)
        }
    }
}
