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

class MySceneViewController: MetalViewController {
  
  // MARK: - Properties
  
  var worldModelMatrix: Matrix4!
  var objectToDraw: Cube!
  
  // MARK: - View life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWorldModelMatrix()
    createObjectToDraw()
    self.metalViewControllerDelegate = self
  }
  
  // MARK: - Private methods
  private func setupWorldModelMatrix() {
    worldModelMatrix = Matrix4()
    worldModelMatrix.translate(0.0, y: 0.0, z: -4)
    let angleRadian = Matrix4.degrees(toRad: 25)
    worldModelMatrix.rotateAroundX(angleRadian, y: 0.0, z: 0.0)
  }
  
  private func createObjectToDraw() {
    objectToDraw = Cube(device: device)
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
