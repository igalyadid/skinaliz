import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';
import 'client_folder_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  List<Directory> _allClients = [];
  List<Directory> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final clients = await StorageService.getClients();
      if (mounted) {
        _allClients = clients;
        _filterClients(_searchController.text);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterClients(String query) {
    if (query.isEmpty) {
      _filteredClients = List.from(_allClients);
    } else {
      _filteredClients = _allClients
          .where((dir) => StorageService.getFolderName(dir.path)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _showAddClientDialog() async {
    final s = AppStrings.of(context);
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newClientTitle),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.clientNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close),
          ),
          IconButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await StorageService.createClient(name);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadClients();
              }
            },
            icon: const Icon(Icons.check, color: Color(0xFF008080)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.face_retouching_natural, color: Color(0xFF008080)),
            const SizedBox(width: 8),
            Text(s.appTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterClients,
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? Center(
                        child: Text(
                          s.noClientsMsg,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredClients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final clientDir = _filteredClients[index];
                          final clientName =
                              StorageService.getFolderName(clientDir.path);
                          final initial = clientName.isNotEmpty
                              ? clientName[0].toUpperCase()
                              : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF008080).withOpacity(0.15),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF008080),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(clientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClientFolderScreen(clientDir: clientDir),
                                ),
                              );
                              _loadClients();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
