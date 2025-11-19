import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// دالة صورة المستخدم الافتراضية
String defaultUserProfile() => 'https://via.placeholder.com/150';

// تعريف ScrollBehavior (إذا كنت ستستخدمه)
ScrollBehavior scrollBehaviour() => const ScrollBehavior().copyWith(
  scrollbars: false, // إخفاء شريط التمرير
  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
);

// يمكنك إضافة أي ودجتات أو دوال مساعدة أخرى هنا لاحقاً