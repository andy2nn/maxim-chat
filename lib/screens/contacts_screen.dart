import 'package:flutter/material.dart';
import '../data/models/user.dart';

class ContactsScreen extends StatefulWidget {
  final List<User> friends;
  final Future<void> Function(List<User> selectedUsers, String? groupName)
  onSelect;

  const ContactsScreen({
    super.key,
    required this.friends,
    required this.onSelect,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<User> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final isGroup = selectedUsers.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Выберите участников')),
      body: ListView.builder(
        itemCount: widget.friends.length,
        itemBuilder: (context, index) {
          final user = widget.friends[index];
          final isSelected = selectedUsers.contains(user);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: user.photoBase64 != null ? null : Text(user.username[0]),
            ),
            title: Text(user.username),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedUsers.remove(user);
                } else {
                  selectedUsers.add(user);
                }
              });
            },
          );
        },
      ),
      floatingActionButton: selectedUsers.isEmpty
          ? null
          : FloatingActionButton.extended(
              label: Text(isGroup ? 'Создать группу' : 'Создать чат'),
              icon: const Icon(Icons.chat),
              onPressed: () async {
                String? groupName;
                if (isGroup) {
                  groupName = await _showGroupNameDialog();
                  if (groupName == null || groupName.trim().isEmpty) return;
                }
                await widget.onSelect(selectedUsers, groupName?.trim());
              },
            ),
    );
  }

  Future<String?> _showGroupNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название группы'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите название группы',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
