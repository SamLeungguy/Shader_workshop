using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SplitDissolve : MonoBehaviour
{
    const int groupCount = 20;

    public MeshFilter myMeshFilter;
    public List<Vector3> splitVertices;
    public List<Vector3> splitNormals;
    public List<Vector2> splitUv;
    public List<int> splitTriangles;

    public List<Vector4> centers;
    public List<Vector2> newUvs;

    public Material mat;

    private void Awake()
    {
        myMeshFilter = GetComponent<MeshFilter>();
        splitVertices = new List<Vector3>();
        splitNormals = new List<Vector3>();
        splitUv = new List<Vector2>();
        splitTriangles = new List<int>();

        centers = new List<Vector4>();
        newUvs = new List<Vector2>();
    }

    private void Start()
    {
        Mesh mesh = GetComponent<MeshFilter>().mesh;


        for (int i = 0; i < mesh.triangles.Length;)
        {
            // vertices
            splitVertices.Add(mesh.vertices[mesh.triangles[i]    ]);
            splitVertices.Add(mesh.vertices[mesh.triangles[i + 1]]);
            splitVertices.Add(mesh.vertices[mesh.triangles[i + 2]]);

            // uv
            splitUv.Add(mesh.uv[mesh.triangles[i]]    );
            splitUv.Add(mesh.uv[mesh.triangles[i + 1]]);
            splitUv.Add(mesh.uv[mesh.triangles[i + 2]]);

            var newUv = (splitUv[i] + splitUv[i + 1] + splitUv[i + 2]) / 3;
            newUvs.Add(newUv);
            newUvs.Add(newUv);
            newUvs.Add(newUv);

            // normals
            Vector3 newNormal = Vector3.Cross(splitVertices[i + 1] - splitVertices[i], splitVertices[i + 2] - splitVertices[i]);

            splitNormals.Add(newNormal);
            splitNormals.Add(newNormal);
            splitNormals.Add(newNormal);

            // indices
            splitTriangles.Add(i);
            splitTriangles.Add(i + 1);
            splitTriangles.Add(i + 2);

            // centers
            Vector4 center = (splitVertices[i] + splitVertices[i + 1] + splitVertices[i + 2]) / 3;
            center.w = (float) Random.Range(0, groupCount) / groupCount;
            centers.Add(center);
            centers.Add(center);
            centers.Add(center);

            i += 3;
        }

        //Debug.Log("new vertices Length: " + splitVertices.Count);

        var newMesh = new Mesh();
        newMesh.name = "NewMesh";

        newMesh.vertices = splitVertices.ToArray();
        newMesh.uv = splitUv.ToArray();
        newMesh.normals = splitNormals.ToArray();
        newMesh.triangles = splitTriangles.ToArray();
        
        newMesh.SetUVs(1, centers);
        newMesh.SetUVs(2, newUvs);

        GetComponent<MeshFilter>().mesh = newMesh;

    }

    private void Update()
    {
        if (mat != null)
        {
            mat.SetMatrix("MyInverseTranspose_LocalToWorldMatrix", transform.localToWorldMatrix.inverse.transpose);
            Quaternion rotation = Quaternion.Euler(90, 45, 90);
            //Matrix4x4 m = Matrix4x4.Rotate(rotation);
            //mat.SetMatrix("MyRotateYMatrix", m);
        }
    }

    private void genMesh()
    {
        Mesh mesh = GetComponent<MeshFilter>().mesh;
        if (!mesh) return;

    }
}
