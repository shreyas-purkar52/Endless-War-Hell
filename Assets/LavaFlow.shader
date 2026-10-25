Shader "Custom/Animated Molten Lava"
{
    Properties
    {
        _BaseColor ("Crust Color", Color) = (0.12, 0.018, 0.006, 1)
        _LavaColor ("Molten Orange", Color) = (1, 0.12, 0.005, 1)
        _HotColor ("Hot Yellow", Color) = (1, 0.55, 0.04, 1)
        _CrackScale ("Crack Scale", Range(2, 35)) = 13
        _CrackWidth ("Crack Width", Range(0.015, 0.18)) = 0.075
        _FlowSpeed ("Flow Speed", Range(0, 2)) = 0.22
        _Distortion ("Flow Distortion", Range(0, 2)) = 0.45
        _Glow ("Emission Strength", Range(0, 8)) = 2.5
        _SurfaceVariation ("Surface Variation", Range(0.1, 3)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Cull Back
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float fogCoord : TEXCOORD1; };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _LavaColor;
                float4 _HotColor;
                float _CrackScale;
                float _CrackWidth;
                float _FlowSpeed;
                float _Distortion;
                float _Glow;
                float _SurfaceVariation;
            CBUFFER_END

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float noise2d(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash21(i);
                float b = hash21(i + float2(1,0));
                float c = hash21(i + float2(0,1));
                float d = hash21(i + float2(1,1));
                return lerp(lerp(a,b,f.x), lerp(c,d,f.x), f.y);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.fogCoord = ComputeFogFactor(OUT.positionHCS.z);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float t = _Time.y * _FlowSpeed;
                float2 uv = IN.uv * _CrackScale;
                float n1 = noise2d(uv * 0.65 + float2(t, -t * 0.55));
                float n2 = noise2d(uv * 1.35 + float2(-t * 0.8, t * 0.7));
                float n3 = noise2d(uv * 2.2 + float2(t * 0.45, t));
                float distortion = (n1 - 0.5) * _Distortion + (n2 - 0.5) * _Distortion * 0.5;
                float movingNoise = noise2d(uv + distortion + float2(t, -t * 0.72));
                float crustPattern = noise2d(uv * 0.8 + distortion + float2(-t * 0.2, t * 0.15));

                // Irregular glowing channels between dark crust plates.
                float ridge = abs(movingNoise - 0.5);
                float crack = 1.0 - smoothstep(_CrackWidth, _CrackWidth + 0.035, ridge);
                float hot = smoothstep(0.0, 0.22, n3) * crack;
                float variation = saturate((n1 * 0.55 + n2 * 0.3 + n3 * 0.15) * _SurfaceVariation);

                float3 crust = _BaseColor.rgb * (0.55 + variation * 0.8);
                float3 lava = lerp(_LavaColor.rgb, _HotColor.rgb, saturate(hot * 0.8 + n3 * crack * 0.35));
                float3 color = lerp(crust, lava, crack);
                float3 emission = lava * crack * _Glow;
                color += emission;
                color = MixFog(color, IN.fogCoord);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
