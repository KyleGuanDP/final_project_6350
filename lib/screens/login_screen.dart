import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'browse_posts_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode { login, register }

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入 Email 和 Password')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (_mode == AuthMode.login) {
        // 登录
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // 注册
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      // ✅ 登录/注册成功后，直接進入主頁，清空導航棧
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BrowsePostsScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Auth error: ${e.code}';
      if (e.code == 'user-not-found') {
        message = '帳號不存在，請先註冊';
      } else if (e.code == 'wrong-password') {
        message = '密碼錯誤';
      } else if (e.code == 'email-already-in-use') {
        message = '這個 email 已經被註冊過了';
      } else if (e.code == 'weak-password') {
        message = '密碼太弱（至少 6 位）';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/Password 尚未在 Firebase Console 啟用';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('未知錯誤: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return Scaffold(
      appBar: AppBar(title: const Text('HyperGarageSale Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLogin ? 'Login with Email' : 'Register New Account',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Text(isLogin ? 'Login' : 'Register'),
                  ),
                ),
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(isLogin ? '還沒有帳號？點這裡註冊' : '已有帳號？點這裡登入'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
