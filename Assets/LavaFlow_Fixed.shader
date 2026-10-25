Shader "Custom/Animated Molten Lava Fixed"
{
    Properties
    {
        _BaseColor ("Crust Color", Color) = (0.055, 0.012, 0.004, 1)
        _LavaColor ("Molten Orange", Color) = (1, 0.075, 0.002, 1)
        _HotColor ("Hot Yellow", Color) = (1, 0.38, 0.025, 1)
        _CrackScale ("Crack Scale", Range(2, 35)) = 9
        _CrackWidth ("Crack Width", Range(0.015, 0.18)) = 0.055
        _FlowSpeed ("Flow Speed", Range(0, 2)) = 0.18
        _Distortion ("Flow Distortion", Range(0, 2)) = 0.35
        _Glow ("Emission Strength", Range(0, 8)) = 2.2
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

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionHCS : SV_POSITION; float3 positionOS : TEXCOORD0; float fogCoord : TEXCOORD1; };

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

            // Voronoi cell-edge distance creates distinct, irregular crust plates.
            float cellEdge(float2 p)
            {
                float2 cell = floor(p);
                float2 local = frac(p);
                float nearest = 10.0;
                float second = 10.0;
                [unroll]
                for (int y = -1; y <= 1; y++)
                {
                    [unroll]
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 g = float2((float)x, (float)y);
                        float2 offset = g + float2(hash21(cell + g), hash21(cell + g + 17.3)) - local;
                        float d = length(offset);
                        if (d < nearest) { second = nearest; nearest = d; }
                        else if (d < second) { second = d; }
                    }
                }
                return second - nearest;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // Use mesh positions rather than UVs because the supplied mesh has no usable UV coordinates.
                OUT.positionOS = IN.positionOS.xyz;
                OUT.fogCoord = ComputeFogFactor(OUT.positionHCS.z);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float t = _Time.y * _FlowSpeed;
                float2 p = IN.positionOS.xz * (_CrackScale * 0.22);
                float n1 = noise2d(p * 0.42 + float2(t * 0.7, -t * 0.45));
                float n2 = noise2d(p * 0.8 + float2(-t * 0.55, t * 0.6));
                float2 flow = float2(n1 - 0.5, n2 - 0.5) * _Distortion;
                float edge = cellEdge(p + flow);
                float width = max(_CrackWidth, 0.015);
                float crack = 1.0 - smoothstep(width, width + 0.035, edge);
                float hotNoise = noise2d(p * 1.8 + float2(t, -t * 0.8));
                float hot = smoothstep(0.42, 0.82, hotNoise);
                float variation = saturate((n1 * 0.6 + n2 * 0.4) * _SurfaceVariation);

                float3 crust = _BaseColor.rgb * (0.45 + variation * 0.8);
                float3 molten = lerp(_LavaColor.rgb, _HotColor.rgb, hot * 0.65);
                float3 color = lerp(crust, molten, crack);
                color += molten * crack * _Glow;
                color = MixFog(color, IN.fogCoord);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
