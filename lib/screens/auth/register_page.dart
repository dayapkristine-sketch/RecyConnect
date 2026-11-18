import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/theme_toggle.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  UserRole _role = UserRole.household;
  IdType _idType = IdType.nationalId;
  UploadedDoc? _idDoc;
  UploadedDoc? _idBackDoc;
  UploadedDoc? _permitDoc;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _accepted = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _username,
      _email,
      _password,
      _confirm,
      _phone,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<UploadedDoc?> _pickDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true, // needed so the admin can view the file later
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    if (f.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that file.')),
        );
      }
      return null;
    }
    if (f.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is larger than 5 MB.')),
        );
      }
      return null;
    }
    return UploadedDoc(name: f.name, bytes: f.bytes!);
  }

  Widget _docButton(String label, UploadedDoc? doc, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(doc == null ? Icons.upload_file : Icons.check_circle),
      label: Text(
        doc == null ? label : doc.name,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4ADE80),
        side: const BorderSide(color: Color(0xFF4ADE80)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm the information first.')),
      );
      return;
    }
    if (_idDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach your valid ID.')),
      );
      return;
    }
    if (_idBackDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach the back side of your valid ID.'),
        ),
      );
      return;
    }
    if (_role == UserRole.junkShop && _permitDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach your business permit.')),
      );
      return;
    }
    final error = await context.read<AppProvider>().registerWithFirebase(
      fullName: _name.text,
      username: _username.text,
      email: _email.text,
      idType: _idType,
      password: _password.text,
      role: _role,
      phone: _phone.text,
      address: _address.text,
      idDocument: _idDoc!,
      idBackDocument: _idBackDoc!,
      permitDocument: _role == UserRole.junkShop ? _permitDoc : null,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.hourglass_top, color: Colors.orange, size: 42),
        title: const Text('Registration submitted'),
        content: const Text(
          'Your account is now pending administrator approval. You can log in after it has been approved.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                right: 12,
                top: 8,
                child: ThemeToggle(iconOnly: true),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Join RecyConnect and help make recycling easier in your community.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 22),
                            _input(
                              _name,
                              'Full name',
                              Icons.badge_outlined,
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _email,
                              'Email address',
                              Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Enter a valid email address'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _username,
                              'Username',
                              Icons.person_outline,
                              validator: (v) {
                                if (v == null || v.trim().length < 4) {
                                  return 'Use at least 4 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _phone,
                              'Contact number',
                              Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _address,
                              'Address / Location',
                              Icons.location_on_outlined,
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<UserRole>(
                              initialValue: _role,
                              dropdownColor: const Color(0xFF203629),
                              style: const TextStyle(color: Colors.white),
                              decoration: _decoration(
                                'Account type',
                                Icons.people_alt_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.household,
                                  child: Text('Household / Resident'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.collector,
                                  child: Text('Scrap Collector'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.junkShop,
                                  child: Text('Junk Shop Owner'),
                                ),
                              ],
                              onChanged: (v) => setState(
                                () => _role = v ?? UserRole.household,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<IdType>(
                              initialValue: _idType,
                              dropdownColor: const Color(0xFF203629),
                              style: const TextStyle(color: Colors.white),
                              decoration: _decoration(
                                'Valid ID type',
                                Icons.verified_user_outlined,
                              ),
                              items: IdType.values
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _idType = v ?? IdType.nationalId,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _password,
                              'Password',
                              Icons.lock_outline,
                              obscure: _hidePassword,
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              validator: (v) {
                                if (v == null ||
                                    v.length < 8 ||
                                    !v.contains(RegExp(r'[A-Z]')) ||
                                    !v.contains(RegExp(r'[0-9]'))) {
                                  return 'Use 8+ characters, one capital letter and one number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _input(
                              _confirm,
                              'Confirm password',
                              Icons.lock_reset_outlined,
                              obscure: _hideConfirm,
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _hideConfirm = !_hideConfirm,
                                ),
                                icon: Icon(
                                  _hideConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              validator: (v) => v != _password.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            _docButton('Attach valid ID', _idDoc, () async {
                              final d = await _pickDoc();
                              if (d != null) setState(() => _idDoc = d);
                            }),
                            const SizedBox(height: 10),
                            _docButton(
                              'Attach ID back side',
                              _idBackDoc,
                              () async {
                                final d = await _pickDoc();
                                if (d != null) setState(() => _idBackDoc = d);
                              },
                            ),
                            if (_role == UserRole.junkShop) ...[
                              const SizedBox(height: 10),
                              _docButton(
                                'Attach business permit',
                                _permitDoc,
                                () async {
                                  final d = await _pickDoc();
                                  if (d != null) {
                                    setState(() => _permitDoc = d);
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 4),
                            const Text(
                              'JPG, PNG, PDF or Word (DOC/DOCX), up to 5 MB. A clear photo of the document is preferred. Online document storage will be enabled later.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _accepted,
                              activeColor: const Color(0xFF4ADE80),
                              checkColor: Colors.black,
                              title: const Text(
                                'I confirm that the information I provided is correct.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              onChanged: (v) =>
                                  setState(() => _accepted = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                onPressed: _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ADE80),
                                  foregroundColor: const Color(0xFF102B1A),
                                ),
                                child: const Text(
                                  'SUBMIT REGISTRATION',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'This field is required' : null;

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: const Color(0xFF4ADE80)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
  );

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon).copyWith(suffixIcon: suffix),
    );
  }
}
