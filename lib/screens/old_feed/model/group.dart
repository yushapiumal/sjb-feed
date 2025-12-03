class Group {
  String id;
  String name;
  String description;
  List<String> admins;
  List<String> members;

  Group({
    required this.id,
    required this.name,
    this.description = '',
    required this.admins,
    required this.members,
  });

  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      admins: List<String>.from(map['admins'] ?? []),
      members: List<String>.from(map['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'admins': admins,
      'members': members,
    };
  }
}