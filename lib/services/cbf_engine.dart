import 'dart:math';
import '../models/curtain_model.dart';

class ContentBasedRecommendationEngine {
  
  /// Calculate similarity between user preferences and curtain using TF-IDF-like approach
  double calculateSimilarity(Map<String, dynamic> userPreferences, Curtain curtain) {
    final userVector = _createUserVector(userPreferences);
    final curtainVector = _createCurtainVector(curtain);
    
    return _cosineSimilarity(userVector, curtainVector);
  }
  
  /// Create weighted vector from user preferences
  Map<String, double> _createUserVector(Map<String, dynamic> preferences) {
    Map<String, double> vector = {};
    
    // Design Pattern features
    vector.addAll(_encodeDesignPattern(preferences['design_pattern'] ?? ''));
    
    // Material features
    vector.addAll(_encodeMaterial(preferences['material'] ?? ''));
    
    // Light Control features
    vector.addAll(_encodeLightControl(preferences['light_control'] ?? ''));
    
    // Room Type features
    vector.addAll(_encodeRoomType(preferences['room_type'] ?? ''));
    
    return vector;
  }
  
  /// Create feature vector from curtain properties
  Map<String, double> _createCurtainVector(Curtain curtain) {
    Map<String, double> vector = {};
    
    vector.addAll(_encodeDesignPattern(curtain.designPattern));
    vector.addAll(_encodeMaterial(curtain.material));
    vector.addAll(_encodeLightControl(curtain.lightControl));
    vector.addAll(_encodeRoomType(curtain.roomType));
    
    return vector;
  }
  
  /// Encode design patterns with similarity weights
  Map<String, double> _encodeDesignPattern(String pattern) {
    Map<String, double> features = {};
    
    switch (pattern.toLowerCase()) {
      case 'stripes':
        features['pattern_stripes'] = 1.0;
        features['pattern_linear'] = 0.9;
        features['pattern_geometric'] = 0.7;
        features['pattern_complexity'] = 0.4;
        break;
      case 'solid/plain':
        features['pattern_solid'] = 1.0;
        features['pattern_plain'] = 1.0;
        features['pattern_minimal'] = 1.0;
        features['pattern_complexity'] = 0.1;
        break;
      case 'geometric':
        features['pattern_geometric'] = 1.0;
        features['pattern_structured'] = 0.8;
        features['pattern_modern'] = 0.7;
        features['pattern_complexity'] = 0.6;
        break;
      case 'floral':
        features['pattern_floral'] = 1.0;
        features['pattern_organic'] = 0.9;
        features['pattern_traditional'] = 0.7;
        features['pattern_complexity'] = 0.8;
        break;
      case 'damask':
        features['pattern_damask'] = 1.0;
        features['pattern_ornate'] = 0.9;
        features['pattern_traditional'] = 0.8;
        features['pattern_complexity'] = 0.9;
        break;
      case 'polka dots':
        features['pattern_polka_dots'] = 1.0;
        features['pattern_playful'] = 0.8;
        features['pattern_circular'] = 0.7;
        features['pattern_complexity'] = 0.5;
        break;
      default:
        features['pattern_unknown'] = 1.0;
    }
    
    return features;
  }
  
  /// Encode materials with similarity weights
  Map<String, double> _encodeMaterial(String material) {
    Map<String, double> features = {};
    
    switch (material.toLowerCase()) {
      case 'cotton':
        features['material_cotton'] = 1.0;
        features['material_natural'] = 1.0;
        features['material_breathable'] = 0.9;
        features['material_durability'] = 0.8;
        break;
      case 'linen':
        features['material_linen'] = 1.0;
        features['material_natural'] = 1.0;
        features['material_breathable'] = 1.0;
        features['material_casual'] = 0.9;
        break;
      case 'velvet':
        features['material_velvet'] = 1.0;
        features['material_luxurious'] = 1.0;
        features['material_heavy'] = 0.9;
        features['material_formal'] = 0.8;
        break;
      case 'sheer':
        features['material_sheer'] = 1.0;
        features['material_light'] = 1.0;
        features['material_translucent'] = 1.0;
        features['material_airy'] = 0.9;
        break;
      case 'polyester':
        features['material_polyester'] = 1.0;
        features['material_synthetic'] = 1.0;
        features['material_durable'] = 0.9;
        features['material_easy_care'] = 0.8;
        break;
      default:
        features['material_unknown'] = 1.0;
    }
    
    return features;
  }
  
