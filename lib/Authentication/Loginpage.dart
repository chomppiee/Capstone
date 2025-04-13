import 'package:flutter/material.dart';
import 'package:segregate1/Authentication/AdminPage.dart';
import 'package:segregate1/Authentication/Forgotpass.dart';
import 'package:segregate1/Authentication/auth_service.dart';
import 'package:segregate1/Widgets/Dashboard.dart';
import 'package:segregate1/Authentication/registration.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true; // State for password visibility

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  void _dashboard(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }


  void _login() async {
    // Check for admin credentials first.
    if (_email.text.trim() == "admin" && _password.text == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminPage()),
      );
      return;
    }
    // Otherwise, use your normal authentication.
    if (_formKey.currentState!.validate()) {
      final user = await _auth.loginUserWithEmailAndPassword(
        _email.text,
        _password.text,
      );

      if (user != null) {
        _dashboard(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

void _showPrivacyPolicy(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        height: 300,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: const Text("""
2.1 Data Collection and Usage

SegreGate collects personal data, such as names, contact details, and user activity, to provide efficient service. We use this data for:

- User authentication and account management.
- Facilitating donations and resource exchanges.
- Sending notifications and updates related to community activities.
- Improving app functionality and user experience.

2.2 Data Security

- We implement standard security measures to protect users' personal data from unauthorized access, alteration, or disclosure.
- Users must keep their login credentials confidential and immediately report any suspicious activity.
- SegreGate does not sell, rent, or share personal data with third parties for commercial purposes.

2.3 User Rights

- Users can update or delete their personal data by accessing their profile settings.
          """),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
}

void _showTermsAndConditions(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Terms and Conditions", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        height: 300,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: const Text("""
3.1 Eligibility

- Users must be at least 18 years old or have parental consent to use SegreGate.
- Users must be residents of Barangay Canumay West to participate in donations and exchanges.

3.2 Account Responsibilities

- Users must provide accurate information when registering.
- Any misuse, fraudulent activity, or violation of app policies may result in account suspension or termination.
- Users are responsible for all activities conducted through their accounts.

3.3 Acceptable Use

Users agree to:
- Use the platform solely for waste segregation, recycling, and resource-sharing purposes.
- Refrain from posting offensive, harmful, or illegal content.
- Respect all transactions and commitments made through the app.
- Ensure that listed items are in usable condition and meet donation guidelines.

3.4 Prohibited Activities

Users are prohibited from:
- Posting or exchanging prohibited items, such as hazardous materials, weapons, illegal substances, or stolen goods.
- Engaging in fraudulent, deceptive, or harmful behavior within the platform.
- Harassing, threatening, or abusing other users.
- Attempting to compromise the security and integrity of the platform.
          """),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Sign in to your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Together for a Cleaner and Greener Canumay East',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                            labelText: 'Email address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value!;
                                      });
                                    },
                                  ),
                                  const Flexible(
                                    child: Text(
                                      'Remember me',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFF1E88E5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF1E88E5),
                            ),
                            onPressed: _login,
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 160),
            const Divider(thickness: 1, indent: 40, endIndent: 40),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showPrivacyPolicy(context);
                    },
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      _showTermsAndConditions(context);
                    },
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
