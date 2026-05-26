import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webnox_taskops/model/team_card_model.dart';
import 'package:webnox_taskops/utils/responsive_utils.dart';

class AnimatedTeamCard extends StatefulWidget {
  final TeamCard teamCard;
  final bool isCurrentlyClockedIn;
  final Duration? elapsedTime;
  final DateTime? startTime;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;
  final String? userRole;

  const AnimatedTeamCard({
    super.key,
    required this.teamCard,
    this.isCurrentlyClockedIn = false,
    this.elapsedTime,
    this.startTime,
    this.onClockIn,
    this.onClockOut,
    this.userRole,
  });

  @override
  State<AnimatedTeamCard> createState() => _AnimatedTeamCardState();
}

class _AnimatedTeamCardState extends State<AnimatedTeamCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Start pulse animation if clocked in
    if (widget.isCurrentlyClockedIn) {
      _pulseController.repeat(reverse: true);
    }

    // Start UI ticker for live updates
    _startUiTicker();
  }

  @override
  void didUpdateWidget(AnimatedTeamCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update pulse animation based on clock status
    if (widget.isCurrentlyClockedIn && !oldWidget.isCurrentlyClockedIn) {
      _pulseController.repeat(reverse: true);
      _startUiTicker(); // Start ticker when clocked in
    } else if (!widget.isCurrentlyClockedIn && oldWidget.isCurrentlyClockedIn) {
      _pulseController.stop();
      _pulseController.reset();
      _uiTicker?.cancel(); // Stop ticker when clocked out
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    _uiTicker?.cancel();
    super.dispose();
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    // Only start ticker if currently clocked in
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_flipAnimation.value * 3.14159),
          child: _flipAnimation.value < 0.5
              ? _buildFrontSide()
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: _buildBackSide(),
                ),
        );
      },
    );
  }

  Widget _buildFrontSide() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrentlyClockedIn ? _pulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
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
                  // Header with card type and flip button
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getResponsiveSpacing(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                          vertical: ResponsiveUtils.getResponsiveSpacing(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: _getCardTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveBorderRadius(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
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
                      const Spacer(),
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
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),

                  // Card name
                  Text(
                    widget.teamCard.cardName,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),

                  // Card description
                  if (widget.teamCard.cardDescription?.isNotEmpty == true) ...[
                    Text(
                      widget.teamCard.cardDescription!,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(
                        context,
                        mobile: 8.0,
                        tablet: 10.0,
                        desktop: 12.0,
                      ),
                    ),
                  ],

                  // Team type
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: ResponsiveUtils.getResponsiveIconSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      SizedBox(
                        width: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: 4.0,
                          tablet: 6.0,
                          desktop: 8.0,
                        ),
                      ),
                      Text(
                        widget.teamCard.teamType ?? 'All Teams',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.isCurrentlyClockedIn
                              ? null
                              : widget.onClockIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getCardTypeColor(),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                mobile: 10.0,
                                tablet: 12.0,
                                desktop: 14.0,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getResponsiveBorderRadius(
                                  context,
                                  mobile: 8.0,
                                  tablet: 10.0,
                                  desktop: 12.0,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            widget.isCurrentlyClockedIn ? 'Active' : 'Punch In',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
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
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
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
                                  mobile: 10.0,
                                  tablet: 12.0,
                                  desktop: 14.0,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getResponsiveBorderRadius(
                                    context,
                                    mobile: 8.0,
                                    tablet: 10.0,
                                    desktop: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Punch Out',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
            _buildDetailRow('Status',
                widget.teamCard.teamCardStatus == 1 ? 'Active' : 'Inactive'),

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
