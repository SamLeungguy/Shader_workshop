using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Week002_Trail : MonoBehaviour
{
    int targetFrameRate = 30;

    [System.Serializable]
    struct Node
    {
        public Vector3 pos0;
        public Vector3 pos1;
        public double time;
        public bool isBreakdown;
    }

    List<Node> nodes = new List<Node>();
    int currentNode = 0;
    public float width = 1;
    public float duration = 2;
    public float errorTolerance = 1;

    double startTime;

    List<Vector3> meshVertices = new List<Vector3>();
    List<Vector2> meshUV0 = new List<Vector2>();
    List<ushort> meshIndices = new List<ushort>();

    MeshFilter meshFilter;
    Mesh mesh;

    public Transform source;

    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = targetFrameRate;
        meshFilter = gameObject.GetComponent<MeshFilter>();

        if (!mesh)
        {
            mesh = new Mesh();
            mesh.name = "Trail Mesh";
        }
        startTime = Time.timeAsDouble;
    }

#if UNITY_EDITOR
    void OnDrawGizmos_Node(Node node)
    {
        Gizmos.color = node.isBreakdown ? Color.blue : Color.red;
        Gizmos.DrawLine(node.pos0, node.pos1);
    }

    void OnDrawGizmos()
    {
        int n = nodes.Count;
        for (int i = currentNode; i < n; i++)
        {
            OnDrawGizmos_Node(nodes[i]);
        }
    }
#endif

    // Update is called once per frame
    void LateUpdate()
    {
        updateNode();
        updateMesh();
    }

    void updateNode()
    {
        double time = Time.timeAsDouble;
        for (int i = 0; i < nodes.Count; i++)
        {
            // find the last which is not yet end
            if (nodes[i].time + duration < time)
            {
                currentNode = i + 1; 
            }
        }

        if (currentNode >= nodes.Count)
        {
            nodes.Clear();
            currentNode = 0;
        }
        else
        {
            int usedNode = nodes.Count - currentNode;
            if ( nodes.Count > 32 && currentNode > usedNode * 4)
            {
                nodes.RemoveRange(0, currentNode);
                currentNode = 0;
            }
        }

        if (source)
        {
            Node node = new Node();
            node.pos0 = source.position;
            node.pos1 = node.pos0 + source.right * width;
            node.time = time;
            addNode(node, 0);
        }
    }

    void addNode(Node node, int iteration)
    {
        const int maxIteration = 8;
        if (iteration >= maxIteration) return;

        if (nodes.Count == 0)
        {
            nodes.Add(node);
            return;
        }

        Node last = nodes[nodes.Count - 1];
        var mid0 = (node.pos0 + last.pos0) / 2;
        var mid1 = (node.pos1 + last.pos1) / 2;

        var midDist = Vector3.Distance(mid0, mid1);
        float err = Mathf.Abs(midDist - width);

        if (err < errorTolerance)
        {
            nodes.Add(node);
            return;
        }

        Node mid = new Node();
        mid.pos0 = mid0;
        mid.pos1 = mid1;
        mid.time = (node.time + last.time) / 2;
        mid.isBreakdown = true;

        addNode(mid,  iteration + 1);
        addNode(node, iteration + 1);
    }

    void updateMesh()
    {
        if (!meshFilter) return;
        meshFilter.sharedMesh = mesh;

        int n = nodes.Count - currentNode;
        if (n <= 0) return;

        meshVertices.Clear();
        meshUV0.Clear();
        meshIndices.Clear();
        mesh.SetIndices(meshIndices, MeshTopology.Triangles, 0);

        for (int i = 0; i < n; i++)
        {
            var node = nodes[currentNode + i];
            meshVertices.Add(node.pos0);
            meshVertices.Add(node.pos1);

            var u = (float)(node.time - startTime);
            meshUV0.Add(new Vector2(u, 0));
            meshUV0.Add(new Vector2(u, 1));

            if (i > 0)
            {
                int vi = (i - 1) * 2;
                meshIndices.Add((ushort)(vi));
                meshIndices.Add((ushort)(vi + 2));
                meshIndices.Add((ushort)(vi + 1));
                meshIndices.Add((ushort)(vi + 1));
                meshIndices.Add((ushort)(vi + 2));
                meshIndices.Add((ushort)(vi + 3));
            }
        }

        mesh.SetVertices(meshVertices);
        mesh.SetUVs(0, meshUV0);
        mesh.SetIndices(meshIndices, MeshTopology.Triangles, 0);
    }
}
