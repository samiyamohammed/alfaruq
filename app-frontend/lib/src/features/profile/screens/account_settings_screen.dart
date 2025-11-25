import 'package:al_faruk_app/src/features/profile/screens/change_password_screen.dart';
import 'package:al_faruk_app/src/features/profile/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:al_faruk_app/generated/app_localizations.dart'; // Import

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettings)), // Localized
      body: ListView(
        children: [
          SettingsListTile(
            icon: Icons.lock_outline,
            title: l10n.changePassword, // Localized
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ));
            },
          ),
          SettingsListTile(
            icon: Icons.credit_card,
            title: l10n.manageSubscription, // Localized
            onTap: () {/* TODO */},
          ),
          const Divider(),
          SettingsListTile(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount, // Localized
            color: Colors.red,
            onTap: () {/* TODO */},
          ),
        ],
      ),
    );
  }
}
