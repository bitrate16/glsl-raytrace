// Shader originally developer to work in shadertoy.com

#define RAY_DIRECTION_LENGTH 0.8
#define GI_LUMINE 0.1
#define GI_COLOR  vec4(1.0, 1.0, 1.0, 1.0)
#define MAX_RAY_DEPTH 4
#define USE_SHADOWS

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Hit {
    float dist;
    vec3 location;
    vec3 normal;
};

// enum HitType {
#define HIT_NONE   0
#define HIT_SPHERE 1
#define HIT_PLANE  2
// };

struct Material {     
    vec4 color;
    float lumine;
    float diffuse;
};

struct PointLight {
	vec3 location;
	Material material;
};

struct Sphere {
    vec3 center;
    float radius;
    Material material;
};
    
struct Plane {
    vec3 location;
	vec3 normal;
    Material material;
};

// Raymarch functions
Hit plane(Ray r, Plane p) {
    float ndd = dot(p.normal, r.direction);
	Hit h;
	h.dist     = -1.0;
	h.location = vec3(0.0);
	h.normal   = vec3(0.0);
	
	
	if (abs(ndd) < 10e-8)
		return h;
	
	h.dist = dot(p.normal, p.location - r.origin) / ndd;
	
	if (h.dist < 10e-8)
		return h;
	
	h.location = r.origin + r.direction * h.dist;
	h.normal   = p.normal;
	
	return h;
}

Hit sphere(Ray r, Sphere s) {
    vec3 oc = r.origin - s.center;
    float a = length(r.direction);
    float b = 2.0 * dot(oc, r.direction);
    float c = dot(oc, oc) - s.radius * s.radius;
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        Hit hit;
        hit.dist = -1.0;
        hit.location = vec3(0.0);
        hit.normal = vec3(0.0);
        return hit;
    } else {
        Hit hit;
        hit.dist = (-b - sqrt(discriminant)) / (2.0 * a);
        hit.location = r.origin + hit.dist * r.direction;
        hit.normal = normalize(hit.location - s.center);
        return hit;
    }
}

// Math utilities
float cos_between(vec3 a, vec3 b) {
	return dot(a, b) / (length(a) * length(b));
}	

// Scene
const int lightCount  = 1;
PointLight lights[lightCount];
const int sphereCount = 2;
Sphere    spheres[sphereCount];
const int planeCount  = 5;
Plane      planes[planeCount];

// Scene initialization goes here
void scene() {
	// Light
	lights[0].location = vec3((iMouse.xy - iResolution.xy / 2.0) / vec2(max(iResolution.x, iResolution.y)), 0.8);
	lights[0].material.lumine = 0.9;
	lights[0].material.color  = vec4(1.0, 1.0, 1.0, 1.0);
    
	// Sphere
	spheres[0].center = vec3(0.2 * sin(iTime), 0.2 * cos(iTime), 1.0);
    spheres[0].radius = 0.1;
	spheres[0].material.color   = vec4(1.0, 0.0, 0.0, 1.0);
	spheres[0].material.diffuse = 1.0;
	spheres[0].material.lumine  = 0.0;
    
	spheres[1].center = vec3(0.5 * sin(iTime + 0.3), 0.5 * cos(iTime + 0.3), 1.5);
    spheres[1].radius = 0.05;
	spheres[1].material.color   = vec4(0.0, 1.0, 0.0, 1.0);
	spheres[1].material.diffuse = 1.0;
	spheres[1].material.lumine  = 0.0;
	
	// Plane
	planes[0].location = vec3(0.0, -1.0, 0.0);
    planes[0].normal   = vec3(0.0, 1.0, 0.0);
	planes[0].material.color   = vec4(1.0, 1.0, 1.0, 1.0);
	planes[0].material.diffuse = 1.0;
	planes[0].material.lumine  = 0.0;
	
	planes[1].location = vec3(0.0, 1.0, 0.0);
    planes[1].normal   = vec3(0.0, -1.0, 0.0);
	planes[1].material.color   = vec4(1.0, 1.0, 1.0, 1.0);
	planes[1].material.diffuse = 1.0;
	planes[1].material.lumine  = 0.0;
	
	planes[2].location = vec3(0.0, 0.0, 4.0);
    planes[2].normal   = vec3(0.0, 0.0, -1.0);
	planes[2].material.color   = vec4(1.0, 1.0, 1.0, 1.0);
	planes[2].material.diffuse = 1.0;
	planes[2].material.lumine  = 0.0;
	
	planes[3].location = vec3(-1.0, 0.0, 0.0);
    planes[3].normal   = vec3(1.0, 0.0, 0.0);
	planes[3].material.color   = vec4(1.0, 0.0, 0.0, 1.0);
	planes[3].material.diffuse = 0.8;
	planes[3].material.lumine  = 0.0;
	
	planes[4].location = vec3(1.0, 0.0, 0.0);
    planes[4].normal   = vec3(-1.0, 0.0, 0.0);
	planes[4].material.color   = vec4(0.0, 0.0, 1.0, 1.0);
	planes[4].material.diffuse = 0.7;
	planes[4].material.lumine  = 0.0;
}

