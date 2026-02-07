import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/auth_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
import 'package:lockedin_frontend/utils/network_helper.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  Future<void> _showNetworkDiagnosis(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Diagnosing Connection...'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    final diagnosis = await NetworkHelper.getDiagnosis();
    final message = await NetworkHelper.getConnectionIssueMessage();

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Diagnosis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Text(
                'Technical Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Internet: ${diagnosis['internetConnection'] ? '✓' : '✗'}'),
              Text('Server: ${diagnosis['serverConnection'] ? '✓' : '✗'}'),
              Text('API URL: ${diagnosis['apiBaseUrl']}'),
              if (diagnosis['serverMessage'] != null)
                Text('Details: ${diagnosis['serverMessage']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/forgetPass.png',
                      width: 259,
                      height: 259,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: const Text(
                        "Forget password",
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Don’t worry! it happens. Please enter the email that associate with your account",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 26),
                    ForgetPasswordForm(
                      onSubmit: (email) async {
                        // Handle forget password - send OTP
                        final result = await AuthService.sendOTP(email: email);
                        if (result['success']) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'OTP sent to your email'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.push('/OTP/${Uri.encodeComponent(email)}');
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to send OTP'),
                                backgroundColor: Colors.red,
                                action: SnackBarAction(
                                  label: 'Diagnose',
                                  onPressed: () async {
                                    await _showNetworkDiagnosis(context);
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgetPasswordForm extends StatefulWidget {
  final Future<void> Function(String email)? onSubmit;
  const ForgetPasswordForm({super.key, this.onSubmit});

  @override
  State<ForgetPasswordForm> createState() => _ForgetPasswordFormState();
}

class _ForgetPasswordFormState extends State<ForgetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  bool get isFormValid {
    return _emailController.text.isNotEmpty && !_isLoading;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await widget.onSubmit?.call(_emailController.text.trim());
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  !EmailValidator.validate(value)) {
                return "Please enter a valid email address";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          LongButton(
            text: _isLoading ? 'Sending...' : 'Get OTP',
            onPressed: isFormValid ? _handleSubmit : null,
          ),
        ],
      ),
    );
  }
}
