using UnityEngine;

public class LavaTextureAnimator : MonoBehaviour
{
    [Header("Lava Renderer")]
    public Renderer lavaRenderer;

    [Header("Flow Settings")]
    public Vector2 flowSpeed = new Vector2(0.025f, 0.01f);

    [Header("Emission Animation")]
    public bool animateEmission = true;
    public Vector2 emissionFlowSpeed = new Vector2(0.025f, 0.01f);

    private Material lavaMaterial;
    private Vector2 baseOffset;
    private Vector2 emissionOffset;

    private static readonly int BaseMapID =
        Shader.PropertyToID("_BaseMap");

    private static readonly int EmissionMapID =
        Shader.PropertyToID("_EmissionMap");

    private void Start()
    {
        if (lavaRenderer == null)
            lavaRenderer = GetComponent<Renderer>();

        if (lavaRenderer == null)
        {
            Debug.LogError(
                "LavaTextureAnimator: No Renderer assigned.", this);
            enabled = false;
            return;
        }

        // Creates a material instance for this renderer.
        lavaMaterial = lavaRenderer.material;

        if (!lavaMaterial.HasProperty(BaseMapID))
        {
            Debug.LogError(
                "The assigned material does not have a Base Map. " +
                "Use a URP/Lit material.", this);
            enabled = false;
            return;
        }

        baseOffset = lavaMaterial.GetTextureOffset(BaseMapID);

        if (lavaMaterial.HasProperty(EmissionMapID))
            emissionOffset = lavaMaterial.GetTextureOffset(EmissionMapID);
    }

    private void Update()
    {
        if (lavaMaterial == null)
            return;

        baseOffset += flowSpeed * Time.deltaTime;

        lavaMaterial.SetTextureOffset(BaseMapID, baseOffset);

        if (animateEmission &&
            lavaMaterial.HasProperty(EmissionMapID))
        {
            emissionOffset += emissionFlowSpeed * Time.deltaTime;

            lavaMaterial.SetTextureOffset(
                EmissionMapID, emissionOffset);
        }
    }

    private void OnDestroy()
    {
        if (lavaMaterial != null)
        {
            Destroy(lavaMaterial);
        }
    }
}