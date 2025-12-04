import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final Color color;
  final Function(int)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24,
    this.color = Colors.amber,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(starIndex) : null,
          child: Icon(
            starIndex <= rating ? Icons.star : Icons.star_border,
            size: size,
            color: color,
          ),
        );
      }),
    );
  }
}
