import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../strategies/auth_strategy.dart';
import '../../home/ui/home_screen.dart';

enum AuthMode { login, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  AuthMode _authMode = AuthMode.login;
  late AuthStrategy _strategy;

  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _strategy = LoginStrategy();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _onModeChanged(Set<AuthMode> selected) {
    if (selected.isEmpty) return;
    setState(() {
      _authMode = selected.first;
      _strategy = _authMode == AuthMode.login ? LoginStrategy() : SignUpStrategy();
      // Clear secondary fields
      _usernameController.clear();
      _displayNameController.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _strategy.execute(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        displayName: _displayNameController.text,
      );

      if (!mounted) return;

      if (_authMode == AuthMode.signUp) {
        // App expects email confirmation ON in settings config.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please check your email to verify your account.')),
        );
        _onModeChanged({AuthMode.login}); // Slide back to login seamless!
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );

        // Push Replacement directly to HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database error: ${e.message}'), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _strategy.title,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Seamless Segmented Selector for Mode
                SegmentedButton<AuthMode>(
                  segments: const [
                    ButtonSegment(value: AuthMode.login, label: Text('Log In')),
                    ButtonSegment(value: AuthMode.signUp, label: Text('Sign Up')),
                  ],
                  selected: {_authMode},
                  onSelectionChanged: _onModeChanged,
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_authMode),
                      children: _strategy.buildFields(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        usernameController: _usernameController,
                        displayNameController: _displayNameController,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: _submitForm,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(_strategy.submitButtonText, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

