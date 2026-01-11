import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abhira/Dashboard/ContactScreens/phonebook_view.dart';
import 'package:abhira/design_system.dart';

class MyContactsScreen extends StatefulWidget {
  const MyContactsScreen({super.key});

  @override
  _MyContactsScreenState createState() => _MyContactsScreenState();
}

class _MyContactsScreenState extends State<MyContactsScreen> {
  List<String> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  /// Load saved contacts
  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = prefs.getStringList("numbers") ?? [];

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Delete contact
  Future<void> _deleteContact(int index) async {
    try {
      final contactName = _contacts[index].split("***")[0];

      setState(() => _contacts.removeAt(index));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("numbers", _contacts);

      Fluttertoast.showToast(
        msg: "$contactName removed",
        backgroundColor: Colors.red,
      );
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      Fluttertoast.showToast(
        msg: "Error deleting contact",
        backgroundColor: Colors.red,
      );
    }
  }

  /// Delete all contacts
  Future<void> _deleteAllContacts() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Contacts?'),
        content: const Text(
          'Are you sure you want to delete all emergency contacts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() => _contacts.clear());

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove("numbers");

              Fluttertoast.showToast(
                msg: "All contacts deleted",
                backgroundColor: Colors.red,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  /// Call contact
  Future<void> _callContact(String number) async {
    try {
      // Check if call permission is granted
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
      }

      if (status.isGranted) {
        // Implement call functionality using url_launcher
        final url = 'tel:$number';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          Fluttertoast.showToast(msg: "Calling $number...");
        } else {
          Fluttertoast.showToast(
            msg: "Could not launch call",
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Call permission is required to make calls",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Error calling contact: $e');
      Fluttertoast.showToast(
        msg: "Failed to make call",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "SOS Contacts",
          style: AppTypography.h2.copyWith(
            color: AppColors.lightText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_contacts.isNotEmpty)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.lightText),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.delete_sweep,
                        color: AppColors.destructive),
                    title: const Text('Delete All'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteAllContacts();
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PhoneBook()),
          ).then((_) => _loadContacts());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text(' Add Contact'),
      ),
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

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 100, color: AppColors.darkGray),
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              'No Emergency Contacts',
              style: AppTypography.h3.copyWith(
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxxLarge),
              child: Text(
                'Add trusted contacts who will be notified in case of emergency',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.darkGray),
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneBook()),
                ).then((_) => _loadContacts());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add First Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxLarge,
                    vertical: AppSpacing.medium),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with instruction
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  indent: AppSpacing.xLarge,
                  endIndent: AppSpacing.small,
                  color: AppColors.gray,
                ),
              ),
              Text(
                "Swipe left to delete",
                style: AppTypography.caption.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
              Expanded(
                child: Divider(
                  indent: AppSpacing.small,
                  endIndent: AppSpacing.xLarge,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),

        // Contacts list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadContacts,
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final parts = _contacts[index].split("***");
                final name = parts.isNotEmpty ? parts[0] : "Unknown";
                final number = parts.length > 1 ? parts[1] : "No number";

                return Slidable(
                  key: ValueKey(_contacts[index]),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _deleteContact(index),
                        backgroundColor: AppColors.destructive,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                        vertical: AppSpacing.xSmall),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        number,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.darkGray),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.primary),
                        onPressed: () => _callContact(number),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }
}
