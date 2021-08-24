using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class LightProjection : MyPostProcessSimple
{
    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 60;
    }

    // Update is called once per frame
    void Update()
    {
        if (material)
        {
            //material.SetVector("_ScannerCenter", transform.position);
        }
    }
}
