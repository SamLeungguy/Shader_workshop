using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MyTrail : MonoBehaviour
{
    MeshFilter myMeshFilter;
    MeshRenderer myMeshRenderer;

    Material mat;
    public List<Vector3> posArray;
    public int currentIndex = 0;

    public GameObject myTrail;

    // trail param
    public float trailWidth = 0.1f;
    public float duration= 4f;
    //public float trailLength = 1f;

    // update
    float lastUpdateTime = Mathf.Infinity;
    public float updateTime = 1.0f;

    // 
    //Vector3 lastPos;
    Vector3 lastV0;
    Vector3 lastV2;

    // mesh vertex
    private List<Vector3> splitVertices;
    private List<Vector3> splitNormals;
    private List<Vector2> splitUv;
    private List<int>     splitTriangles;

    public List<float> meshLifeTime;

    private float m_trailWidth;

    //---------------
    public bool isRest = false;

    private void Awake()
    {
        posArray = new List<Vector3>();

        splitVertices = new List<Vector3>();
        splitNormals = new List<Vector3>();
        splitUv = new List<Vector2>();
        splitTriangles = new List<int>();

        meshLifeTime = new List<float>();

        m_trailWidth = trailWidth / 2;
        //lastPos = Vector3.right;

    }

    // Start is called before the first frame update
    void Start()
    {
        myTrail = new GameObject();
        myTrail.name = "myTrail";
        myTrail.AddComponent<MeshFilter>();
        myTrail.AddComponent<MeshRenderer>();

        myMeshFilter = myTrail.GetComponent<MeshFilter>();
        myMeshRenderer = myTrail.GetComponent<MeshRenderer>();
        posArray.Add((transform.position));
        myMeshRenderer.material = GetComponent<MeshRenderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        drawTrail();
        trimTrail();

        lastUpdateTime += Time.deltaTime;
        for (int i = 0; i < meshLifeTime.Count; i++)
        {
            meshLifeTime[i] += Time.deltaTime;
        }
    }

    void drawTrail()
    {
        if (lastUpdateTime >= updateTime)
        {
            // first time
            if (posArray.Count == 2)
            {
                Vector3 p0_ = posArray[posArray.Count - 1];
                Vector3 p1_ = posArray[posArray.Count - 2];

                float dist_ = Vector3.Distance(p0_, p1_);
                Vector3 dir_ = (p0_ - p1_).normalized;
                Vector3 l = Vector3.Cross(dir_, Vector3.up);
                Vector3 v0_, v1_, v2_, v3_;

                v1_ = p0_ - dir_ * m_trailWidth;
                v3_ = p0_ + dir_ * m_trailWidth;

                v0_ = v1_ + dist_ * dir_;
                v2_ = v3_ + dist_ * dir_;

                lastV0 = v0_;
                lastV2 = v2_;
            }

            // avoid the v0 == v1 and v2 == v3 

            if (Mathf.Equals(posArray[posArray.Count - 1], transform.position)) return;

            posArray.Add((transform.position));

            int posSize = posArray.Count;

            Vector3 p0 = posArray[posSize - 1];
            Vector3 p1 = posArray[posSize - 2];

            float distance = Vector3.Distance(p0, p1);

            Vector3 dir = (p0 - p1).normalized;
            Vector3 left = Vector3.Cross(dir, Vector3.up);

            //Debug.Log("dir:" + dir.ToString() + ", " + "left:" + left.ToString() + ", " + "distance:" + distance.ToString());

            // v2 +++ v0
            // + \     +
            // +   \   +
            // +     \ +
            // v3 +++ v1

            Vector3 v0, v1, v2, v3;

            v1 = lastV0;
            v3 = lastV2;

            Vector3 newV = dir * distance;
            //Debug.Log("newV:" + newV.ToString());

            v0 = v1 + dir * distance;
            v2 = v3 + dir * distance;

            //Debug.Log("v0:" + v0.ToString() + ", " + "v1:" + v1.ToString());
            //Debug.Log("v2:" + v2.ToString() + ", " + "v3:" + v3.ToString());

            lastV0 = v0;
            lastV2 = v2;

            Vector3 aNormal = Vector3.Cross(v2 - v0, v1 - v0);
            Vector3 bNormal = Vector3.Cross(v1 - v3, v2 - v3);

            // vertices
            splitVertices.Add(v0); splitVertices.Add(v1); splitVertices.Add(v2);
            splitVertices.Add(v3); splitVertices.Add(v2); splitVertices.Add(v1);

            // indices
            splitTriangles.Add(currentIndex * 6);     splitTriangles.Add(currentIndex * 6 + 1); splitTriangles.Add(currentIndex * 6 + 2);
            splitTriangles.Add(currentIndex * 6 + 3); splitTriangles.Add(currentIndex * 6 + 4); splitTriangles.Add(currentIndex * 6 + 5);

            // uv
            splitUv.Add(new Vector2(1, 1)); splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 1));
            splitUv.Add(new Vector2(0, 0)); splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 0));

            // normals
            splitNormals.Add(aNormal); splitNormals.Add(aNormal); splitNormals.Add(aNormal);
            splitNormals.Add(bNormal); splitNormals.Add(bNormal); splitNormals.Add(bNormal);

            myMeshFilter.mesh.Clear();

            myMeshFilter.mesh.vertices  = splitVertices.ToArray();
            myMeshFilter.mesh.triangles = splitTriangles.ToArray();
            myMeshFilter.mesh.uv        = splitUv.ToArray();
            myMeshFilter.mesh.normals   = splitNormals.ToArray();

            meshLifeTime.Add(0);

            ++currentIndex;
            lastUpdateTime = 0;
        }
    }

    void trimTrail()
    {
        if ( meshLifeTime.Count > 0 && meshLifeTime[0] >= duration)
        {
            posArray.RemoveRange(0, 1);
            splitVertices.RemoveRange(0, 6);
            splitTriangles.RemoveRange(0, 6);
            splitUv.RemoveRange(0, 6);
            splitNormals.RemoveRange(0, 6);

            meshLifeTime.RemoveAt(0);

            for (int i = 0; i < splitTriangles.Count; i++)
            {
                splitTriangles[i] = i;
            }

            myMeshFilter.mesh.Clear();

            myMeshFilter.mesh.vertices  = splitVertices.ToArray();
            myMeshFilter.mesh.triangles = splitTriangles.ToArray();
            myMeshFilter.mesh.uv        = splitUv.ToArray();
            myMeshFilter.mesh.normals   = splitNormals.ToArray();
            currentIndex -= 1;
        }
    }

    void myReset()
    {
        myMeshFilter.mesh.Clear();

        splitVertices.Clear();
        splitTriangles.Clear();
        splitUv.Clear();
        splitNormals.Clear();

        isRest = false;
    }


    private void originalDrawTrail()
    {
        if (lastUpdateTime >= updateTime)
        {
            posArray.Add((transform.position));

            Vector3 p0 = posArray[posArray.Count - 1];
            Vector3 p1 = posArray[posArray.Count - 2];

            Vector3 ab = p0 - p1;

            //float angle = Mathf.Acos(Vector3.Dot(-ab.normalized, Vector3.right));
            float angle = Vector3.Angle(ab.normalized, Vector3.right);
            angle = Mathf.Deg2Rad * angle;
            float cosTheta = Mathf.Cos(angle);
            float sinTheta = Mathf.Sin(angle);

            float i = sinTheta * m_trailWidth;
            float k = cosTheta * m_trailWidth;

            Vector3 v0, v1, v2, v3;
            v0 = new Vector3(p0.x - i, p0.y, p0.z + k);
            v1 = new Vector3(p0.x + i, p0.y, p0.z - k);
            v2 = new Vector3(p1.x - i, p1.y, p1.z + k);
            v3 = new Vector3(p1.x + i, p1.y, p1.z - k);

            Vector3 aNormal = Vector3.Cross(v2 - v0, v1 - v0);
            Vector3 bNormal = Vector3.Cross(v1 - v3, v2 - v3);

            // vertices
            splitVertices.Add(v0); splitVertices.Add(v1); splitVertices.Add(v2);
            splitVertices.Add(v3); splitVertices.Add(v2); splitVertices.Add(v1);

            // indices
            splitTriangles.Add(currentIndex * 6); splitTriangles.Add(currentIndex * 6 + 1); splitTriangles.Add(currentIndex * 6 + 2);
            splitTriangles.Add(currentIndex * 6 + 3); splitTriangles.Add(currentIndex * 6 + 4); splitTriangles.Add(currentIndex * 6 + 5);

            // uv
            splitUv.Add(new Vector2(1, 1)); splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 1));
            splitUv.Add(new Vector2(0, 0)); splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 0));

            // normals
            splitNormals.Add(aNormal); splitNormals.Add(aNormal); splitNormals.Add(aNormal);
            splitNormals.Add(bNormal); splitNormals.Add(bNormal); splitNormals.Add(bNormal);

            myMeshFilter.mesh.vertices = splitVertices.ToArray();
            myMeshFilter.mesh.triangles = splitTriangles.ToArray();
            myMeshFilter.mesh.uv = splitUv.ToArray();
            myMeshFilter.mesh.normals = splitNormals.ToArray();

            ++currentIndex;
            lastUpdateTime = 0;
        }
        trimTrail();

        lastUpdateTime += Time.deltaTime;
    }

    // trash

    //private void newDrawTrail()
    //{
    //    if (lastUpdateTime >= updateTime)
    //    {
    //        // update position
    //        posArray.Add(transform.position);

    //        Vector3 p0 = posArray[currentIndex - 1];
    //        Vector3 p1 = posArray[currentIndex];

    //        Vector3 dir = (p0 - p1).normalized;
    //        float angle = Mathf.Acos(Vector3.Dot(-dir, Vector3.right));
    //        float cosTheta = Mathf.Cos(angle);
    //        float sinTheta = Mathf.Sin(angle);

    //        float i = sinTheta * m_trailWidth;
    //        float k = cosTheta * m_trailWidth;

    //        Vector3 p2 = p1 + dir * trailLength;

    //        Vector3 v0, v1, v2, v3;
    //        v0 = new Vector3(p1.x - i, p1.y, p1.z + k);
    //        v1 = new Vector3(p1.x + i, p1.y, p1.z - k);
    //        v2 = new Vector3(p2.x - i, p2.y, p2.z + k);
    //        v3 = new Vector3(p2.x + i, p2.y, p2.z - k);

    //        Vector3 aNormal = Vector3.Cross(v2 - v0, v1 - v0);
    //        Vector3 bNormal = Vector3.Cross(v1 - v3, v2 - v3);

    //        // vertices
    //        splitVertices.Add(v0); splitVertices.Add(v1); splitVertices.Add(v2);
    //        splitVertices.Add(v2); splitVertices.Add(v1); splitVertices.Add(v3);

    //        // indices
    //        int index = currentIndex - 1;
    //        splitTriangles.Add(index * 6); splitTriangles.Add(index * 6 + 1); splitTriangles.Add(index * 6 + 2);
    //        splitTriangles.Add(index * 6 + 3); splitTriangles.Add(index * 6 + 4); splitTriangles.Add(index * 6 + 5);

    //        // uv
    //        splitUv.Add(new Vector2(1, 1)); splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 1));
    //        splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 0));

    //        // normals
    //        splitNormals.Add(aNormal); splitNormals.Add(aNormal); splitNormals.Add(aNormal);
    //        splitNormals.Add(bNormal); splitNormals.Add(bNormal); splitNormals.Add(bNormal);

    //        myMeshFilter.mesh.vertices = splitVertices.ToArray();
    //        myMeshFilter.mesh.triangles = splitTriangles.ToArray();
    //        myMeshFilter.mesh.uv = splitUv.ToArray();
    //        myMeshFilter.mesh.normals = splitNormals.ToArray();

    //        lastUpdateTime = 0;
    //        currentIndex++;
    //    }
    //    trimTrail();

    //    lastUpdateTime += Time.deltaTime;
    //}

    //private void newnewDrawTrail()
    //{
    //    posArray.Add(transform.position);

    //    Vector3 p0 = posArray[currentIndex];
    //    Vector3 p1 = posArray[currentIndex + 1];

    //    Vector3 ab = p1 - p0;
    //    float angle = Mathf.Acos(Vector3.Dot(ab.normalized, Vector3.right.normalized));
    //    float cosTheta = Mathf.Cos(angle);
    //    float sinTheta = Mathf.Sin(angle);

    //    float i = sinTheta * m_trailWidth;
    //    float k = cosTheta * m_trailWidth;

    //    Vector3 offset = ab - gameObject.transform.position;
    //    offset.y = 0;

    //    Vector3 v0, v1, v2, v3;
    //    v0 = new Vector3(-p0.x - i, p0.y, p0.z + k);
    //    v1 = new Vector3(-p1.x + i, p1.y, p1.z - k);
    //    v2 = new Vector3(-p0.x + i, p0.y, p0.z - k);
    //    v3 = new Vector3(-p1.x - i, p1.y, p1.z + k);

    //    Vector3 aNormal = -Vector3.Cross(v2 - v0, v1 - v0);
    //    Vector3 bNormal = -Vector3.Cross(v0 - v3, v1 - v3);

    //    // vertices
    //    splitVertices.Add(v3); splitVertices.Add(v0); splitVertices.Add(v1);
    //    splitVertices.Add(v2); splitVertices.Add(v1); splitVertices.Add(v0);

    //    // indices
    //    splitTriangles.Add(currentIndex * 6); splitTriangles.Add(currentIndex * 6 + 1); splitTriangles.Add(currentIndex * 6 + 2);
    //    splitTriangles.Add(currentIndex * 6 + 3); splitTriangles.Add(currentIndex * 6 + 4); splitTriangles.Add(currentIndex * 6 + 5);

    //    // uv
    //    splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 1)); splitUv.Add(new Vector2(0, 0));
    //    splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 0)); splitUv.Add(new Vector2(1, 1));

    //    // normals
    //    splitNormals.Add(aNormal); splitNormals.Add(aNormal); splitNormals.Add(aNormal);
    //    splitNormals.Add(bNormal); splitNormals.Add(bNormal); splitNormals.Add(bNormal);

    //    myMeshFilter.mesh.vertices = splitVertices.ToArray();
    //    myMeshFilter.mesh.triangles = splitTriangles.ToArray();
    //    myMeshFilter.mesh.uv = splitUv.ToArray();
    //    myMeshFilter.mesh.normals = splitNormals.ToArray();

    //    Graphics.DrawMesh(myMeshFilter.mesh, gameObject.transform.localToWorldMatrix, myMeshRenderer.material, 0, Camera.main);

    //    ++currentIndex;
    //    lastUpdateTime = 0;
    //}
    //private void test()
    //{
    //    //transform.position += Vector3.right * 10;
    //    posArray.Add(transform.position);

    //    Vector3 p0 = posArray[currentIndex];
    //    Vector3 p1 = posArray[currentIndex + 1];

    //    Vector3 ab = p1 - p0;
    //    float angle = Mathf.Acos(Vector3.Dot(ab.normalized, Vector3.right.normalized));
    //    float cosTheta = Mathf.Cos(angle);
    //    float sinTheta = Mathf.Sin(angle);

    //    float i = sinTheta * m_trailWidth;
    //    float k = cosTheta * m_trailWidth;

    //    Vector3 v0, v1, v2, v3;
    //    v0 = new Vector3(p0.x - i, p0.y, p0.z + k);
    //    v1 = new Vector3(p1.x + i, p1.y, p1.z - k);
    //    v2 = new Vector3(p0.x + i, p0.y, p0.z - k);
    //    v3 = new Vector3(p1.x - i, p1.y, p1.z + k);

    //    Vector3 aNormal = Vector3.Cross(v2 - v0, v1 - v0);
    //    Vector3 bNormal = Vector3.Cross(v0 - v3, v1 - v3);

    //    // vertices
    //    splitVertices.Add(v0); splitVertices.Add(v1); splitVertices.Add(v2);
    //    splitVertices.Add(v0); splitVertices.Add(v3); splitVertices.Add(v1);

    //    // indices
    //    splitTriangles.Add(currentIndex * 6); splitTriangles.Add(currentIndex * 6 + 1); splitTriangles.Add(currentIndex * 6 + 2);
    //    splitTriangles.Add(currentIndex * 6 + 3); splitTriangles.Add(currentIndex * 6 + 4); splitTriangles.Add(currentIndex * 6 + 5);

    //    // uv
    //    splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 0)); splitUv.Add(new Vector2(0, 0));
    //    splitUv.Add(new Vector2(0, 1)); splitUv.Add(new Vector2(1, 1)); splitUv.Add(new Vector2(1, 0));

    //    // normals
    //    splitNormals.Add(aNormal); splitNormals.Add(aNormal); splitNormals.Add(aNormal);
    //    splitNormals.Add(bNormal); splitNormals.Add(bNormal); splitNormals.Add(bNormal);

    //    myMeshFilter.mesh.vertices = splitVertices.ToArray();
    //    myMeshFilter.mesh.triangles = splitTriangles.ToArray();
    //    myMeshFilter.mesh.uv = splitUv.ToArray();
    //    myMeshFilter.mesh.normals = splitNormals.ToArray();

    //    Graphics.DrawMesh(myMeshFilter.mesh, gameObject.transform.localToWorldMatrix, myMeshRenderer.material, 0, Camera.main);

    //    ++currentIndex;
    //    lastUpdateTime = 0;
    //}

}