  /// Encode light control with functionality weights
  Map<String, double> _encodeLightControl(String lightControl) {
    Map<String, double> features = {};
    
    switch (lightControl.toLowerCase()) {
      case 'blackout':
        features['light_blackout'] = 1.0;
        features['light_blocking'] = 1.0;
        features['light_privacy'] = 1.0;
        features['light_darkness'] = 1.0;
        break;
      case 'dimout':
        features['light_dimout'] = 1.0;
        features['light_blocking'] = 0.8;
        features['light_privacy'] = 0.9;
        features['light_darkness'] = 0.8;
        break;
      case 'light filtering':
        features['light_filtering'] = 1.0;
        features['light_soft'] = 1.0;
        features['light_privacy'] = 0.6;
        features['light_brightness'] = 0.7;
        break;
      default:
        features['light_unknown'] = 1.0;
    }
    
    return features;
  }
  
  /// Encode room types with contextual weights
  Map<String, double> _encodeRoomType(String roomType) {
    Map<String, double> features = {};
    
    switch (roomType.toLowerCase()) {
      case 'living room':
        features['room_living'] = 1.0;
        features['room_social'] = 1.0;
        features['room_large'] = 0.8;
        features['room_decorative'] = 0.9;
        break;
      case 'bedroom':
        features['room_bedroom'] = 1.0;
        features['room_private'] = 1.0;
        features['room_dark'] = 0.9;
        features['room_quiet'] = 0.8;
        break;
      case 'kitchen':
        features['room_kitchen'] = 1.0;
        features['room_functional'] = 1.0;
        features['room_humid'] = 0.7;
        features['room_small'] = 0.6;
        break;
      case 'office':
        features['room_office'] = 1.0;
        features['room_professional'] = 1.0;
        features['room_focused'] = 0.9;
        features['room_minimal'] = 0.8;
        break;
      default:
        features['room_unknown'] = 1.0;
    }
    
    return features;
  }
  
