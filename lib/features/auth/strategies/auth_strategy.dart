import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Strategy Design Pattern to handle structural and behavioral differences
/// between Sign Up and Login.
abstract class AuthStrategy {
  String get title;
  String get submitButtonText;

  List<Widget> buildFields({
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController usernameController,
    required TextEditingController displayNameController,
  });

  Future<void> execute({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });
}

class LoginStrategy implements AuthStrategy {
  @override
  String get title => 'Welcome Back';

  @override
  String get submitButtonText => 'Login';

  @override
  List<Widget> buildFields({
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController usernameController,
    required TextEditingController displayNameController,
  }) {
    return [
      TextFormField(
        controller: emailController,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
        keyboardType: TextInputType.emailAddress,
        validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: passwordController,
        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
        obscureText: true,
        validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
      ),
    ];
  }

  @override
  Future<void> execute({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    await AuthService.instance.login(email.trim(), password);
  }
}

class SignUpStrategy implements AuthStrategy {
  @override
  String get title => 'Create an Account';

  @override
  String get submitButtonText => 'Sign Up';

  @override
  List<Widget> buildFields({
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController usernameController,
    required TextEditingController displayNameController,
  }) {
    return [
      TextFormField(
        controller: emailController,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
        keyboardType: TextInputType.emailAddress,
        validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: passwordController,
        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
        obscureText: true,
        validator: (value) => (value != null && value.length < 6) ? 'Min 6 characters' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: usernameController,
        decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
            helperText: 'Must be unique (3-30 lowercase characters)',
        ),
        validator: (value) => (value == null || value.length < 3) ? 'Min 3 characters' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: displayNameController,
        decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.badge)),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    ];
  }

  @override
  Future<void> execute({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    await AuthService.instance.signUp(
      email: email.trim(),
      password: password,
      username: username.trim().toLowerCase(),
      displayName: displayName.trim(),
    );
  }
}


