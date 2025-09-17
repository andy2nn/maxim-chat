import 'package:flutter/material.dart';
import '../data/models/user.dart';

class ContactsScreen extends StatefulWidget {
  final void Function(List<User>) onSelect;

  const ContactsScreen({super.key, required this.onSelect});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<User> allUsers = []; // Загрузи из репозитория
  final List<User> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите участников'),
        actions: [
          TextButton(
            onPressed: () => widget.onSelect(selectedUsers),
            child: const Text('Создать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];
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
                if (isSelected)
                  selectedUsers.remove(user);
                else
                  selectedUsers.add(user);
              });
            },
          );
        },
      ),
    );
  }
}