  /// Calculate cosine similarity between two feature vectors
  double _cosineSimilarity(Map<String, double> vectorA, Map<String, double> vectorB) {
    // Get all unique features
    Set<String> allFeatures = {...vectorA.keys, ...vectorB.keys};
    
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;
    
    for (String feature in allFeatures) {
      double valueA = vectorA[feature] ?? 0.0;
      double valueB = vectorB[feature] ?? 0.0;
      
      dotProduct += valueA * valueB;
      magnitudeA += valueA * valueA;
      magnitudeB += valueB * valueB;
    }
    
    if (magnitudeA == 0.0 || magnitudeB == 0.0) return 0.0;
    
    return dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB));
  }
  
  /// Calculate weighted score with must-have constraints
  double calculateWeightedScore(
    Map<String, dynamic> userPreferences,
    Curtain curtain,
    Map<String, bool> mustHaves,
    Map<String, double> categoryWeights,
  ) {
    double totalScore = 0.0;
    double totalWeight = 0.0;
    
    // Pattern score
    if (mustHaves['pattern'] == true) {
      if (curtain.designPattern == userPreferences['design_pattern']) {
        totalScore += 1.0 * categoryWeights['pattern']!;
      } else {
        return 0.0; // Must-have not met
      }
    } else {
      double patternSimilarity = calculatePatternSimilarity(
        userPreferences['design_pattern'], 
        curtain.designPattern
      );
      totalScore += patternSimilarity * categoryWeights['pattern']!;
    }
    totalWeight += categoryWeights['pattern']!;
    
    // Material score
    if (mustHaves['material'] == true) {
      if (curtain.material == userPreferences['material']) {
        totalScore += 1.0 * categoryWeights['material']!;
      } else {
        return 0.0; // Must-have not met
      }
    } else {
      double materialSimilarity = calculateMaterialSimilarity(
        userPreferences['material'], 
        curtain.material
      );
      totalScore += materialSimilarity * categoryWeights['material']!;
    }
    totalWeight += categoryWeights['material']!;
    
    // Light Control score
    if (mustHaves['lightControl'] == true) {
      if (curtain.lightControl == userPreferences['light_control']) {
        totalScore += 1.0 * categoryWeights['lightControl']!;
      } else {
        return 0.0; // Must-have not met
      }
    } else {
      double lightSimilarity = calculateLightControlSimilarity(
        userPreferences['light_control'], 
        curtain.lightControl
      );
      totalScore += lightSimilarity * categoryWeights['lightControl']!;
    }
    totalWeight += categoryWeights['lightControl']!;
    
    // Room Type score
    if (mustHaves['roomType'] == true) {
      if (curtain.roomType == userPreferences['room_type']) {
        totalScore += 1.0 * categoryWeights['roomType']!;
      } else {
        return 0.0; // Must-have not met
      }
    } else {
      double roomSimilarity = calculateRoomTypeSimilarity(
        userPreferences['room_type'], 
        curtain.roomType
      );
      totalScore += roomSimilarity * categoryWeights['roomType']!;
    }
    totalWeight += categoryWeights['roomType']!;
    
    return totalScore / totalWeight;
  }
  
  /// PUBLIC: Calculate pattern similarity
  double calculatePatternSimilarity(String pattern1, String pattern2) {
    if (pattern1 == pattern2) return 1.0;
    
    // Define pattern similarity matrix
    const Map<String, Map<String, double>> patternSimilarity = {
      'stripes': {'geometric': 0.6, 'solid/plain': 0.3},
      'solid/plain': {'stripes': 0.3, 'geometric': 0.4},
      'geometric': {'stripes': 0.6, 'damask': 0.5, 'polka dots': 0.4},
      'floral': {'damask': 0.7, 'polka dots': 0.3},
      'damask': {'floral': 0.7, 'geometric': 0.5},
      'polka dots': {'geometric': 0.4, 'floral': 0.3},
    };
    
    return patternSimilarity[pattern1.toLowerCase()]?[pattern2.toLowerCase()] ?? 0.0;
  }
  
  /// PUBLIC: Calculate material similarity
  double calculateMaterialSimilarity(String material1, String material2) {
    if (material1 == material2) return 1.0;
    
    const Map<String, Map<String, double>> materialSimilarity = {
      'cotton': {'linen': 0.8, 'polyester': 0.3},
      'linen': {'cotton': 0.8, 'sheer': 0.4},
      'velvet': {'polyester': 0.5},
      'sheer': {'linen': 0.4, 'polyester': 0.6},
      'polyester': {'cotton': 0.3, 'velvet': 0.5, 'sheer': 0.6},
    };
    
    return materialSimilarity[material1.toLowerCase()]?[material2.toLowerCase()] ?? 0.0;
  }
  
  /// PUBLIC: Calculate light control similarity
  double calculateLightControlSimilarity(String light1, String light2) {
    if (light1 == light2) return 1.0;
    
    const Map<String, Map<String, double>> lightSimilarity = {
      'blackout': {'dimout': 0.8},
      'dimout': {'blackout': 0.8, 'light filtering': 0.4},
      'light filtering': {'dimout': 0.4},
    };
    
    return lightSimilarity[light1.toLowerCase()]?[light2.toLowerCase()] ?? 0.0;
  }
  
  /// PUBLIC: Calculate room type similarity
  double calculateRoomTypeSimilarity(String room1, String room2) {
    if (room1 == room2) return 1.0;
    
    const Map<String, Map<String, double>> roomSimilarity = {
      'living room': {'office': 0.3},
      'bedroom': {'living room': 0.2},
      'kitchen': {'office': 0.4},
      'office': {'living room': 0.3, 'kitchen': 0.4},
    };
    
    return roomSimilarity[room1.toLowerCase()]?[room2.toLowerCase()] ?? 0.0;
  }
}