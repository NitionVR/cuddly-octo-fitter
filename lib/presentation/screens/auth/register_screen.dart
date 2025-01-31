import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[ Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundStart,
              AppColors.backgroundEnd,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join FitQuest today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          Consumer<AuthViewModel>(
                            builder: (context, authViewModel, _) {
                              return AuthButton(
                                text: 'CREATE ACCOUNT',
                                isLoading: authViewModel.isLoading,
                                onPressed: () => _handleRegister(context),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Consumer<AuthViewModel>(
                            builder: (context, authViewModel, _) {
                              if (authViewModel.error != null) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    authViewModel.error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

        if (context.watch<AuthViewModel>().isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
    ]
    );
  }

  Future<void> _handleRegister(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authViewModel = context.read<AuthViewModel>();
        await authViewModel.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        // Wait for auth state to update
        await Future.delayed(const Duration(milliseconds: 500));

        if (authViewModel.isAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to create account. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        // Error will be displayed through the error widget in the UI
        // since we're using the viewModel's error state
      }
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password';
    }
    if (error.contains('operation-not-allowed')) {
      return 'Unable to register at this time. Please try again later';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    return 'Unable to create account. Please try again';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}