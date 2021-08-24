Shader "MyShader/MyLight"
{
    Properties
    { 
        [Enum(MyLight_Type)]
		_LightType("Light_Type", Int) = 0
        //-------------
        [Header(Point_Light Directional_Light)]
        _AmbientColor     ("AmbientColor", Color)         = (1,0,0,1)
        _DiffuseColor     ("DiffuseColor", Color)         = (1,0,0,1)
        _SpecularColor    ("SpecularColor", Color)        = (1,0,0,1)

       	_AmbientIntensity   ("AmbientIntensity",  range(0, 1))    = 0.2
       	_DiffuseIntensity   ("DiffuseIntensity",  range(0, 1))    = 0.6
       	_SpecularIntensity  ("SpecularIntensity", range(0, 1))    = 0.2

       	_SpecularShininess("SpecularShininess", range(0, 50))    = 5

        [Header(Attenuation)]
       	_Constant    ("Attenuation Constant",   range(0, 1))    = 1.0
       	_Linear      ("Attenuation Linear",     range(0, 1))    = 0.09
       	_Quadratic   ("Attenuation Quadratic",  range(0, 1))    = 0.032

        //----------------
        _BaseColor ("BaseColor", Color)         = (1,0,0,1)
        _MyTime         ("My time", Range(0,400))      = 0
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline"  }

        Pass
        {

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 vertexObjPos : TEXCOORD1;
                float3 w_pos        : TEXCOORD2;
                float3 w_normal     : TEXCOORD3;
            };

            struct MyLight
            {
                float4 color;
                float3 position;
                float3 direction;
            
                float innerCutoff;
                float outerCutoff;
            
                int type;
            };
             //MyLight _MyLights[MAX_LIGHTS_COUNT];


             #define MAX_LIGHTS_COUNT 10
             float4 _MyLights_colors[MAX_LIGHTS_COUNT];
             float3 _MyLights_positions[MAX_LIGHTS_COUNT];
             float3 _MyLights_directions[MAX_LIGHTS_COUNT];

             float _MyLights_innerCutoffs[MAX_LIGHTS_COUNT];
             float _MyLights_outerCutoffs[MAX_LIGHTS_COUNT];

             float _MyLights_types[MAX_LIGHTS_COUNT];

             int _LightCount;
            
             float4 _AmbientColor;  
             float4 _DiffuseColor; 
             float4 _SpecularColor; 
             
             float _AmbientIntensity; 
             float _DiffuseIntensity;
             float _SpecularIntensity;

             float _SpecularShininess;

             float _Constant;
             float _Linear;   
             float _Quadratic;

             float _MyTime;
             float4 _BaseColor;

             //-------old
             float4 _MyLightPos;
             float3 _MyLightDir;
             float _MySpotLightInnerCutOff;
             float _MySpotLightOuterCutOff;
             int _LightType;

             //---------
            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.vertexObjPos = i.positionOS;

                o.uv = i.uv;
                o.w_normal = TransformObjectToWorldNormal(i.normal);

                o.w_pos = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            float4 phongShading(float3 wpos, float3 normal, int i)
            {
                float3 L;
                float dist;
                float attenuation = 1.0f;

                int type = _MyLights_types[i];

                if (type == 1) // directional light
                {
                     L = normalize(-_MyLights_directions[i].xyz);                    
                }
                else    // point light / spot light
                {
                    L = normalize(_MyLights_positions[i].xyz - wpos);

                    float3 dist = distance(_MyLights_positions[i].xyz, wpos);
                    attenuation = 1.0f / (_Constant + _Linear * dist + _Quadratic * (dist * dist));
                }
                
                //float3 L = normalize(_MyLightPos.xyz - wpos);
                float3 N = normalize(normal);
                float3 V = normalize(wpos - _WorldSpaceCameraPos);
                float3 R = reflect(L, N);

                float3 ambient  = _AmbientColor * _AmbientIntensity;
                float3 diffuse  = _DiffuseColor * max(dot(L, N), 0) * _DiffuseIntensity;
                float3 specular = _SpecularColor * pow(max(dot(V, R), 0), _SpecularShininess) * _SpecularIntensity;

                if (type == 0)    // spot light
                {
                    float theta = dot(L, normalize(-_MyLights_directions[i]));
                    float epsilon = (_MyLights_innerCutoffs[i] - _MyLights_outerCutoffs[i]);
                    float intensity = clamp((theta - _MyLights_outerCutoffs[i]) / epsilon, 0.0, 1.0);

                    diffuse *= intensity;
                    specular *= intensity;
                }

                float4 color = 0;
                color.rgb += ambient;
                color.rgb += diffuse;
                color.rgb += specular;
                color *= _BaseColor;

                return color * _MyLights_colors[i] * attenuation;
            }


            half4 frag(Varyings i) : SV_Target
            {
                static const float epsilon = 0.0001f;

                 Light light = GetMainLight();
                 float3 lightDirWS = light.direction;

                uint pixelLightCount = GetAdditionalLightsCount();

                float3 w = i.w_pos.xyz;
                float3 n = i.w_normal;

                float4 result = 0;
                for(int i = 0; i < _LightCount; ++i)
                {
                    result += phongShading(w, n, i);
                }
                return result;
                return _MyLights_colors[2];
            }
            ENDHLSL
        }
    }
}