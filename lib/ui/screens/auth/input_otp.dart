import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/auth_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/utils/network_helper.dart';

class OTPScreen extends StatelessWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  Future<void> _showNetworkDiagnosis(BuildContext context, String email) async {
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
              const SizedBox(height: 16),
              Text('For email: $email', style: TextStyle(fontWeight: FontWeight.w500)),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Back Button
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios),
                    ),

                    const SizedBox(height: 16),

                    /// Image
                    Center(
                      child: Image.asset(
                        'assets/images/otp.png',
                        width: width * 0.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Title
                    const Text(
                      "Enter OTP",
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    Text(
                      "6 digit OTP has been sent to $email",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// OTP FORM
                    OTPForm(
                      email: email,
                      onSubmit: (otp) {
                        context.push(
                          '/reset-password/${Uri.encodeComponent(email)}/${Uri.encodeComponent(otp)}',
                        );
                      },
                      onResend: () async {
                        final result =
                            await AuthService.sendOTP(email: email);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    (result['success'] ? 'OTP sent successfully' : 'Failed to send OTP'),
                              ),
                              backgroundColor: result['success']
                                  ? Colors.green
                                  : Colors.red,
                              action: !result['success'] 
                                  ? SnackBarAction(
                                      label: 'Diagnose',
                                      onPressed: () async {
                                        await _showNetworkDiagnosis(context, email);
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OTPForm extends StatefulWidget {
  final String email;
  final void Function(String otp)? onSubmit;
  final Future<void> Function()? onResend;

  const OTPForm({
    super.key,
    required this.email,
    this.onSubmit,
    this.onResend,
  });

  @override
  State<OTPForm> createState() => _OTPFormState();
}

class _OTPFormState extends State<OTPForm> {
  static const int otpLength = 6;
  static const int resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = resendSeconds;
  bool _isResending = false;

  bool get isFormValid =>
      _controllers.every((c) => c.text.isNotEmpty);

  String get otpValue =>
      _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    for (var c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await widget.onResend?.call();
      _startCountdown();
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String _formatTime(int s) =>
      '00:${s.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = (screenWidth - 64) / otpLength;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          /// OTP INPUTS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(otpLength, (index) {
              return SizedBox(
                width: boxWidth.clamp(40, 56),
                height: 56,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => _onChanged(v, index),
                  validator: (v) =>
                      v == null || v.isEmpty ? '' : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          /// SUBMIT
          LongButton(
            text: 'Enter OTP',
            onPressed: isFormValid
                ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit?.call(otpValue);
                    }
                  }
                : null,
          ),

          const SizedBox(height: 16),

          /// RESEND
          OutlinedButton(
            onPressed:
                (_secondsLeft > 0 || _isResending)
                    ? null
                    : _handleResend,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: Text(
              _isResending
                  ? 'Sending...'
                  : _secondsLeft > 0
                      ? 'Resend OTP (${_formatTime(_secondsLeft)})'
                      : 'Resend OTP',
            ),
          ),
        ],
      ),
    );
  }
}
