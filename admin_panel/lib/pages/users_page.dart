import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/widgets/common.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.users(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> users = snapshot.data?.docs.map((d) => d.data()).toList() ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(title: "Users", subtitle: "${users.length} people signed up in the shopping app"),
            Expanded(
              child: snapshot.hasError
                  ? EmptyState(icon: Icons.lock_outline, text: "Could not load users:\n${snapshot.error}")
                  : !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                          ? const EmptyState(icon: Icons.people_outline, text: "No users yet")
                          : ListView(
                              padding: EdgeInsets.fromLTRB(pagePadding(context), 0, pagePadding(context), 28),
                              children: [
                                CardBox(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      for (var u in users)
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.strong(context),
                                            child: Text(
                                              "${u["Name"] ?? "?"}".isEmpty ? "?" : "${u["Name"]}"[0].toUpperCase(),
                                              style: TextStyle(color: AppColors.onStrong(context), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text("${u["Name"] ?? "-"}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: SelectableText("${u["Email"] ?? "-"}"),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        );
      },
    );
  }
}
