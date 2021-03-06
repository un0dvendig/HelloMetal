/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Metal
import QuartzCore
import simd
import UIKit

class Node {
  
  // MARK: - Properties
  
  var bufferProvider: BufferProvider
  let device: MTLDevice
  let light = Light(color: (1.0, 1.0, 1.0), ambientIntensity: 0.1, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
  let name: String
  var positionX: Float = 0.0
  var positionY: Float = 0.0
  var positionZ: Float = 0.0
  var rotationX: Float = 0.0
  var rotationY: Float = 0.0
  var rotationZ: Float = 0.0
  lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)
  var scale: Float {
    // TODO: Handle iPhoneX properly
    if UIDevice.current.hasNotch {
      return 0.9
    } else {
      return 1.0
    }
  }
  var texture: MTLTexture
  var time: CFTimeInterval = 0.0
  var vertexCount: Int
  var vertexBuffer: MTLBuffer

  // MARK: - Initialization
  
  init(name: String, vertices: [Vertex], device: MTLDevice, texture: MTLTexture) {
    // 1. Go through each vertex and form a single buffer
    // with floats, which will look like this:
    // [x,y,z,r,g,b,a , x,y,z,r,g,b,a , x,y,z,r,g,b,a ,...]
    //        V1              V2              V3
    var vertexData = [Float]()
    for vertex in vertices {
      vertexData += vertex.floatBuffer()
    }
    
    // 2. Ask the device to create a vertex buffer with the float buffer you created above.
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])!
    
    // 3. Set the instance variables
    self.name = name
    self.device = device
    self.vertexCount = vertices.count
    self.texture = texture
    
    let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2 + Light.size()
    self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeOfUniformsBuffer)
  }
  
  // MARK: - Methods
  
  func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
    _ = bufferProvider.availableResourcesSemaphore.wait(timeout: .distantFuture)
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor =
      MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer?.addCompletedHandler{ (_) in
      self.bufferProvider.availableResourcesSemaphore.signal()
    }

    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    
    // For now cull mode is used instead of depth buffer
    renderEncoder?.setCullMode(MTLCullMode.front)
    
    renderEncoder?.setRenderPipelineState(pipelineState)
    renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    
    renderEncoder?.setFragmentTexture(texture, index: 0)
    if let samplerState = samplerState {
      renderEncoder?.setFragmentSamplerState(samplerState, index: 0)
    }
    
    // 1. Convert the convenience properties (like position
    // and rotation) into a model matrix
    var nodeModelMatrix = self.modelMatrix()
    
    // parentModelViewMatrix represents camera position
    nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
    
    // 2. Ask the device to create a buffer with
    // shared CPU/GPU memory
    
    // 3. Get a raw pointer from buffer
    // (similar to `void *`) in Objective-C
    // memcpy
    
    // 4. Copy the matrix data into the buffer
    
    let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix, light: light)
    
    // 5. Pass `uniformBuffer` (with data copied) to the
    // vertex shader. This is similar to how we sent
    // the buffer to verex-specific data, expect
    // we use index 1 instead of 0
    renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
    renderEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
    
    renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,
      instanceCount: vertexCount/3)
    renderEncoder?.endEncoding()

    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
  
  func modelMatrix() -> float4x4 {
    var matrix = float4x4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }
  
  func updateWithDelta(delta: CFTimeInterval) {
    time += delta
  }
  
  class func defaultSampler(device: MTLDevice) -> MTLSamplerState? {
    let sampler = MTLSamplerDescriptor()
    sampler.minFilter = .nearest
    sampler.magFilter = .nearest
    sampler.mipFilter = .nearest
    sampler.maxAnisotropy = 1
    sampler.sAddressMode = .clampToEdge
    sampler.tAddressMode = .clampToEdge
    sampler.rAddressMode = .clampToEdge
    sampler.normalizedCoordinates = true
    sampler.lodMinClamp = 0
    sampler.lodMaxClamp = .greatestFiniteMagnitude
    return device.makeSamplerState(descriptor: sampler)
  }
  
}
