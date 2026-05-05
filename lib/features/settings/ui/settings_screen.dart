import 'package:flutter/material.dart';
import 'package:trip_central/features/settings/services/settings_service.dart';
import 'package:trip_central/features/auth/ui/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingPassword = false;

  // State for the inline form
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isEditingName = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _settingsService.getCurrentProfile();
      setState(() {
        _profile = profile;
        _nameController.text = profile['display_name'] ?? '';
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDisplayName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _settingsService.updateDisplayName(
        newName: _nameController.text,
        currentPassword: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Display name updated successfully!')));
        setState(() {
          _isEditingName = false;
          _passwordController.clear();
        });
        _fetchProfile(); // Refresh to show new data natively
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    try {
      await _settingsService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
        setState(() {
          _isEditingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating password: $e')));
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _settingsService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileSection(theme),
                const SizedBox(height: 16),
                _buildPasswordSection(theme),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    backgroundColor: theme.colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Display Name', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_profile?['display_name'] ?? 'Not set'),
            trailing: IconButton(
              icon: Icon(_isEditingName ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditingName = !_isEditingName;
                  if (!_isEditingName) {
                    _passwordController.clear();
                    _nameController.text = _profile?['display_name'] ?? '';
                  }
                });
              },
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isEditingName ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'New Display Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password to Verify',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required to confirm changes';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveDisplayName,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.lock)),
            title: const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Update your password'),
            trailing: IconButton(
              icon: Icon(_isEditingPassword ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditingPassword = !_isEditingPassword;
                  if (!_isEditingPassword) {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                  }
                });
              },
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isEditingPassword ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required to confirm changes';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSavingPassword ? null : _savePassword,
                        child: _isSavingPassword
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

