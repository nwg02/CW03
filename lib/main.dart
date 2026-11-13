
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

// Use the local Firebase emulators during testing.
const bool useFirebaseEmulators = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode && useFirebaseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(
      '10.0.2.2',
      9099,
    );

    FirebaseFirestore.instance.useFirestoreEmulator(
      '10.0.2.2',
      8080,
    );

    FirebaseFunctions.instance.useFunctionsEmulator(
      '10.0.2.2',
      5001,
    );
  }

  runApp(const MyApp());
}

// --------------------------------------------------
// MAIN APPLICATION
// --------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// --------------------------------------------------
// AUTHENTICATION GATE
// --------------------------------------------------

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Authentication error.'),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// --------------------------------------------------
// LOGIN AND REGISTRATION
// --------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage =
                'Email already registered.';
            break;

          case 'weak-password':
            _errorMessage =
                'Password is too weak.';
            break;

          case 'invalid-email':
            _errorMessage =
                'Invalid email address.';
            break;

          case 'invalid-credential':
          case 'wrong-password':
          case 'user-not-found':
            _errorMessage =
                'Incorrect email or password.';
            break;

          default:
            _errorMessage =
                'Authentication failed: ${e.code}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.amber,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _isLogin
                        ? 'Welcome Back!'
                        : 'Create an Account',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _isLoading ? null : _submit,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                _isLogin
                                    ? 'Sign In'
                                    : 'Register',
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'No account? Register here'
                          : 'Already have an account? Sign in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// HOME SCREEN
// --------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCompleting = false;
  bool _isHintLoading = false;

  String? _coachReply;

  final TextEditingController _questionController =
      TextEditingController();

  // ------------------------------------------------
  // COMPLETE CHALLENGE USING CLOUD FUNCTION
  // ------------------------------------------------

  Future<void> _completeChallenge() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('completeToday');

      final result = await callable.call({
        'challengeId': 'today',
      });

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) return;

      final alreadyCompleted =
          data['alreadyCompleted'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadyCompleted
                ? 'Already completed! No extra points awarded.'
                : 'Success! You earned 10 points and the First Quest badge!',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      String message = 'Reward error: ${e.code}';

      if (e.code == 'not-found') {
        message =
            'Reward function is not available.';
      } else if (e.code == 'unauthenticated') {
        message =
            'Please sign in to complete the challenge.';
      } else if (e.code == 'unavailable') {
        message =
            'Reward service unavailable. Try again.';
      } else if (e.message != null) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to complete challenge: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  // ------------------------------------------------
  // AI QUEST COACH
  // ------------------------------------------------

  Future<void> _getHint() async {
    final question = _questionController.text.trim();

    if (question.isEmpty || question.length > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a question between 1 and 300 characters.',
          ),
        ),
      );
      return;
    }

    if (_isHintLoading) return;

    setState(() {
      _isHintLoading = true;
      _coachReply = null;
    });

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('askQuestCoach');

      final result = await callable.call({
        'question': question,
      });

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) return;

      setState(() {
        _coachReply = data['reply'] as String? ??
            'No hint was returned.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'unauthenticated') {
          _coachReply =
              'Please sign in to use the Quest Coach.';
        } else if (e.code == 'not-found') {
          _coachReply =
              'Quest Coach is not available yet.';
        } else if (e.code == 'unavailable') {
          _coachReply =
              'Quest Coach is temporarily unavailable.';
        } else {
          _coachReply =
              'Coach error: ${e.code}. ${e.message ?? ""}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _coachReply = 'Unable to get a hint: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isHintLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // BUILD HOME SCREEN
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // Load today's challenge from Firestore
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('challenges')
            .doc('today')
            .snapshots(),

        builder: (context, challengeSnapshot) {
          if (challengeSnapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load challenge.',
              ),
            );
          }

          if (!challengeSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final challenge =
              challengeSnapshot.data!.data();

          if (challenge == null) {
            return const Center(
              child: Text(
                'No daily challenge found.',
              ),
            );
          }

          final title =
              challenge['title'] as String? ??
              'Daily Challenge';

          final prompt =
              challenge['prompt'] as String? ??
              'No prompt available.';

          // Read current user's progress
          return StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('progress')
                .doc('today')
                .snapshots(),

            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Unable to load progress.',
                  ),
                );
              }

              if (!progressSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final progress =
                  progressSnapshot.data!.data();

              final completed =
                  progress?['completed'] == true;

              final points =
                  (progress?['points'] as num?)
                          ?.toInt() ??
                      0;

              final badgeId =
                  progress?['badgeId'] as String?;

              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Welcome
                    const Icon(
                      Icons.emoji_events,
                      size: 70,
                      color: Colors.amber,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Welcome to Cloud Quest!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Signed in as ${user.email ?? user.uid}',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Today's Challenge
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Challenge",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              prompt,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // User Progress
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Your Progress',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Points: $points',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              completed
                                  ? 'Challenge Completed!'
                                  : 'Challenge Not Completed',
                            ),

                            const SizedBox(height: 10),

                            Text(
                              badgeId == null
                                  ? 'Badge: None'
                                  : 'Badge: $badgeId',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // AI Quest Coach
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'AI Quest Coach',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Need help with your challenge? '
                              'Ask the Quest Coach for a hint.',
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller:
                                  _questionController,
                              maxLength: 300,
                              maxLines: 3,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Ask for a hint',
                                hintText:
                                    'How should I approach this challenge?',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _isHintLoading
                                        ? null
                                        : _getHint,
                                icon: const Icon(
                                  Icons.lightbulb_outline,
                                ),
                                label: Text(
                                  _isHintLoading
                                      ? 'Thinking...'
                                      : 'Get Hint',
                                ),
                              ),
                            ),

                            if (_isHintLoading) ...[
                              const SizedBox(height: 16),
                              const Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            ],

                            if (_coachReply != null) ...[
                              const SizedBox(height: 16),

                              const Text(
                                'Quest Coach Response',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: Text(
                                  _coachReply!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Complete Challenge
                    FilledButton(
                      onPressed: _isCompleting
                          ? null
                          : _completeChallenge,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child: _isCompleting
                            ? const CircularProgressIndicator()
                            : Text(
                                completed
                                    ? 'Test Duplicate Completion'
                                    : 'Complete Challenge',
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
