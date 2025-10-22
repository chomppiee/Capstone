import 'package:flutter/material.dart';
import 'package:segregate1/Authentication/Loginpage.dart';
import 'package:segregate1/Authentication/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _agreedToTerms = false;
  bool _showTermsError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _signUp() async {
    setState(() {
      _showTermsError = !_agreedToTerms;
    });

    if (_formKey.currentState!.validate() && _agreedToTerms) {
      final user = await _auth.createUserWithEmailAndPassword(
        _emailController.text,
        _confirmPasswordController.text,
      );

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullname': _nameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'points':          0,                     // ← initialize points here
          'events_attended': 0,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Try again.')),
        );
      }
    }
  }

  /// Password Validation Function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
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
          children: [
            Container(
              height: 250,
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
                    'Create an Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Join us in building a greener Canumay East!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
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
                      children: [
                        _buildTextField(_nameController, 'Full Name'),
                        _buildTextField(_usernameController, 'Username'),
                        _buildTextField(_addressController, 'Address'),
                        Padding(
  padding: const EdgeInsets.only(bottom: 15),
  child: TextFormField(
    controller: _emailController,
    decoration: InputDecoration(
      labelText: 'Email Address',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your email address';
      }
      // Email format validation
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
      return null;
    },
  ),
),

                        _buildPasswordField(_passwordController, 'Password'),
                        _buildPasswordField(_confirmPasswordController, 'Confirm Password', isConfirm: true),

                        /// Checkbox with Clickable Terms & Policy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (bool? value) {
                                setState(() {
                                  _agreedToTerms = value!;
                                  _showTermsError = false;
                                });
                              },
                            ),
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                children: [
                                  const Text('I agree to the '),
                                  GestureDetector(
                                    onTap: () {
                                    _showPrivacyPolicy(context);
                                    },
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF1E88E5),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(' & '),
                                  GestureDetector(
                                    onTap: () {
                                      _showTermsAndConditions(context);
                                    },
                                    child: const Text(
                                      'Terms & Conditions',
                                      style: TextStyle(
                                        color: Color(0xFF1E88E5),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_showTermsError)
                          const Text('You must agree to continue.', style: TextStyle(color: Colors.red)),

                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _signUp,
                            child: const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standard Text Field UI
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
      ),
    );
  }

  /// Password Field with Toggle Visibility
  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(isConfirm ? (_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility)
                : (_obscurePassword ? Icons.visibility_off : Icons.visibility)),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              });
            },
          ),
        ),
        validator: isConfirm ? (value) => value != _passwordController.text ? 'Passwords do not match' : null : _validatePassword,
      ),
    );
  }
}
