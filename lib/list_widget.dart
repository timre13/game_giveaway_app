import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkWidget extends StatefulWidget {
  const LinkWidget({
    Key? key,
    required this.text,
    required this.url,
  }) : super(key: key);

  final String text;
  final Uri url;

  @override
  State<LinkWidget> createState() => _LinkWidgetState();
}

class _LinkWidgetState extends State<LinkWidget> {
  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.background, 0.2);

    return InkWell(
        child: Text(widget.text,
            style: TextStyle(
                color: color,
                decoration: TextDecoration.underline,
                decorationThickness: 1.5)),
        onTap: () => launchUrl(widget.url));
  }
}
