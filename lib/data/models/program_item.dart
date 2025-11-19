import 'package:equatable/equatable.dart';

class ProgramItem extends Equatable {
  final int id;
  final String title;
  // 1. Field is nullable
  final String? image;
  final String postType;

  // 2. Constructor parameter 'image' is now optional (no 'required')
  const ProgramItem({
    required this.id,
    required this.title,
    this.image, // Optional parameter allows null
    required this.postType,
  }); // Line 12 area

  factory ProgramItem.fromJson(Map<String, dynamic> json) {
    // Read ID safely
    num idNum = json['id'] ?? 0;

    return ProgramItem(
      id: idNum.toInt(),
      title: json['title'] as String? ?? '', // Provide default non-null
      // 3. Cast to String? matches the optional 'image' parameter
      image: json['image'] as String?, // Line 23 area
      postType: json['post_type'] as String? ?? '', // Provide default non-null
    );
  }

  @override
  // 4. props list correctly includes the nullable 'image'
  List<Object?> get props => [id, title, image, postType];
}