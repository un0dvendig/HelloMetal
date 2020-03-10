/// Copyright (c) 2018 Razeware LLC
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

import Metal
import UIKit

class ViewController: UIViewController {
  
  // MARK: - Properties
  
  // 1.1.
  var device: MTLDevice!
  
  // 1.2.
  var metalLayer: CAMetalLayer!
  
  // 1.3.
  var objectToDraw: Cube!
  
  // 1.6.
  var pipelineState: MTLRenderPipelineState!
  
  // 1.7.
  var commandQueue: MTLCommandQueue!
  
  // 2.1.
  var timer: CADisplayLink!
  
  var projectionMatrix: Matrix4!
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    createProjectionMatrix()
    
    // 1.1.
    createMTLDevice()
    // 1.2.
    createCAMetalLayer()
    // 1.3.
    createVertexBuffer()
    // 1.6.
    createRenderPipeline()
    //1.7.
    createCommandQueue()
    // 2.1.
    createDisplayLink()
    
  }

  // MARK: - Methods
  
  func render() {
    // 2.2. Creating a Render Pass Descriptor
    guard let drawable = metalLayer?.nextDrawable() else { return }
    objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, projectionMatrix: projectionMatrix, clearColor: nil)
  }
  
  @objc func gameloop() {
    autoreleasepool {
      self.render()
    }
  }
  
  // MARK: - Private methods
  
  // 1.1. Creating a MTLDevice
  private func createMTLDevice() {
    device = MTLCreateSystemDefaultDevice()
  }
  
  // 1.2. Creating a CAMetalLayer
  private func createCAMetalLayer() {
    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.frame = view.layer.frame
    view.layer.addSublayer(metalLayer)
  }
  
  // 1.3. Creating a Vertex Buffer
  private func createVertexBuffer() {
    objectToDraw = Cube(device: device)
    objectToDraw.positionX = 0.0
    objectToDraw.positionY = 0.0
    objectToDraw.positionZ = -2.0
    objectToDraw.rotationZ = Matrix4.degrees(toRad: 45)
    objectToDraw.scale = 0.5
  }
  
  // 1.6. Creagin a Render Pipeline
  private func createRenderPipeline() {
    let defaultLibrary = device.makeDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
  }
  
  // 1.7. Creating a Command Queue
  private func createCommandQueue() {
    commandQueue = device.makeCommandQueue()
  }
  
  // 2.1. Creating a Display Link
  private func createDisplayLink() {
    timer = CADisplayLink(target: self, selector: #selector(gameloop))
    timer.add(to: RunLoop.main, forMode: .default)
  }
  
  private func createProjectionMatrix() {
    projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
  }

}
