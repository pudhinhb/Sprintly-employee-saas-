import 'package:flutter/material.dart';
import '../../helpers/common_colors.dart';
import '../../model/team_sync_conversation.dart';

/// Dialog for creating a new group chat
class CreateGroupDialog extends StatefulWidget {
  final List<TeamSyncUser> availableUsers;

  const CreateGroupDialog({super.key, required this.availableUsers});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final List<TeamSyncUser> _selectedUsers = [];
  List<TeamSyncUser> _filteredUsers = [];
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.availableUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.availableUsers;
      } else {
        _filteredUsers = widget.availableUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              (user.designation?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _toggleUser(TeamSyncUser user) {
    setState(() {
      if (_selectedUsers.any(
        (u) => u.id == user.id && u.userType == user.userType,
      )) {
        _selectedUsers.removeWhere(
          (u) => u.id == user.id && u.userType == user.userType,
        );
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isSelected(TeamSyncUser user) {
    return _selectedUsers.any(
      (u) => u.id == user.id && u.userType == user.userType,
    );
  }

  void _createGroup() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'participants': _selectedUsers,
      'isPublic': _isPublic,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = CommonColors.getTextColor(context);
    final secondaryTextColor = primaryTextColor.withOpacity(0.6);
    final surfaceColor = CommonColors.getCardColor(context);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CommonColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group_add_rounded,
                    color: CommonColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create New Group',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Group Name
            Text(
              'Group Name *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(fontSize: 14, color: primaryTextColor),
                decoration: InputDecoration(
                  hintText: 'Enter group name...',
                  hintStyle: TextStyle(fontSize: 14, color: secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description (optional)
            Text(
              'Description (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _descriptionController,
                style: TextStyle(fontSize: 14, color: primaryTextColor),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a description...',
                  hintStyle: TextStyle(fontSize: 14, color: secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Group Type (Public/Private)
            Text(
              'Group Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Private option
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPublic = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_isPublic
                            ? CommonColors.primary.withOpacity(0.1)
                            : isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              !_isPublic ? CommonColors.primary : borderColor,
                          width: !_isPublic ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: !_isPublic
                                ? CommonColors.primary
                                : secondaryTextColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !_isPublic
                                        ? CommonColors.primary
                                        : primaryTextColor,
                                  ),
                                ),
                                Text(
                                  'Admin adds members',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Public option
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPublic = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isPublic
                            ? CommonColors.primary.withOpacity(0.1)
                            : isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isPublic ? CommonColors.primary : borderColor,
                          width: _isPublic ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.public,
                            color: _isPublic
                                ? CommonColors.primary
                                : secondaryTextColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Public',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isPublic
                                        ? CommonColors.primary
                                        : primaryTextColor,
                                  ),
                                ),
                                Text(
                                  'Anyone can join',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selected participants
            if (_selectedUsers.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Selected (${_selectedUsers.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedUsers.clear()),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final user = _selectedUsers[index];
                    return Chip(
                      label: Text(user.name.split(' ').first),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleUser(user),
                      backgroundColor: CommonColors.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: CommonColors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Search participants
            Text(
              'Add Participants',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 14, color: primaryTextColor),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(fontSize: 14, color: secondaryTextColor),
                  prefixIcon: Icon(
                    Icons.search,
                    color: secondaryTextColor,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected = _isSelected(user);
                  return _UserSelectTile(
                    user: user,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => _toggleUser(user),
                  );
                },
              ),
            ),

            // Create Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CommonColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Create Group',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSelectTile extends StatelessWidget {
  final TeamSyncUser user;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _UserSelectTile({
    required this.user,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = CommonColors.getTextColor(context);
    final secondaryTextColor = primaryTextColor.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? CommonColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? CommonColors.primary : secondaryTextColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  if (user.designation != null)
                    Text(
                      user.designation!,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.userType == 'Admin'
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.userType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: user.userType == 'Admin' ? Colors.purple : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = user.name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    final colorIndex = user.name.length % colors.length;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[colorIndex], colors[colorIndex].withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
