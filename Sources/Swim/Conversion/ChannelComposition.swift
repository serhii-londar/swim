import Foundation

extension Image where P == GrayAlpha {
    @inlinable
    public init(gray: Image<Gray, T>, alpha: Image<Gray, T>) {
        precondition(gray.size == alpha.size, "Images must have same size.")
        
        let (width, height) = gray.size
        let data = interleave(data1: gray.data, data2: alpha.data)
        
        self.init(width: width, height: height, data: data)
    }
}

extension Image where P == RGB {
    @inlinable
    public init(r: Image<Gray, T>, g: Image<Gray, T>, b: Image<Gray, T>) {
        precondition(r.size == g.size && g.size == b.size, "Images must have same size.")
        
        let (width, height) = r.size
        let data = interleave(data1: r.data, data2: g.data, data3: b.data)
        
        self.init(width: width, height: height, data: data)
    }
}

extension Image where P == RGBA {
    @inlinable
    public init(r: Image<Gray, T>, g: Image<Gray, T>, b: Image<Gray, T>, a: Image<Gray, T>) {
        precondition(r.size == g.size && g.size == b.size && b.size == a.size, "Images must have same size.")
        
        let (width, height) = r.size
        let data = interleave(data1: r.data, data2: g.data, data3: b.data, data4: a.data)
        
        self.init(width: width, height: height, data: data)
    }
    
    @inlinable
    public init(rgb: Image<RGB, T>,  a: Image<Gray, T>) {
        precondition(rgb.size == a.size, "Images must have same size.")

        self = .createWithUnsafeMutableBufferPointer(width: a.width, height: a.height) { bp in
            for i in 0..<a.pixelCount {
                copy(src: rgb.data, srcOffset: 3*i, dst: bp, dstOffset: 4*i, count: 3)
                bp[4*i+3] = a.data[i]
            }
        }
    }
}

extension Image where P == ARGB {
    @inlinable
    public init(a: Image<Gray, T>, r: Image<Gray, T>, g: Image<Gray, T>, b: Image<Gray, T>) {
        precondition(a.size == r.size && r.size == g.size && g.size == b.size, "Images must have same size.")
        
        let (width, height) = r.size
        let data = interleave(data1: a.data, data2: r.data, data3: g.data, data4: b.data)
        
        self.init(width: width, height: height, data: data)
    }
    
    @inlinable
    public init(a: Image<Gray, T>, rgb: Image<RGB, T>) {
        precondition(rgb.size == a.size, "Images must have same size.")

        self = .createWithUnsafeMutableBufferPointer(width: a.width, height: a.height) { bp in
            for i in 0..<a.pixelCount {
                bp[4*i+0] = a.data[i]
                copy(src: rgb.data, srcOffset: 3*i, dst: bp, dstOffset: 4*i+1, count: 3)
            }
        }
    }
}
