import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/screens/home_screen.dart';
import 'package:reuse_depot/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  const AuthScreen({Key? key}) : super(key: key);
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await auth.signIn(_emailController.text, _passwordController.text);
      } else {
        await auth.register(_emailController.text, _passwordController.text);
        // Navigate to home screen after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reuse Depot'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) => value!.isEmpty ? 'Please enter email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) => value!.isEmpty ? 'Please enter password' : null,
              ),
              SizedBox(height: 24),
              if (_isLoading)
                CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Login' : 'Register'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: Text(
                        _isLogin
                            ? 'Create new account'
                            : 'I already have an account',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
