import 'package:flutter/material.dart';

/// Skeleton Loader for Messages - Shows shimmer effect while loading
class MessageSkeletonLoader extends StatefulWidget {
  final bool isDark;
  final int itemCount;

  const MessageSkeletonLoader({
    super.key,
    required this.isDark,
    this.itemCount = 8,
  });

  @override
  State<MessageSkeletonLoader> createState() => _MessageSkeletonLoaderState();
}

class _MessageSkeletonLoaderState extends State<MessageSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            final isMe = index % 3 == 0;
            return _buildSkeletonMessage(isMe, index);
          },
        );
      },
    );
  }

  Widget _buildSkeletonMessage(bool isMe, int index) {
    final baseColor =
        widget.isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        widget.isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildShimmerBox(
              width: 36,
              height: 36,
              borderRadius: 18,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildShimmerBox(
                    width: 80,
                    height: 12,
                    borderRadius: 4,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ),
              _buildShimmerBox(
                width: 180 + (index * 20 % 80).toDouble(),
                height: 40 + (index * 10 % 30).toDouble(),
                borderRadius: 16,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(height: 4),
              _buildShimmerBox(
                width: 50,
                height: 10,
                borderRadius: 4,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
          if (isMe) ...[const SizedBox(width: 8)],
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Skeleton Loader for Conversation List
class ConversationSkeletonLoader extends StatefulWidget {
  final bool isDark;
  final int itemCount;

  const ConversationSkeletonLoader({
    super.key,
    required this.isDark,
    this.itemCount = 6,
  });

  @override
  State<ConversationSkeletonLoader> createState() =>
      _ConversationSkeletonLoaderState();
}

class _ConversationSkeletonLoaderState extends State<ConversationSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        widget.isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return _buildSkeletonTile(baseColor, highlightColor);
          },
        );
      },
    );
  }

  Widget _buildSkeletonTile(Color baseColor, Color highlightColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _buildShimmerBox(
            width: 48,
            height: 48,
            borderRadius: 24,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  width: 120,
                  height: 14,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 6),
                _buildShimmerBox(
                  width: 180,
                  height: 12,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildShimmerBox(
                width: 40,
                height: 10,
                borderRadius: 4,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(height: 6),
              _buildShimmerBox(
                width: 20,
                height: 20,
                borderRadius: 10,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
