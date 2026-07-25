import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversion_provider.dart';

/// 日志显示区域
class LogSection extends StatelessWidget {
  const LogSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final logHeight = isTablet ? 240.0 : 160.0;

    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          height: logHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF232A31),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8A94A0), width: 2),
          ),
          child: LogListView(logs: provider.logs),
        );
      },
    );
  }
}

/// 日志列表（自动滚底）
class LogListView extends StatefulWidget {
  final List<String> logs;

  const LogListView({super.key, required this.logs});

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LogListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 日志更新时自动滚到底部
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: widget.logs.length,
      itemBuilder: (context, index) {
        final log = widget.logs[index];
        Color textColor = const Color(0xFFD7E0E8);
        if (log.contains('[OK]')) {
          textColor = const Color(0xFF6FCF97);
        } else if (log.contains('[FAIL]')) {
          textColor = const Color(0xFFEB5757);
        } else if (log.contains('----')) {
          textColor = const Color(0xFFFFD93D);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            log,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
              color: textColor,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }
}
