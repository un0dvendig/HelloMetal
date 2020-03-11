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
import MetalKit
import simd
import UIKit

protocol MetalViewControllerDelegate: class {
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

  // MARK: - Properties
  
  var commandQueue: MTLCommandQueue!
  var device: MTLDevice!
  var pipelineState: MTLRenderPipelineState!
  var projectionMatrix: float4x4!
  var textureLoader: MTKTextureLoader! = nil
  weak var metalViewControllerDelegate: MetalViewControllerDelegate?
  
  // MARK: - Outlets
  
  @IBOutlet weak var mtkView: MTKView! {
    didSet {
      mtkView.delegate = self
      mtkView.preferredFramesPerSecond = 60
      mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
  }
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    createMTLDevice()
    createTextureLoader()
    createProjectionMatrix()
    createRenderPipeline()
    createCommandQueue()
  }
  
  // MARK: - Private methods
  
  private func render(_ drawable: CAMetalDrawable?) {
    guard let drawable = drawable else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }
  
  private func createMTLDevice() {
    device = MTLCreateSystemDefaultDevice()
    mtkView.device = device
  }
  
  private func createTextureLoader() {
    textureLoader = MTKTextureLoader(device: device)
  }
  
  private func createProjectionMatrix() {
    let angleRadian = float4x4.degrees(toRad: 85.0)
    let aspectRatio = Float(self.view.bounds.size.width / self.view.bounds.size.height)
    
    projectionMatrix = float4x4.makePerspectiveViewAngle(angleRadian, aspectRatio: aspectRatio, nearZ: 0.01, farZ: 100.0)
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
  
}

// MARK: - MTKViewDelegate methods

extension MetalViewController: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    let angleRadian = float4x4.degrees(toRad: 85.0)
    let aspectRadio = Float(self.view.bounds.size.width / self.view.bounds.size.height)
    projectionMatrix = float4x4.makePerspectiveViewAngle(angleRadian, aspectRatio: aspectRadio, nearZ: 0.01, farZ: 100.0)
  }
  
  func draw(in view: MTKView) {
    render(view.currentDrawable)
  }
}
