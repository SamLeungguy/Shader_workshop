#ifndef _MY_LIGHTING_HLSL_
#define _MY_LIGHTING_HLSL_

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct MyLight
{
    float3 color;
    float3 direction;
    float3 position;
};

Light GetDirectionalLight()
{
    Light light;
    light.color = 1.0;
    light.direction = float3(0.0, 1.0, 0.0);
    return light;
}


#endif