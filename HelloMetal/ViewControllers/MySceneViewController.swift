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
import simd

class MySceneViewController: MetalViewController {
  
  // MARK: - Properties
  
  var lastPanLocation: CGPoint!
  var objectToDraw: Cube!
  let panSensivity: Float = 5.0
  var worldModelMatrix: float4x4!
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWorldModelMatrix()
    createObjectToDraw()
    self.metalViewControllerDelegate = self
    setupGestures()
  }
  
  // MARK: - Private methods
  
  private func setupWorldModelMatrix() {
    worldModelMatrix = float4x4()
    worldModelMatrix.translate(0.0, y: 0.0, z: -4)
    let angleRadian = float4x4.degrees(toRad: 25)
    worldModelMatrix.rotateAroundX(angleRadian, y: 0.0, z: 0.0)
  }
  
  private func createObjectToDraw() {
    objectToDraw = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader)
  }
  
  private func setupGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
    self.view.addGestureRecognizer(pan)
  }
  
  @objc
  private func pan(_ panGesture: UIPanGestureRecognizer) {
    if panGesture.state == .changed {
      let pointInView = panGesture.location(in: self.view)
      
      let xDelta = Float((lastPanLocation.x - pointInView.x) / self.view.bounds.width) * panSensivity
      let yDelta = Float((lastPanLocation.y - pointInView.y) / self.view.bounds.height) * panSensivity
      
      objectToDraw.rotationY -= xDelta
      objectToDraw.rotationX -= yDelta
      
      lastPanLocation = pointInView
    } else if panGesture.state == .began {
      lastPanLocation = panGesture.location(in: self.view)
    }
  }
}

// MARK: - MetalViewControllerDelegate

extension MySceneViewController: MetalViewControllerDelegate {
  func renderObjects(drawable: CAMetalDrawable) {
    objectToDraw.render(commandQueue: commandQueue,
                        pipelineState: pipelineState,
                        drawable: drawable,
                        parentModelViewMatrix: worldModelMatrix,
                        projectionMatrix: projectionMatrix,
                        clearColor: nil)
  }
  
  func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
    objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
  }
}
