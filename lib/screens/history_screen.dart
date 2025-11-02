import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/storage/history_storage.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';
import 'package:plagiarishield_sim/models/history_entry.dart';
import 'package:plagiarishield_sim/screens/report_screen.dart';
import 'package:plagiarishield_sim/widgets/bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

/// HistoryScreen - Displays all plagiarism check history of the active user.
/// Now supports selecting specific entries to delete.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> entries = [];
  bool isSelectionMode = false; // Tracks if user is selecting
  Set<String> selectedIds = {}; // Stores selected reportIds

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads all stored history for the active user
  Future<void> _loadHistory() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    final loadedReports = await HistoryStorage.instance.getUserHistory(userId);
    final loadedEntries = loadedReports.entries
        .map((e) => HistoryEntry.fromJson(e.value))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        entries = loadedEntries;
      });
    }
  }

  /// Deletes all stored history
  Future<void> _clearAllHistory() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🗑 Gradient trash icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFF4511E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Title
                Text(
                  'Clear All History?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 Content
                Text(
                  'This will permanently delete all your history records. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFB0BEC5)),
                          ),
                        ),
                        child:
                            const Text('Cancel', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete All
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFF4511E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Delete All',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      await HistoryStorage.instance.clearUserHistory(userId);

      setState(() {
        entries.clear();
        selectedIds.clear();
        isSelectionMode = false;
      });
    }
  }

  /// Deletes only selected entries
  Future<void> _confirmDeleteSelected() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🗑 Gradient trash icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFF4511E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),

                // 🔹 Title
                Text(
                  'Delete Selected Entries?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 Content
                Text(
                  'This action will permanently remove the selected history items. You can’t undo this.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFB0BEC5)),
                          ),
                        ),
                        child:
                            const Text('Cancel', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFF4511E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteSelectedEntries();
    }
  }

  /// Delete the currently selected entries (persistently + update UI)
  Future<void> _deleteSelectedEntries() async {
    if (selectedIds.isEmpty) return;

    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    try {
      // delete from persistent storage
      await HistoryStorage.instance.deleteReports(
        userId: userId,
        reportIds: selectedIds.toList(),
      );

      // update in-memory list & UI
      setState(() {
        entries.removeWhere((e) => selectedIds.contains(e.reportId));
        selectedIds.clear();
        isSelectionMode = false;
      });

      if (!mounted) return;
      // ---- BAGONG SNACKBAR ----
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Selected entries deleted',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor:
              const Color(0xFF43C5FC), // Kulay na bagay sa theme
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      // ---- BAGONG ERROR SNACKBAR ----
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Failed to delete entries',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43C5FC),
        centerTitle: true,
        title: Text(
          isSelectionMode
              ? '${selectedIds.length} Selected'
              : 'Recent Checks History',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    isSelectionMode = false;
                    selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Colors.white), // Tiniyak na puti ang icon
              tooltip: 'Delete Selected',
              onPressed: () async {
                await _confirmDeleteSelected();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_sweep,
                  color: Colors.white), // Tiniyak na puti ang icon
              tooltip: 'Clear All History',
              onPressed: _clearAllHistory,
            ),
        ],
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),

      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const Text(
                    'Your checked reports will appear here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final selected = selectedIds.contains(entry.reportId);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    // ---- BINAGO ANG KULAY DITO ----
                    color: selected
                        ? const Color(0xFF43C5FC).withOpacity(0.2)
                        : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      leading: isSelectionMode
                          ? Icon(
                              selected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              // ---- AT DITO ----
                              color: selected
                                  ? const Color(0xFF43C5FC)
                                  : Colors.grey,
                            )
                          : null,
                      title: Text(
                        entry.summary,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        entry.timestamp,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: isSelectionMode
                          ? null
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        if (isSelectionMode) {
                          setState(() {
                            if (selected) {
                              selectedIds.remove(entry.reportId);
                              if (selectedIds.isEmpty) {
                                isSelectionMode = false;
                              }
                            } else {
                              selectedIds.add(entry.reportId);
                            }
                          });
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                content: entry.source,
                                isFromHistory: true,
                                historyDataJson: entry
                                    .apiResponse, // Ipapasa ang buong response
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!isSelectionMode) {
                          setState(() {
                            isSelectionMode = true;
                            selectedIds.add(entry.reportId);
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

