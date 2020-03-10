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

class Node {
  
  // MARK: - Properties
  
  let device: MTLDevice
  let name: String
  var vertexCount: Int
  var vertexBuffer: MTLBuffer
  
  var positionX: Float = 0.0
  var positionY: Float = 0.0
  var positionZ: Float = 0.0
  
  var rotationX: Float = 0.0
  var rotationY: Float = 0.0
  var rotationZ: Float = 0.0
  var scale: Float = 1.0
  
  // MARK: - Initialization
  
  init(name: String, vertices: [Vertex], device: MTLDevice) {
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
  }
  
  // MARK: - Methods
  
  func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, projectionMatrix: Matrix4, clearColor: MTLClearColor?){

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor =
      MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    let commandBuffer = commandQueue.makeCommandBuffer()

    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder?.setRenderPipelineState(pipelineState)
    renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    
    // 1. Convert the convenience properties (like position
    // and rotation) into a model matrix
    let nodeModelMatrix = self.modelMatrix()
    
    // 2. Ask the device to create a buffer with
    // shared CPU/GPU memory
    let uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2, options: [])
    
    // 3. Get a raw pointer from buffer
    // (similar to `void *`) in Objective-C
    let bufferPointer = uniformBuffer?.contents()
    
    // 4. Copy the matrix data into the buffer
    memcpy(bufferPointer, nodeModelMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
    memcpy(bufferPointer! + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
    
    // 5. Pass `uniformBuffer` (with data copied) to the
    // vertex shader. This is similar to how we sent
    // the buffer to verex-specific data, expect
    // we use index 1 instead of 0
    renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
    
    renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,
      instanceCount: vertexCount/3)
    renderEncoder?.endEncoding()

    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
  
  func modelMatrix() -> Matrix4 {
    let matrix = Matrix4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }
  
}
