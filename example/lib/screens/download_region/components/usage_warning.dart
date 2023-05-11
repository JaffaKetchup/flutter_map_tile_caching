import 'package:flutter/material.dart';

class UsageWarning extends StatelessWidget {
  const UsageWarning({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: const [
          Icon(
            Icons.warning_amber,
            color: Colors.red,
            size: 36,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "You must abide by your tile server's Terms of Service when Bulk Downloading. Many servers will forbid or heavily restrict this action, as it places extra strain on resources. Be respectful, and note that you use this functionality at your own risk.\nThis example application is limited to a maximum of 2 simultaneous download threads by default.",
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      );
}
