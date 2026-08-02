import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

/// Shows a sign-in icon when signed out, or the user's avatar (tap for a
/// sign-out menu) when signed in. Place in an AppBar's actions.
///
/// Cloud sync (and therefore sign-in) is currently only wired up on web, so
/// this stays a no-op StatelessWidget elsewhere - critically, that means the
/// Firebase-touching State below never even gets constructed on other
/// platforms, where Firebase.initializeApp() is never called.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return const _AccountButtonWeb();
  }
}

class _AccountButtonWeb extends StatefulWidget {
  const _AccountButtonWeb();

  @override
  State<_AccountButtonWeb> createState() => _AccountButtonWebState();
}

class _AccountButtonWebState extends State<_AccountButtonWeb> {
  final AuthService _auth = AuthService();
  final DbService _db = DbService();
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await _auth.signInWithGoogle();
      await _db.syncFromCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Signed in - your notes are now backed up'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (_busy) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          );
        }

        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Sign in with Google to back up your notes',
            onPressed: _signIn,
          );
        }

        return PopupMenuButton<String>(
          tooltip: 'Account',
          onSelected: (value) {
            if (value == 'sign_out') _signOut();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                user.email ?? 'Signed in',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'sign_out',
              child: Text('Sign out'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text((user.email ?? '?').substring(0, 1).toUpperCase())
                  : null,
            ),
          ),
        );
      },
    );
  }
}
