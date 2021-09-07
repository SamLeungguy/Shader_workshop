using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyNormalMap : MonoBehaviour
{
    public Transform my_light;
    public Material mat;
    
    // Update is called once per frame
    void Update()
    {
        if (mat)
        {
            mat.SetVector("light_pos", new Vector4(my_light.position.x, my_light.position.y, my_light.position.z, 1.0f));
        }
    }
}
