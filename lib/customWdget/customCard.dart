import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final double elevation;
  final Color color;
  final ShapeBorder? shape;
  final Color? surfaceTintColor;
  const CustomCard(
      {super.key,
        required this.child,
        required this.elevation,
        required this.color,
        this.shape,
        this.surfaceTintColor});

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 7,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