void traceClosest(in Ray r, out int hitType, out Hit closest, out int closestId) {
	// Closest hit ID
	closestId = -1;
	// Closest hit manifold
    closest.dist     = -1.0;
    closest.location = vec3(0.0);
    closest.normal   = vec3(0.0);
	// Type of resulting hit
	hitType = HIT_NONE;
	
	// Trace spheres
    for (int sphereId = 0; sphereId < sphereCount; ++sphereId) {
        Hit h = sphere(r, spheres[sphereId]);
        if (h.dist >= 10e-8 && (h.dist < closest.dist || closest.dist < 10e-8)) {
            closest = h;
            closestId = sphereId;
			hitType = HIT_SPHERE;
        }
    }
	
	// Trace planes
    for (int planeId = 0; planeId < planeCount; ++planeId) {
        Hit h = plane(r, planes[planeId]);
        if (h.dist >= 10e-8 && (h.dist < closest.dist || closest.dist < 10e-8)) {
            closest = h;
            closestId = planeId;
			hitType = HIT_PLANE;
        }
    }
}

// Ray trace function
vec4 trace(in Ray r, int depth) {
	// Limit depth of the ray
	if (depth >= MAX_RAY_DEPTH)
		return vec4(0.0);
	
	// Output color
	vec4 color = vec4(0.0);
	
	// H I T
	
    int closestId;
	// Closest hit manifold
    Hit closestHit;
	// Type of resulting hit
	int hitType;
	
	traceClosest(r, hitType, closestHit, closestId);
    
	// Check distance match	
    if (closestHit.dist >= 0.0) {
		// Lighting from global illumination
		if (hitType == HIT_SPHERE)
			color += GI_LUMINE * GI_COLOR * spheres[closestId].material.color;
		else if (hitType == HIT_PLANE)
			color += GI_LUMINE * GI_COLOR * planes[closestId].material.color;
		
		// Lighting from light objects
        for (int lightId = 0; lightId < lightCount; ++lightId) {
#ifdef USE_SHADOWS
			Ray shadowRay;
			shadowRay.direction = normalize(lights[lightId].location - closestHit.location);
			shadowRay.origin    = closestHit.location + shadowRay.direction * 10e-4;
			
			int closestShadowId;
			// Closest hit manifold
			Hit closestShadowHit;
			// Type of resulting hit
			int shadowHitType;
			
			traceClosest(shadowRay, shadowHitType, closestShadowHit, closestShadowId);
			
			if (closestShadowId != -1 && closestShadowHit.dist < distance(closestHit.location, lights[lightId].location))
				continue;
#endif
			if (hitType == HIT_SPHERE) {
				color += spheres[closestId].material.color 
                         * spheres[closestId].material.color 
                         * lights[lightId].material.color 
                         * lights[lightId].material.lumine
                         * (max(cos_between(lights[lightId].location - closestHit.location, closestHit.normal), 0.0)
                                 + max(cos_between(r.direction, closestHit.normal), 0.0)); // Spot
			} else if (hitType == HIT_PLANE) {
				color += planes[closestId].material.color 
                         * planes[closestId].material.color 
                         * lights[lightId].material.color 
                         * lights[lightId].material.lumine
                         * (max(cos_between(lights[lightId].location - closestHit.location, closestHit.normal), 0.0)
                            + max(cos_between(r.direction, closestHit.normal), 0.0)); // Spot
			}
        } 
    }
	
	return color;
}
	
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	fragColor = vec4(0.0);
    fragCoord -= iResolution.xy / 2.0;
    
	// Ray
    Ray r;
	r.origin    = vec3(0.0);
	r.direction = normalize(vec3(fragCoord.xy, RAY_DIRECTION_LENGTH) / vec3(max(iResolution.x, iResolution.y), max(iResolution.x, iResolution.y), 1.0));
    
	// S C E N E
	
    scene();
	
	// H I T
	
    fragColor = trace(r, 0);
}

