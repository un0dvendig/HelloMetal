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

protocol MetalViewControllerDelegate: class {
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

  // MARK: - Properties
  
  var commandQueue: MTLCommandQueue!
  var device: MTLDevice!
  var lastFrameTimestamp: CFTimeInterval = 0.0
  var metalLayer: CAMetalLayer!
  var pipelineState: MTLRenderPipelineState!
  var projectionMatrix: Matrix4!
  var timer: CADisplayLink!
  
  weak var metalViewControllerDelegate: MetalViewControllerDelegate?
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    createMTLDevice()
    createProjectionMatrix()
    createCAMetalLayer()
    createRenderPipeline()
    createCommandQueue()
    createDisplayLink()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if let window = view.window {
      let scale = window.screen.nativeScale
      let layerSize = view.bounds.size
      
      view.contentScaleFactor = scale
      metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
      metalLayer.drawableSize = CGSize(width: layerSize.width, height: layerSize.height)
    }
    
    let angleRad = Matrix4.degrees(toRad: 85.0)
    let aspectRatio = Float(self.view.bounds.size.width / self.view.bounds.size.height)
    projectionMatrix = Matrix4.makePerspectiveViewAngle(angleRad, aspectRatio: aspectRatio, nearZ: 0.01, farZ: 100.0)
  }
  
  // MARK: - Methods
  
  func render() {
    guard let drawable = metalLayer?.nextDrawable() else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }
  
  @objc
  func newFrame(displayLink: CADisplayLink) {
    if lastFrameTimestamp == 0.0 {
      lastFrameTimestamp = displayLink.timestamp
    }
    
    let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
    lastFrameTimestamp = displayLink.timestamp
    
    gameloop(timeSinceLastUpdate: elapsed)
  }
  
  func gameloop(timeSinceLastUpdate: CFTimeInterval) {
    self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate: timeSinceLastUpdate)
    
    autoreleasepool {
      self.render()
    }
  }
  
  // MARK: - Private methods
  
  private func createMTLDevice() {
    device = MTLCreateSystemDefaultDevice()
  }
  
  private func createProjectionMatrix() {
    let angleRadian = Matrix4.degrees(toRad: 85.0)
    let aspectRatio = Float(self.view.bounds.size.width / self.view.bounds.size.height)
    
    projectionMatrix = Matrix4.makePerspectiveViewAngle(angleRadian, aspectRatio: aspectRatio, nearZ: 0.01, farZ: 100.0)
  }
  
  private func createCAMetalLayer() {
    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    view.layer.addSublayer(metalLayer)
  }
  
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
  
  private func createCommandQueue() {
    commandQueue = device.makeCommandQueue()
  }
  
  private func createDisplayLink() {
    timer = CADisplayLink(target: self, selector: #selector(MetalViewController.newFrame(displayLink:)))
    timer.add(to: RunLoop.main, forMode: .default)
  }
  
}
