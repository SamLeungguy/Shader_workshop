using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SplitDissolve : MonoBehaviour
{
    public MeshFilter myMeshFilter;
    public List<Vector3> splitVertices;
    public List<Vector3> splitNormals;
    public List<Vector2> splitUv;
    public List<int> splitTriangles;

    public List<Vector3> centers;

    public Material mat;

    //public List<Vector3> nextVertices1;
    //public List<Vector3> nextVertices2;
    //public List<Vector3> testVertices;
    //public List<Vector3> testNormals;
    //public List<Vector2> testUv;

    private void Awake()
    {
        myMeshFilter = GetComponent<MeshFilter>();
        splitVertices = new List<Vector3>();
        splitNormals = new List<Vector3>();
        splitUv = new List<Vector2>();
        splitTriangles = new List<int>();

        centers = new List<Vector3>();


        //nextVertices1 = new List<Vector3>();
        //nextVertices2 = new List<Vector3>();

        //testVertices = new List<Vector3>();
        //testNormals = new List<Vector3>();
        //testUv = new List<Vector2>();
    }

    private void Start()
    {
        //gameObject.AddComponent<MeshFilter>();
        //gameObject.AddComponent<MeshRenderer>();
        Mesh mesh = GetComponent<MeshFilter>().mesh;

        //Debug.Log("triangles Length: " + mesh.triangles.Length);
        //Debug.Log("vertices Length: " + mesh.vertices.Length);
        //Debug.Log("uv Length: " + mesh.uv.Length);
        //Debug.Log("normal Length: " + mesh.normals.Length);

        //testVertices.AddRange(mesh.vertices);
        //testNormals.AddRange(mesh.normals);
        //testUv.AddRange(mesh.uv);

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
            Vector3 center = (splitVertices[i] + splitVertices[i + 1] + splitVertices[i + 2]) / 3;
            centers.Add(center);
            centers.Add(center);
            centers.Add(center);

            // other vertices
            //// if it is 0, then need 1, 2
            //nextVertices1.Add(mesh.vertices[mesh.triangles[i + 1]]);
            //nextVertices2.Add(mesh.vertices[mesh.triangles[i + 2]]);
            //
            //// if it is 1, then need 0, 2
            //nextVertices1.Add(mesh.vertices[mesh.triangles[i    ]]);
            //nextVertices2.Add(mesh.vertices[mesh.triangles[i + 2]]);
            //
            //// if it is 2, then need 0, 1
            //nextVertices1.Add(mesh.vertices[mesh.triangles[i    ]]);
            //nextVertices2.Add(mesh.vertices[mesh.triangles[i + 1]]);

            i += 3;
        }

        //Debug.Log("new vertices Length: " + splitVertices.Count);

        mesh.vertices = splitVertices.ToArray();
        mesh.uv = splitUv.ToArray();
        mesh.normals = splitNormals.ToArray();
        mesh.triangles = splitTriangles.ToArray();
        
        mesh.SetUVs(1, centers);

        // next other vertices
        //mesh.SetUVs(1, nextVertices1);
        //mesh.SetUVs(2, nextVertices2);
    }

    private void Update()
    {
        if (mat != null)
        {
            mat.SetMatrix("MyInverseTranspose_LocalToWorldMatrix", transform.localToWorldMatrix.inverse.transpose);
        }
    }
}
