class AthkarData {
  final String title;
  final List<AthkarReciter> reciters;
  final List<AthkarItem> content;

  AthkarData({required this.title, required this.reciters, required this.content});

  factory AthkarData.fromJson(Map<String, dynamic> json) {
    return AthkarData(
      title: json['title'],
      reciters: (json['reciters'] as List).map((e) => AthkarReciter.fromJson(e)).toList(),
      content: (json['content'] as List).map((e) => AthkarItem.fromJson(e)).toList(),
    );
  }
}

class AthkarReciter {
  final String name;
  final String audioUrl;
  AthkarReciter({required this.name, required this.audioUrl});
  factory AthkarReciter.fromJson(Map<String, dynamic> json) => 
      AthkarReciter(name: json['name'], audioUrl: json['audio_url']);
}

class AthkarItem {
  final String text;
  final int count;
  final String? reward;
  // متغير للتحكم في العداد داخل التطبيق (لا يأتي من الجيسون)
  int currentCount; 

  AthkarItem({required this.text, required this.count, this.reward, required this.currentCount});

  factory AthkarItem.fromJson(Map<String, dynamic> json) => 
      AthkarItem(text: json['text'], count: json['count'], reward: json['reward'], currentCount: json['count']);
}