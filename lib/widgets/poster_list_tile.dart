import 'package:flutter/material.dart';

/// A poster thumbnail + title/subtitle row, used by search results and the
/// watchlist. Centralizes the TMDB image URL so it's built the same way
/// everywhere.
class PosterListTile extends StatelessWidget {
  final String? posterPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const PosterListTile({
    super.key,
    required this.posterPath,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  static String posterUrl(String path) =>
      'https://image.tmdb.org/t/p/w200$path';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 46,
            height: 69,
            child: posterPath == null
                ? const ColoredBox(
                    color: Color(0xFF2A2733),
                    child: Icon(Icons.image_not_supported, size: 20),
                  )
                : Image.network(
                    posterUrl(posterPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const ColoredBox(
                      color: Color(0xFF2A2733),
                      child: Icon(Icons.image_not_supported, size: 20),
                    ),
                  ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing,
      ),
    );
  }
}
