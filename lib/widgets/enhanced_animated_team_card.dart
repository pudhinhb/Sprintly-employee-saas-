import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:webnox_taskops/model/team_card_model.dart';
import 'package:webnox_taskops/utils/responsive_utils.dart';

class EnhancedAnimatedTeamCard extends StatefulWidget {
  final TeamCard teamCard;
  final bool isCurrentlyClockedIn;
  final Duration? elapsedTime;
  final DateTime? startTime;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;
  final String? userRole;
  final int index;

  const EnhancedAnimatedTeamCard({
    super.key,
    required this.teamCard,
    this.isCurrentlyClockedIn = false,
    this.elapsedTime,
    this.startTime,
    this.onClockIn,
    this.onClockOut,
    this.userRole,
    this.index = 0,
  });

  @override
  State<EnhancedAnimatedTeamCard> createState() =>
      _EnhancedAnimatedTeamCardState();
}

class _EnhancedAnimatedTeamCardState extends State<EnhancedAnimatedTeamCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  Timer? _timer;
  Timer? _uiTicker;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();

    // Initialize flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    if (widget.isCurrentlyClockedIn) {
      _pulseController.repeat(reverse: true);
    }
    _slideController.forward();
    _startUiTicker();
  }

  @override
  void didUpdateWidget(EnhancedAnimatedTeamCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCurrentlyClockedIn && !oldWidget.isCurrentlyClockedIn) {
      _pulseController.repeat(reverse: true);
      _startUiTicker();
    } else if (!widget.isCurrentlyClockedIn && oldWidget.isCurrentlyClockedIn) {
      _pulseController.stop();
      _pulseController.reset();
      _uiTicker?.cancel();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    _uiTicker?.cancel();
    super.dispose();
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    if (widget.isCurrentlyClockedIn) {
      _uiTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  Color _getCardTypeColor() {
    final cardType = widget.teamCard.cardType?.toLowerCase() ?? '';
    switch (cardType) {
      case 'announcement':
        return Colors.blue;
      case 'guideline':
        return Colors.green;
      case 'process':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCardTypeText() {
    final cardType = widget.teamCard.cardType?.toLowerCase() ?? '';
    switch (cardType) {
      case 'announcement':
        return 'Announcement';
      case 'guideline':
        return 'Guideline';
      case 'process':
        return 'Process';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Info';
    }
  }

  Color _getStatusColor() {
    if (widget.isCurrentlyClockedIn) {
      return _getCardTypeColor();
    }
    return widget.teamCard.teamCardStatus == 1 ? Colors.green : Colors.grey;
  }

  String _getStatusText() {
    if (widget.isCurrentlyClockedIn) {
      return 'Active';
    }
    return widget.teamCard.teamCardStatus == 1 ? 'Active' : 'Inactive';
  }

  String _getTimeElapsed() {
    if (widget.isCurrentlyClockedIn && widget.startTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(widget.startTime!);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '00:00:00';
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * widget.index),
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: ResponsiveUtils.getResponsiveMargin(
          context,
          mobile: const EdgeInsets.all(6),
          tablet: const EdgeInsets.all(8),
          desktop: const EdgeInsets.all(12),
        ),
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            final flipValue = isShowingFront
                ? _flipAnimation.value
                : 1 - _flipAnimation.value;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(flipValue * 3.14159),
              child: isShowingFront ? _buildFrontSide() : _buildBackSide(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrentlyClockedIn ? _pulseAnimation.value : 1.0,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: _flipCard,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: ResponsiveUtils.getResponsiveSize(
                    context,
                    mobile: 200,
                    tablet: 220,
                    desktop: 240,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  border: Border.all(
                    color: widget.isCurrentlyClockedIn
                        ? _getCardTypeColor()
                        : Theme.of(context).dividerColor.withOpacity(0.15),
                    width: widget.isCurrentlyClockedIn ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: ResponsiveUtils.getResponsivePadding(
                    context,
                    mobile: const EdgeInsets.all(6),
                    tablet: const EdgeInsets.all(8),
                    desktop: const EdgeInsets.all(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with type badge and status
                      _buildHeader(),

                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: 4.0,
                          tablet: 5.0,
                          desktop: 6.0,
                        ),
                      ),

                      // Card name
                      _buildCardName(),

                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        ),
                      ),

                      // Tags row
                      _buildTagsRow(),

                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        ),
                      ),

                      // Description container (compact)
                      if (widget.teamCard.cardDescription?.isNotEmpty == true)
                        _buildCompactDescription(),

                      // Time tracking container (compact)
                      if (widget.isCurrentlyClockedIn)
                        _buildCompactTimeTracking(),

                      // Team type container (compact)
                      _buildCompactTeamType(),

                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        ),
                      ),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Type badge
        Container(
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            mobile: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            tablet: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            desktop: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          decoration: BoxDecoration(
            color: _getCardTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(
                context,
                mobile: 4.0,
                tablet: 6.0,
                desktop: 8.0,
              ),
            ),
          ),
          child: Text(
            _getCardTypeText(),
            style: TextStyle(
              color: _getCardTypeColor(),
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(
          width: ResponsiveUtils.getResponsiveSpacing(
            context,
            mobile: 4.0,
            tablet: 6.0,
            desktop: 8.0,
          ),
        ),

        // Status badge
        Container(
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            mobile: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            tablet: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            desktop: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(
                context,
                mobile: 4.0,
                tablet: 6.0,
                desktop: 8.0,
              ),
            ),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const Spacer(),

        // Flip button
        IconButton(
          onPressed: _flipCard,
          icon: Icon(
            Icons.info_outline,
            size: ResponsiveUtils.getResponsiveIconSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildCardName() {
    return Text(
      widget.teamCard.cardName,
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(
          context,
          mobile: 13,
          tablet: 14,
          desktop: 15,
        ),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTagsRow() {
    return Row(
      children: [
        // Priority indicator
        Container(
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            mobile: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            tablet: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            desktop: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          decoration: BoxDecoration(
            color: widget.teamCard.cardType == 'urgent'
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(
                context,
                mobile: 4.0,
                tablet: 6.0,
                desktop: 8.0,
              ),
            ),
          ),
          child: Text(
            widget.teamCard.cardType == 'urgent' ? 'High Priority' : 'Normal',
            style: TextStyle(
              color: widget.teamCard.cardType == 'urgent'
                  ? Colors.red
                  : Colors.grey,
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 9,
                tablet: 10,
                desktop: 11,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDescription() {
    return Text(
      widget.teamCard.cardDescription!,
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[300]
            : Colors.grey[600],
        fontSize: ResponsiveUtils.getResponsiveFontSize(
          context,
          mobile: 11,
          tablet: 12,
          desktop: 13,
        ),
        fontWeight: FontWeight.w400,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: widget.isCurrentlyClockedIn ? null : widget.onClockIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCardTypeColor(),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
              ),
            ),
            child: Text(
              widget.isCurrentlyClockedIn ? 'Active' : 'Punch In',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 11,
                  tablet: 12,
                  desktop: 13,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.isCurrentlyClockedIn) ...[
          SizedBox(
            width: ResponsiveUtils.getResponsiveSpacing(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            ),
          ),
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onClockOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),
                ),
              ),
              child: Text(
                'Punch Out',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTimeTracking() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: ResponsiveUtils.getResponsiveIconSize(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
          color: Colors.blue[600],
        ),
        SizedBox(
          width: ResponsiveUtils.getResponsiveSpacing(
            context,
            mobile: 4.0,
            tablet: 5.0,
            desktop: 6.0,
          ),
        ),
        Text(
          'Duration: ${_formatDuration(_getElapsedTime())}',
          style: TextStyle(
            color: Colors.blue[600],
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTeamType() {
    return Row(
      children: [
        Icon(
          Icons.group,
          size: ResponsiveUtils.getResponsiveIconSize(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[300]
              : Colors.grey[600],
        ),
        SizedBox(
          width: ResponsiveUtils.getResponsiveSpacing(
            context,
            mobile: 4.0,
            tablet: 5.0,
            desktop: 6.0,
          ),
        ),
        Text(
          'Team: ${widget.teamCard.teamType ?? 'All Teams'}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[600],
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Duration _getElapsedTime() {
    if (widget.startTime != null) {
      return DateTime.now().difference(widget.startTime!);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.blue[900]?.withOpacity(0.3)
            : Colors.blue[50],
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: ResponsiveUtils.getResponsiveSpacing(
              context,
              mobile: 8.0,
              tablet: 10.0,
              desktop: 12.0,
            ),
            offset: Offset(
                0,
                ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                )),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSpacing(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back side header
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: ResponsiveUtils.getResponsiveIconSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                  color: Colors.blue[600],
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                Text(
                  'Card Details',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 17,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _flipCard,
                  icon: Icon(
                    Icons.close,
                    size: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),

            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),

            // Card details
            _buildDetailRow('Card ID', widget.teamCard.teamCardId),
            _buildDetailRow('Card Type', _getCardTypeText()),
            _buildDetailRow(
                'Team Type', widget.teamCard.teamType ?? 'All Teams'),
            _buildDetailRow('Status', _getStatusText()),
            if (widget.isCurrentlyClockedIn)
              _buildDetailRow('Time Elapsed', _getTimeElapsed()),

            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),

            // Full description
            if (widget.teamCard.cardDescription?.isNotEmpty == true) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              Text(
                widget.teamCard.cardDescription!,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSpacing(
          context,
          mobile: 6.0,
          tablet: 8.0,
          desktop: 10.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.getResponsiveSpacing(
              context,
              mobile: 80.0,
              tablet: 90.0,
              desktop: 100.0,
            ),
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
