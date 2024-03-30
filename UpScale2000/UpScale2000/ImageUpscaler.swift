//
//  ImageUpscaler.swift
//  DrawOmatic
//
//  Created by Jones on 18/01/2024.
//

import Metal
import MetalKit
import MetalFX

class ImageUpscaler {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureLoader: MTKTextureLoader

    init?() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice(),
              let queue = defaultDevice.makeCommandQueue() else {
            return nil
        }
        self.device = defaultDevice
        self.commandQueue = queue
        self.textureLoader = MTKTextureLoader(device: device)
    }

    // FROM GENERATED IMAGE
//    private func createTexture(from image: CGImage) -> MTLTexture? {
//        let options: [MTKTextureLoader.Option: Any] = [
//            .SRGB: false, // Adjust based on your CGImage
//            .origin: MTKTextureLoader.Origin.topLeft // Adjust if needed
//        ]
//
//        do {
//            let texture = try textureLoader.newTexture(cgImage: image, options: options)
//            return texture
//        } catch {
//            print("Error creating texture: \(error)")
//            return nil
//        }
//    }
    
    func createTexture(url: URL, device: MTLDevice) /*throws*/ -> MTLTexture? {
//                let options: [MTKTextureLoader.Option: Any] = [
//                    .SRGB: false, // Adjust based on your CGImage
//                    .origin: MTKTextureLoader.Origin.topLeft // Adjust if needed
//                ]
        do {
        let loader = MTKTextureLoader(device: device)
            let texture = try loader.newTexture(URL: url, options: nil/*options*/)
        return texture
        } catch {
                    print("Error creating texture: \(error)")
                    return nil
                }
            }
        
//    func upscaleImage(_ image: CGImage, toSize newSize: CGSize) -> CGImage? {
    func upscaleImage(url: URL, toSize newSize: CGSize) -> CGImage? {
//        guard let inputTexture = createTexture(from: image) else { return nil }
        guard let inputTexture = createTexture(url: url, device: device) else { return nil }

        let scalerDescriptor = MTLFXSpatialScalerDescriptor()
        scalerDescriptor.inputWidth = inputTexture.width
        scalerDescriptor.inputHeight = inputTexture.height
        scalerDescriptor.colorTextureFormat = inputTexture.pixelFormat
        scalerDescriptor.outputWidth = Int(newSize.width)
        scalerDescriptor.outputHeight = Int(newSize.height)
        scalerDescriptor.outputTextureFormat = inputTexture.pixelFormat

        guard let spatialScaler = scalerDescriptor.makeSpatialScaler(device: device) else { return nil }
            spatialScaler.colorTexture = inputTexture

        let outputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: inputTexture.pixelFormat,
            width: Int(newSize.width),
            height: Int(newSize.height),
            mipmapped: false
        )
        outputTextureDescriptor.usage = [.renderTarget] // Set usage to render target
        outputTextureDescriptor.storageMode = .private  // Ensure storage mode is private

        guard let outputTexture = device.makeTexture(descriptor: outputTextureDescriptor) else { return nil }
        spatialScaler.outputTexture = outputTexture

            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
            spatialScaler.encode(commandBuffer: commandBuffer)

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            return textureToCGImage(outputTexture)
        }

    func textureToCGImage(_ texture: MTLTexture) -> CGImage? {
        let width = texture.width
        let height = texture.height
        let pixelByteCount = 4 * width * height

        // Create a new texture with shared storage mode
        let sharedTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: texture.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        sharedTextureDescriptor.storageMode = .shared
        sharedTextureDescriptor.usage = [.shaderRead]

        guard let sharedTexture = device.makeTexture(descriptor: sharedTextureDescriptor) else {
            return nil
        }

        // Copy from private texture to shared texture
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            return nil
        }

        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSize(width: width, height: height, depth: 1),
                         to: sharedTexture, destinationSlice: 0, destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Now read from the shared texture
        var rawData = [UInt8](repeating: 0, count: pixelByteCount)
        let region = MTLRegionMake2D(0, 0, width, height)
        sharedTexture.getBytes(&rawData, bytesPerRow: 4 * width, from: region, mipmapLevel: 0)

        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
            guard let providerRef = CGDataProvider(data: NSData(bytes: &rawData, length: pixelByteCount)),
                  let cgim = CGImage(
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: 4 * width,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                    provider: providerRef,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: CGColorRenderingIntent.defaultIntent
                  ) else {
                return nil
            }

            return cgim
        }

}
