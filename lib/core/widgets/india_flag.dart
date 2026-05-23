import 'package:flutter/material.dart';

/// Simplified 3-stripe Indian flag — used in the dial-code chip.
/// Skips the Ashoka Chakra detail since it renders poorly at small sizes.
class IndiaFlag extends StatelessWidget {
  const IndiaFlag({super.key, this.width = 26, this.height = 18});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: Container(color: const Color(0xFFFF9933))),
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: const Color(0xFF138808))),
          ],
        ),
      ),
    );
  }
}
