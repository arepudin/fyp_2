class Curtain {
  final String id;
  final String name;
  final String imageUrl;
  final String designPattern;
  final String material;
  final String lightControl;
  final String roomType; // <-- NEW
  final String style;    // <-- NEW

  Curtain({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.designPattern,
    required this.material,
    required this.lightControl,
    required this.roomType, // <-- NEW
    required this.style,    // <-- NEW
  });

  factory Curtain.fromMap(Map<String, dynamic> map) {
    return Curtain(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Curtain',
      imageUrl: map['image_url'] ?? 'https://placehold.co/400x400/cccccc/333333?text=No+Image',
      designPattern: map['design_pattern'] ?? 'Unknown',
      material: map['material'] ?? 'Unknown',
      lightControl: map['light_control'] ?? 'Unknown',
      roomType: map['room_type'] ?? 'Living Room', // <-- NEW
      style: map['style'] ?? 'Modern',             // <-- NEW
    );
  }

  Map<String, String> get preferencesAsMap => {
    'design_pattern': designPattern,
    'material': material,
    'light_control': lightControl,
    'room_type': roomType,
    'style': style,
  };
}