import 'package:flutter/material.dart';

class DomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double curveStartHeight =
        h * 0.35; // The height where the arch starts

    path.moveTo(0, h); // Start at bottom-left
    path.lineTo(w, h); // Bottom-right
    path.lineTo(w, curveStartHeight); // Right edge straight up

    // Pointed Arch to the top center
    path.quadraticBezierTo(w * 0.85, curveStartHeight * 0.2, w / 2, 0);

    // Arch from top center down to left edge
    path.quadraticBezierTo(
        w * 0.15, curveStartHeight * 0.2, 0, curveStartHeight);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
