import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ExpandChevron extends StatelessWidget {
  const ExpandChevron({super.key, required this.expanded, this.size = 14});

  final bool expanded;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FaIcon(
      expanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
      size: size,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
