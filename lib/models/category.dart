class Category {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final String? iconUrl;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final List<String> subcategories;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.iconUrl,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.subcategories = const [],
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });
  factory Category.fromSupabaseJson(Map<String, dynamic> data, String id) {
  return Category(
    id: id,
    name: data["name"] ?? "",
    displayName: data["display_name"] ?? data["name"] ?? "",
    description: data["description"] ?? "",
    iconUrl: data["icon_url"] ?? data["iconUrl"], 
    imageUrl: data["image_url"] ?? data["imageUrl"], 
    isActive: data["is_active"] ?? true,
    sortOrder: data["sort_order"] ?? data["sortOrder"] ?? 0, 
    subcategories: List<String>.from(data["subcategories"] ?? []),
    metadata: Map<String, dynamic>.from(data["metadata"] ?? {}),
    createdAt: data['created_at'] != null
        ? DateTime.parse(data['created_at'])
        : null,
    updatedAt: data['updated_at'] != null
        ? DateTime.parse(data['updated_at'])
        : null,
  );
}

  Map<String, dynamic> toSupabasestore() {
    return {
      'name': name,
      'display_name': displayName,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'is_active': isActive,
      'sortOrder': sortOrder,
      'subcategories': subcategories,
      'metadata': metadata,
      'created_at':createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
