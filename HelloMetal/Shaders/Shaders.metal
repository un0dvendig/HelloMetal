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
  packed_float3 normal;
};

struct VertexOut {
  float4 position [[ position ]];
  float3 fragmentPosition;
  float4 color;
  float2 texCoord;
  float3 normal;
};

struct Light {
  packed_float3 color; // 0 - 2
  float ambientIntensity; // 3
  packed_float3 direction; // 4 - 6
  float diffuseIntensity; // 7
  float shininess; // 8
  float specularIntensity; // 9
  
  /*
   -------------------------
   |0 1 2 3|4 5 6 7|8 9    |
   |       |       |       |
   | chunk0| chunk1| chunk2|
   -------------------------
   */
};

struct Uniforms {
  float4x4 modelMatrix;
  float4x4 projectionMatrix;
  Light light;
};



// 1.4. Creating a Vertex Shader
vertex VertexOut basic_vertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms& uniforms [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
  
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;
  
  VertexIn VertexIn = vertex_array[vid];
  
  VertexOut VertexOut;
  VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position, 1);
  VertexOut.fragmentPosition = (mv_Matrix * float4(VertexIn.position, 1)).xyz;
  VertexOut.color = VertexIn.color;
  VertexOut.texCoord = VertexIn.texCoord;
  VertexOut.normal = (mv_Matrix * float4(VertexIn.normal, 0.0)).xyz;
  
  return VertexOut;
}

// 1.5. Creating a Fragment Shader
fragment float4 basic_fragment(VertexOut interpolated [[ stage_in ]],
                               const device Uniforms& uniforms [[ buffer(1) ]],
                               texture2d<float> tex2D [[ texture(0) ]],
                               sampler sampler2D [[ sampler(0) ]]) {

  // Ambient
  Light light = uniforms.light;
  float4 ambientColor = float4(light.color * light.ambientIntensity, 1);
  
  // Diffuse
  float diffuseFactor = max(0.0, dot(interpolated.normal, light.direction));
  float4 diffuseColor = float4(light.color * light.diffuseIntensity * diffuseFactor, 1.0);
  
  // Specular
  float3 eye = normalize(interpolated.fragmentPosition);
  float3 reflection = reflect(light.direction, interpolated.normal);
  float specularFactor = pow(max(0.0, dot(reflection, eye)), light.shininess);
  float4 specularColor = float4(light.color * light.specularIntensity * specularFactor, 1.0);
  
  float4 color = tex2D.sample(sampler2D, interpolated.texCoord);
//  Uncomment to colorize the texture
//  float4 color = interpolated.color * tex2D.sample(sampler2D, interpolated.texCoord);
  
  return color * (ambientColor + diffuseColor + specularColor);
}
