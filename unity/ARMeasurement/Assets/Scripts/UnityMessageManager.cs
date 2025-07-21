using System;
using UnityEngine;
using UnityEngine.Events;

namespace ARMeasurement
{
    public class UnityMessageManager : MonoBehaviour
    {
        public static UnityMessageManager Instance { get; private set; }
        
        // Events for Flutter communication
        [Serializable]
        public class MessageReceived : UnityEvent<string> { }
        
        public MessageReceived OnMessageReceived;
        
        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }
        
        /// <summary>
        /// Send message to Flutter
        /// </summary>
        /// <param name="message">JSON message to send</param>
        public void SendMessageToFlutter(string message)
        {
            try
            {
                // This method name must match the one expected by flutter_unity_widget
                UnityEngine.Application.ExternalCall("onUnityMessage", message);
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to send message to Flutter: {e}");
            }
        }
        
        /// <summary>
        /// Receive message from Flutter
        /// Called by flutter_unity_widget
        /// </summary>
        /// <param name="message">JSON message from Flutter</param>
        public void OnFlutterMessage(string message)
        {
            try
            {
                Debug.Log($"Received message from Flutter: {message}");
                OnMessageReceived?.Invoke(message);
                
                // Forward to AR measurement manager
                var arManager = FindObjectOfType<ARMeasurementManager>();
                arManager?.OnFlutterMessage(message);
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to handle Flutter message: {e}");
            }
        }
        
        /// <summary>
        /// Unity scene loaded callback - called by flutter_unity_widget
        /// </summary>
        /// <param name="sceneName">Name of the loaded scene</param>
        public void OnSceneLoaded(string sceneName)
        {
            Debug.Log($"Unity scene loaded: {sceneName}");
            
            // Notify Flutter that Unity is ready
            SendMessageToFlutter(JsonUtility.ToJson(new
            {
                method = "onUnitySceneLoaded",
                data = JsonUtility.ToJson(new { sceneName = sceneName })
            }));
        }
        
        /// <summary>
        /// Check AR support and send result to Flutter
        /// </summary>
        public void CheckARSupport()
        {
            try
            {
                bool isSupported = UnityEngine.XR.ARSubsystems.XRSubsystemHelpers.GetRunningSubsystem<UnityEngine.XR.ARSubsystems.XRSessionSubsystem>() != null ||
                                   UnityEngine.XR.ARFoundation.ARSession.state == UnityEngine.XR.ARFoundation.ARSessionState.Ready;
                
                var supportData = new
                {
                    isSupported = isSupported,
                    platform = Application.platform.ToString(),
                    deviceModel = SystemInfo.deviceModel
                };
                
                SendMessageToFlutter(JsonUtility.ToJson(new
                {
                    method = "onARSupportChecked",
                    data = JsonUtility.ToJson(supportData)
                }));
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to check AR support: {e}");
                
                SendMessageToFlutter(JsonUtility.ToJson(new
                {
                    method = "onARError",
                    data = JsonUtility.ToJson(new { message = e.Message })
                }));
            }
        }
    }
}