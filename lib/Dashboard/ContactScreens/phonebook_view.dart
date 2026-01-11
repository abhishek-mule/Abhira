// ==================== PHONEBOOK SCREEN ====================
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhira/Dashboard/Dashboard.dart';
import 'package:abhira/animations/bottomAnimation.dart';
import 'package:abhira/design_system.dart';

class PhoneBook extends StatefulWidget {
  const PhoneBook({super.key});

  @override
  _PhoneBookState createState() => _PhoneBookState();
}

class _PhoneBookState extends State<PhoneBook> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final Set<String> _selectedContactIds = {};

  bool _isLoading = true;
  bool _hasPermission = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize contacts with permission check
  Future<void> _initializeContacts() async {
    setState(() => _isLoading = true);

    final contactPermissionStatus = await _requestContactPermission();
    final callPermissionGranted = await _checkCallPermission();

    if (contactPermissionStatus == PermissionStatus.granted) {
      if (callPermissionGranted) {
        await _loadContacts();
      } else {
        Fluttertoast.showToast(
          msg: "Call permission is required to make calls",
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
        await _loadContacts();
      }
    } else {
      _handlePermissionDenied(contactPermissionStatus);
    }

    setState(() => _isLoading = false);
  }

  /// Request contact permission
  Future<PermissionStatus> _requestContactPermission() async {
    var status = await Permission.contacts.status;

    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }

    setState(() => _hasPermission = status.isGranted);
    return status;
  }

  /// Check and request call permission
  Future<bool> _checkCallPermission() async {
    var status = await Permission.phone.status;

    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    return status.isGranted;
  }

  /// Load all contacts
  Future<void> _loadContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter out contacts without phone numbers
      final validContacts = contacts.where((c) => c.phones.isNotEmpty).toList();

      setState(() {
        _contacts = validContacts;
        _filteredContacts = validContacts;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      Fluttertoast.showToast(
        msg: "Failed to load contacts. Please try again.",
        backgroundColor: Colors.red,
      );
      // Retry loading contacts after a delay
      await Future.delayed(const Duration(seconds: 2));
      await _loadContacts();
    }
  }

  /// Search contacts
  void _searchContacts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredContacts = _contacts);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phoneMatch = contact.phones.any((phone) =>
            phone.number.replaceAll(RegExp(r'\D'), '').contains(query));
        return name.contains(lowerQuery) || phoneMatch;
      }).toList();
    });
  }

  /// Toggle contact selection
  void _toggleContact(Contact contact) {
    final contactId = contact.id;

    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });

    Fluttertoast.showToast(
      msg:
          "${_selectedContactIds.length} contact${_selectedContactIds.length != 1 ? 's' : ''} selected",
      backgroundColor: Colors.blue,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Save selected contacts
  Future<void> _saveContacts() async {
    if (_selectedContactIds.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select at least one contact",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> existingNumbers = prefs.getStringList("numbers") ?? [];
      int addedCount = 0;

      for (final contact in _contacts) {
        if (_selectedContactIds.contains(contact.id) &&
            contact.phones.isNotEmpty) {
          final name =
              contact.displayName.isNotEmpty ? contact.displayName : "Unknown";
          final number = _formatPhoneNumber(contact.phones.first.number);
          final entity = "$name***$number";

          if (!existingNumbers.contains(entity)) {
            existingNumbers.add(entity);
            addedCount++;
          }
        }
      }

      await prefs.setStringList("numbers", existingNumbers);

      Fluttertoast.showToast(
        msg:
            "$addedCount contact${addedCount != 1 ? 's' : ''} saved successfully",
        backgroundColor: Colors.green,
      );

      _goBack();
    } catch (e) {
      debugPrint('Error saving contacts: $e');
      Fluttertoast.showToast(
        msg: "Error saving contacts",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Format phone number
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return "";

    // Remove all non-numeric characters
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Handle different phone number formats
    if (cleaned.length >= 10) {
      // If starts with country code
      if (cleaned.length > 10 && !cleaned.startsWith('0')) {
        return '+$cleaned';
      }
      // If starts with 0, replace with country code (example: +92 for Pakistan)
      if (cleaned.startsWith('0')) {
        return '+92${cleaned.substring(1)}';
      }
      return '+$cleaned';
    }

    return phone; // Return original if can't format
  }

  /// Handle permission denied
  void _handlePermissionDenied(PermissionStatus status) {
    String message = "Contact permission denied";

    if (status.isPermanentlyDenied) {
      message =
          "Please enable contacts permission in settings to access your phonebook";
    } else if (status.isDenied) {
      message = "Contacts permission is required to access your phonebook";
    }

    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  /// Navigate back
  void _goBack() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Dashboard(pageIndex: 1)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white70),
            hintText: 'Search contacts...',
            hintStyle: TextStyle(color: Colors.black54),
          ),
          onChanged: _searchContacts,
        ),
        actions: [
          if (_selectedContactIds.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.large),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.xSmall),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.xxLarge),
                  ),
                  child: Text(
                    '${_selectedContactIds.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedContactIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveContacts,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.save),
              label: const Text('Save Contacts'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 80, color: AppColors.darkGray),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              'Contact Permission Required',
              style: AppTypography.h3.copyWith(color: AppColors.lightText),
            ),
            const SizedBox(height: AppSpacing.small),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxxLarge),
              child: Text(
                'Allow access to contacts to add emergency contacts',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.darkGray),
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            TextButton.icon(
              onPressed: () => _initializeContacts(),
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: Text('Retry',
                  style: AppTypography.body.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.darkGray),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              _searchController.text.isEmpty
                  ? 'No contacts found'
                  : 'No matching contacts',
              style: AppTypography.h3.copyWith(color: AppColors.darkGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredContacts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          final isSelected = _selectedContactIds.contains(contact.id);

          return WidgetAnimator(
            _buildContactTile(contact, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildContactTile(Contact contact, bool isSelected) {
    final name =
        contact.displayName.isNotEmpty ? contact.displayName : "Unknown";
    final phone =
        contact.phones.isNotEmpty ? contact.phones.first.number : "No phone";

    return Material(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? AppColors.primary : AppColors.gray,
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: AppTypography.body.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          phone,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.darkGray,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.circle_outlined, color: AppColors.darkGray),
        onTap: () => _toggleContact(contact),
      ),
    );
  }
}
