implementing "../primitive.slang";
import math;

public struct Triangle : IRayCastable
{
    public float3[3] vertices;
    public float3[3] normals;
    public float2[3] uvs;
    public float3[3] colors;
    public uint materialId;

    /* Returns the average color of the triangle. */
    public float3 averageColor()
    {
        return (this.colors[0] + this.colors[1] + this.colors[2]) / 3.0;
    }

    private bool sameSideTest(float3 P, float3 a, float3 b, float3 c) {
        float3 cross1 = cross( c - b, P - b);
        float3 cross2 = cross( c - b, a - b);

        return dot(cross1, cross2) >= 0;
    }

    /**
     * Test ray-triangle intersection.
     * @param ray The ray to test against the triangle.
     * @return An Optional containing RayHitResult if the ray hits the triangle, otherwise an empty Optional.
     */
    public Optional<RayHitResult> hit(Ray ray)
    {
        float3 o = ray.origin;
        float3 direction = ray.direction;

        // find the normal
        float3 normal = cross(vertices[1] - vertices[0], vertices[2] - vertices[0]);
        //if (dot(normal, normal) < 1e-8) {
        //   return Optional<RayHitResult>();
        //}


        float c = dot(normal, vertices[0]);

        // check for division by zero
        if (abs(dot(normal, direction)) < 1e-6) {
            return Optional<RayHitResult>();
        }
        float t = (c - dot(normal, o)) / dot(normal, direction);

        if (t < ray.tRange[0] || t > ray.tRange[1]) {
            return Optional<RayHitResult>();
        } 

        float3 P = o + t * direction;

        if (this.sameSideTest(P, vertices[0], vertices[1], vertices[2]) &&
        this.sameSideTest(P, vertices[1], vertices[0], vertices[2]) && 
        this.sameSideTest(P, vertices[2], vertices[0], vertices[1])) {

            RayHitResult result;
            result.t = t;
            result.normal = normal;
            return result;

        }

        return Optional<RayHitResult>();

        
    }
}
