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

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  packed_float3 position;
  packed_float4 color;
  packed_float2 texCoord;
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float2 texCoord;
};

struct Uniforms {
  float4x4 modelMatrix;
  float4x4 projectionMatrix;
};

// 1.4. Creating a Vertex Shader
vertex VertexOut basic_vertex(
  const device VertexIn* vertex_array [[ buffer(0) ]],
  const device Uniforms& uniforms [[ buffer(1) ]],
  unsigned int vid [[ vertex_id ]]) {
  
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;
  
  VertexIn VertexIn = vertex_array[vid];
  
  VertexOut VertexOut;
  VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position, 1);
  VertexOut.color = VertexIn.color;
  VertexOut.texCoord = VertexIn.texCoord;
  
  return VertexOut;
}

// 1.5. Creating a Fragment Shader
fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
texture2d<float> tex2D [[ texture(0) ]], sampler sampler2D [[ sampler(0) ]]) {
  float4 color = tex2D.sample(sampler2D, interpolated.texCoord);
  
//  Uncomment to colorize the texture
//  float4 color = interpolated.color * tex2D.sample(sampler2D, interpolated.texCoord);
  return color;
}
