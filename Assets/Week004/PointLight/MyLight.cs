using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public enum MyLight_Type
{
    Spot_Light = 0,
    Directional_Light = 1,
    Point_Light = 2,
};

[ExecuteInEditMode]
public class MyLight : MonoBehaviour
{
    public Light[] lights = new Light[10];
    private int currentLight = 0;

    public float MySpotLightInnerCutOff = 12.5f;
    public float MySpotLightOuterCutOff = 12.5f;

    public List<Vector4> _MyLights_colors      = new List<Vector4>();
    public List<Vector4> _MyLights_positions   = new List<Vector4>();
    public List<Vector4> _MyLights_directions  = new List<Vector4>();
    public List<float> _MyLights_types         = new List<float>();
    public List<float> _MyLights_innnerCutoffs = new List<float>();
    public List<float> _MyLights_outerCutoffs  = new List<float>();


    private void LateUpdate()
    {
        Application.targetFrameRate = 60;
        //var p = gameObject.GetComponent<Light>();
        //if (!p)
        //    return;

        //MySpotLightInnerCutOff = Mathf.Clamp(MySpotLightInnerCutOff, 0, 90);
        //MySpotLightOuterCutOff = Mathf.Clamp(MySpotLightOuterCutOff, MySpotLightInnerCutOff, 90);

        //Shader.SetGlobalVector("_MyLightPos", p.transform.position);
        //Shader.SetGlobalVector("_MyLightDir", p.transform.forward);
        //Shader.SetGlobalFloat("_MySpotLightInnerCutOff", Mathf.Cos(Mathf.Deg2Rad * MySpotLightInnerCutOff));
        //Shader.SetGlobalFloat("_MySpotLightOuterCutOff", Mathf.Cos(Mathf.Deg2Rad * MySpotLightOuterCutOff));

        //Debug.Log("Hello");

        _MyLights_colors.Clear();
        _MyLights_positions.Clear();
        _MyLights_directions.Clear();
        _MyLights_types.Clear();
        _MyLights_innnerCutoffs.Clear();
        _MyLights_outerCutoffs.Clear();

        setupLights();

        Shader.SetGlobalVectorArray("_MyLights_colors", _MyLights_colors);
        Shader.SetGlobalVectorArray("_MyLights_positions", _MyLights_positions);
        Shader.SetGlobalVectorArray("_MyLights_directions", _MyLights_directions);
        Shader.SetGlobalFloatArray("_MyLights_types", _MyLights_types);
        Shader.SetGlobalFloatArray("_MyLights_innerCutoffs", _MyLights_innnerCutoffs);
        Shader.SetGlobalFloatArray("_MyLights_outerCutoffs", _MyLights_outerCutoffs);

        Shader.SetGlobalInt("_LightCount", currentLight);
        //Debug.Log(currentLight);
        currentLight = 0;
    }

    void setupLights()
    {
        for (int i = 0; i < lights.Length; i++)
        {
            var light = lights[i];
            if (light)
            {
                LightType type = light.type;

                _MyLights_colors.Add(light.color);
                _MyLights_positions.Add(light.transform.position);
                _MyLights_directions.Add(light.transform.forward);
                _MyLights_types.Add((float)type);
                if (type == LightType.Spot)
                {
                    //Debug.Log("Spot");
                    Debug.Log(light.innerSpotAngle);
                    _MyLights_innnerCutoffs.Add(Mathf.Cos(Mathf.Deg2Rad * light.innerSpotAngle));
                    _MyLights_outerCutoffs.Add(Mathf.Cos(Mathf.Deg2Rad * (light.spotAngle)));
                }
                else
                {
                    _MyLights_innnerCutoffs.Add(0);
                    _MyLights_outerCutoffs.Add(0);
                }
                currentLight++;
            }

            //if (light)
            //{
            //    LightType type = light.type;

            //    Shader.SetGlobalVector("_MyLights_color[" + i.ToString() + "]",     light.color);
            //    Shader.SetGlobalVector("_MyLights_position[" + i.ToString() + "]",  light.transform.position);
            //    Shader.SetGlobalVector("_MyLights_direction[" + i.ToString() + "]", -light.transform.up);

            //    Shader.SetGlobalInt("_MyLights_type[" + i.ToString() + "]", (int)type);

            //    if (type == LightType.Spot)
            //    {
            //        Shader.SetGlobalFloat("_MyLights[" + i.ToString() + "].innnerCutoff", Mathf.Cos(Mathf.Deg2Rad * light.innerSpotAngle));
            //        Shader.SetGlobalFloat("_MyLights[" + i.ToString() + "].outerCutoff", Mathf.Cos(Mathf.Deg2Rad * (light.innerSpotAngle + 12.5f)));
            //    }
            //    currentLight++;
            //}
        }
    }
}
