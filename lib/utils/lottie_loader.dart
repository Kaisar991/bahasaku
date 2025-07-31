import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  final String path;

  LottieLoader({required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(path, width: 200, height: 200),
    );
  }
}
