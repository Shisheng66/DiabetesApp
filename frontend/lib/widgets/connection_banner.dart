import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connection_provider.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();
    if (connection.online) {
      return const SizedBox.shrink();
    }

    final checking = connection.state == BackendConnectionState.checking;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: checking
                  ? const Color(0xFFEAF4FF)
                  : const Color(0xFFFFEFEA),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                if (checking)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 19,
                    color: Color(0xFFC53A2E),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connection.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: checking
                          ? const Color(0xFF285A86)
                          : const Color(0xFF9B3429),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<ConnectionProvider>().check(
                    forceResolve: true,
                  ),
                  child: const Text('重新连接'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
