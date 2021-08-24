using UnityEngine;

public enum Week003_WorldScanner_UvMode
{
    OneDimension = 1,
    TwoDimension = 2,
};


[ExecuteInEditMode]
public class Week003_WorldScanner : MyPostProcessSimple
{
    public void Update()
    {
        if (material)
        {
            material.SetVector("_ScannerCenter", transform.position);
        }
    }
}
