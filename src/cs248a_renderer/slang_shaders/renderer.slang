import math;
import texture;
import material;
import model;
import primitive;

public struct RendererUniform
{
    // Camera parameters.
    public Camera camera;
    // Ambient color, used when no ray hits a primitive
    public float4 ambientColor;
    // Ray samples per pixel
    public uint sqrtSpp;
    // Primitives.
    public StructuredBuffer<Triangle> triangleBuf;
    public uint triangleCount;
    public SharedTexture3DBuffer<float4> volumeTexBuf;
    public StructuredBuffer<Volume> volumeBuf;
    public uint volumeCount;
    public SDFBuffer sdfBuf;
    // Acceleration structure.
    public bool useBVH;
    public BVH<Triangle> bvh;

    public bool renderDepth;
    public bool renderNormal;
}

static uint MAX_STEPS = 100;
static float EPSILON = 1e-6;

/**
 * Sample the scene at the given uv coordinate.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @return The color of the ray sample at the given uv coordinate.
 */

public Optional<RayHitResult> rayTriangles(Ray ray, StructuredBuffer<Triangle> triangles, uint triangleCount)
{

    // find the normal of the plane defined by the triangle
    Optional<RayHitResult> result;
    float t_smallest = float.maxValue;
    for (int i = 0; i < triangleCount; i++)
    {
        Optional<RayHitResult> hitResult = triangles[i].hit(ray);
        if (hitResult.hasValue) {
            if (hitResult.value.t < t_smallest)
            {
                t_smallest = hitResult.value.t;
                result = hitResult;
            }
        }
    }

    if (t_smallest == float.maxValue)
    {
        return Optional<RayHitResult>();
    }

    return result;

}

public float4 sample(float2 uv, RendererUniform uniforms)
{
    // We generate a camera ray for the given uv coordinate.
    // You need to implement the `generateRay` function in `Camera` struct in `src/cs248a_renderer/slang_shaders/model/camera.slang`
    Ray ray = uniforms.camera.generateRay(uv);


    
    Optional<RayHitResult> ans = rayTriangles(ray, uniforms.triangleBuf, uniforms.triangleCount);

    if (ans.hasValue == false) {
        return float4(0.0, 0.0, 0.0, 1.0);

    }

    RayHitResult result = ans.value;

    

    if (uniforms.renderDepth)
    {
        // Map depth to [0, 1] range for visualization
        return float4(float3(result.t), 1.0);
    }

    if (uniforms.renderNormal)
    {
        // Map normal from [-1, 1] to [0, 1] range for visualization
        return float4(result.normal * 0.5 + 0.5, 1.0);
    }

    // Once you have the intersection result, use the following code to shade (calculate color) for the ray.
    // The shading function needs the camera ray and the intersection result.
    SimpleMaterial simpleMaterial;
    float3 color = simpleMaterial.shade(ray, result);
    return float4(color, 1.0);
}

/**
 * The entry point of the renderer.
 * @param tid The 2D coordinate of the current thread. Ranges from (0, 0) to (canvasSize.x - 1, canvasSize.y - 1).
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @return The color of the pixel at the given thread coordinate.
 */
public float4 render(uint2 tid, RendererUniform uniforms)
{
    // TODO: Student implementation starts here.

    // Basic version: no supersampling.
    float2 uv = (float2(tid) + 0.5) / float2(uniforms.camera.canvasSize);
    float4 final_color = float4(0.0, 0.0, 0.0, 0.0);
    for (int i = 0; i < uniforms.sqrtSpp; i++)
    {
        for (int j = 0; j < uniforms.sqrtSpp; j++) {
            uv = (float2(tid) + float2(float(i) + 0.5, float(j) + 0.5) / uniforms.sqrtSpp) / float2(uniforms.camera.canvasSize);

            final_color += sample(uv, uniforms);
        }
    }
    return final_color / pow(uniforms.sqrtSpp, 2);

    // TODO: Student implementation ends here.
}
