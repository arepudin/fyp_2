using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

namespace ARMeasurement
{
    public class ARMeasurementManager : MonoBehaviour
    {
        [Header("AR Components")]
        public ARRaycastManager raycastManager;
        public ARPlaneManager planeManager;
        public GameObject pointPrefab;
        
        [Header("Measurement Settings")]
        public float pointSize = 0.02f;
        public Material placedPointMaterial;
        public Material completedPointMaterial;
        
        private List<GameObject> placedMarkers = new List<GameObject>();
        private List<Vector3> placedPositions = new List<Vector3>();
        private Camera arCamera;
        private bool isInitialized = false;
        
        // Measurement data
        private string currentUnit = "meters";
        
        void Start()
        {
            arCamera = Camera.main;
            if (arCamera == null)
                arCamera = FindObjectOfType<Camera>();
                
            InitializeAR();
        }
        
        void InitializeAR()
        {
            if (raycastManager == null)
                raycastManager = FindObjectOfType<ARRaycastManager>();
                
            if (planeManager == null)
                planeManager = FindObjectOfType<ARPlaneManager>();
                
            isInitialized = true;
            
            // Send initialization complete message to Flutter
            SendToFlutter("onARInitialized", new { success = true });
        }
        
        void Update()
        {
            // Handle touch input for point placement
            if (Input.touchCount > 0 && isInitialized)
            {
                Touch touch = Input.GetTouch(0);
                if (touch.phase == TouchPhase.Began && placedPositions.Count < 4)
                {
                    PlacePoint(touch.position);
                }
            }
        }
        
        void PlacePoint(Vector2 screenPosition)
        {
            List<ARRaycastHit> hits = new List<ARRaycastHit>();
            
            if (raycastManager.Raycast(screenPosition, hits, TrackableType.PlaneWithinPolygon))
            {
                Pose hitPose = hits[0].pose;
                
                // Create visual marker
                GameObject marker = Instantiate(pointPrefab, hitPose.position, hitPose.rotation);
                marker.transform.localScale = Vector3.one * pointSize;
                
                // Set material based on completion status
                Renderer renderer = marker.GetComponent<Renderer>();
                if (renderer != null)
                {
                    renderer.material = placedPositions.Count < 3 ? placedPointMaterial : completedPointMaterial;
                }
                
                placedMarkers.Add(marker);
                placedPositions.Add(hitPose.position);
                
                // Send point data to Flutter
                var pointData = new
                {
                    id = $"point_{placedPositions.Count - 1}",
                    position = new float[] { hitPose.position.x, hitPose.position.y, hitPose.position.z },
                    timestamp = DateTime.Now.ToString("o")
                };
                
                SendToFlutter("onPointPlaced", pointData);
                
                // Check if measurement is complete
                if (placedPositions.Count == 4)
                {
                    CalculateMeasurement();
                }
            }
        }
        
        void CalculateMeasurement()
        {
            if (placedPositions.Count < 4) return;
            
            // Calculate distances
            Vector3 bottomLeft = placedPositions[0];
            Vector3 bottomRight = placedPositions[1];
            Vector3 topRight = placedPositions[2];
            Vector3 topLeft = placedPositions[3];
            
            float widthMeters = Vector3.Distance(bottomLeft, bottomRight);
            float heightMeters = Vector3.Distance(bottomLeft, topLeft);
            
            // Convert to current unit
            float width = currentUnit == "meters" ? widthMeters : widthMeters * 39.3701f;
            float height = currentUnit == "meters" ? heightMeters : heightMeters * 39.3701f;
            
            var measurementData = new
            {
                width = Math.Round(width, currentUnit == "meters" ? 2 : 1),
                height = Math.Round(height, currentUnit == "meters" ? 2 : 1),
                unit = currentUnit,
                accuracy = CalculateAccuracy()
            };
            
            SendToFlutter("onMeasurementComplete", measurementData);
        }
        
        float CalculateAccuracy()
        {
            if (placedPositions.Count == 0) return 0f;
            
            float totalDistance = 0f;
            foreach (var pos in placedPositions)
            {
                totalDistance += Vector3.Distance(Vector3.zero, pos);
            }
            
            float averageDistance = totalDistance / placedPositions.Count;
            return averageDistance * 0.01f; // 1cm per meter
        }
        
        public void ClearPoints()
        {
            foreach (var marker in placedMarkers)
            {
                if (marker != null)
                    Destroy(marker);
            }
            
            placedMarkers.Clear();
            placedPositions.Clear();
            
            SendToFlutter("onPointsCleared", new { success = true });
        }
        
        public void SetUnit(string unit)
        {
            currentUnit = unit.ToLower();
            
            // Recalculate if measurement is complete
            if (placedPositions.Count == 4)
            {
                CalculateMeasurement();
            }
        }
        
        void SendToFlutter(string method, object data)
        {
            try
            {
                string message = JsonUtility.ToJson(new FlutterMessage
                {
                    method = method,
                    data = JsonUtility.ToJson(data)
                });
                
                // Send to Flutter via Unity-Flutter bridge
                UnityMessageManager.Instance.SendMessageToFlutter(message);
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to send message to Flutter: {e}");
            }
        }
        
        // Handle commands from Flutter
        public void OnFlutterMessage(string message)
        {
            try
            {
                var command = JsonUtility.FromJson<FlutterCommand>(message);
                
                switch (command.command)
                {
                    case "InitializeAR":
                        InitializeAR();
                        break;
                    case "PlacePoint":
                        var pointData = JsonUtility.FromJson<PointPlacementData>(command.data);
                        PlacePoint(new Vector2(pointData.screenX, pointData.screenY));
                        break;
                    case "ClearPoints":
                        ClearPoints();
                        break;
                    case "SetUnit":
                        var unitData = JsonUtility.FromJson<UnitData>(command.data);
                        SetUnit(unitData.unit);
                        break;
                }
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to handle Flutter message: {e}");
                SendToFlutter("onARError", new { message = e.Message });
            }
        }
    }
    
    [Serializable]
    public class FlutterMessage
    {
        public string method;
        public string data;
    }
    
    [Serializable]
    public class FlutterCommand
    {
        public string command;
        public string data;
    }
    
    [Serializable]
    public class PointPlacementData
    {
        public float screenX;
        public float screenY;
        public int pointIndex;
    }
    
    [Serializable]
    public class UnitData
    {
        public string unit;
    }
}