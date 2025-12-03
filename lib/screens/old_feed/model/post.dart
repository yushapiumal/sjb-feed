import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String id;
  String groupId;
  String link;
  String instruction;
  List<String> reactions;
  String createdBy; // Added
  Timestamp? createdAt; // Make nullable or handle

  Post({
    required this.id,
    required this.groupId,
    required this.link,
    required this.instruction,
    this.reactions = const [],
    this.createdBy = '',
    this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    return Post(
      id: id,
      groupId: map['groupId'] ?? '',
      link: map['link'] ?? '',
      instruction: map['instruction'] ?? '',
      reactions: List<String>.from(map['reactions'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'link': link,
      'instruction': instruction,
      'reactions': reactions,
      'createdBy': createdBy,
      'createdAt': Timestamp.now(),
    };
  }
}