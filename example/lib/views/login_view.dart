import 'package:flutter/material.dart';

import '../design.dart';
import '../push_model.dart';

/// The login screen. Signing in calls Ortto.instance.identify via
/// PushModel.signIn.
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.model});

  final PushModel model;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  final FocusNode _emailFocus = FocusNode();

  PushModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: model.email);
    _emailController.addListener(() {
      model.email = _emailController.text;
      setState(() {});
    });
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _hasSavedAccount => model.visibleRememberedLoginEmail.isNotEmpty;

  String get _submittedEmail => _hasSavedAccount
      ? model.visibleRememberedLoginEmail.trim()
      : _emailController.text.trim();

  bool get _isContinueDisabled =>
      model.isIdentifying || _submittedEmail.isEmpty;

  void _signIn() {
    if (_isContinueDisabled) return;
    _emailFocus.unfocus();
    // Ortto SDK: identify happens here. signIn calls Ortto.instance.identify
    // with this email — see PushModel.identify.
    model.signIn(_submittedEmail);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetCornerRadius = (size.width * 0.12).clamp(38.0, 48.0);

    return GestureDetector(
      onTap: _emailFocus.unfocus,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(child: _topArtwork()),
          _bottomSheet(sheetCornerRadius, bottomInset, keyboardInset),
        ],
      ),
    );
  }

  Widget _topArtwork() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Push Demo',
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 58,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Colors.white,
              // Flutter's blurRadius is tighter than SwiftUI's radius for the
              // same value, so soften and lift the shadow to match the native
              // demo's .shadow(radius: 14, y: 7).
              shadows: [
                Shadow(
                  color: AppColors.ink.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _providerBadge(),
        ],
      ),
    );
  }

  Widget _providerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 13, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'FCM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheet(
      double cornerRadius, double bottomInset, double keyboardInset) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 38,
        left: 28,
        right: 28,
        bottom: (keyboardInset > 0 ? keyboardInset : bottomInset) + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _hasSavedAccount ? 'Jump back in!' : 'Sign in',
              maxLines: 1,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: _hasSavedAccount
                  ? _savedAccount(model.visibleRememberedLoginEmail.trim())
                  : _emailField(),
            ),
            const SizedBox(height: 18),
            _continueButton(),
            if (_hasSavedAccount) ...[
              const SizedBox(height: 18),
              _useAnotherAccountButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emailField() {
    final isFocused = _emailFocus.hasFocus;
    return Column(
      key: const ValueKey('email-field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused
                  ? AppColors.lilac
                  : AppColors.ink.withValues(alpha: 0.22),
              width: isFocused ? 2 : 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _signIn(),
            cursorColor: AppColors.lilac,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Email address',
              hintStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.ink.withValues(alpha: 0.28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll log you in with your Ortto demo account.",
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ink.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }

  Widget _savedAccount(String email) {
    final displayName = _displayName(email);
    return SizedBox(
      key: const ValueKey('saved-account'),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lilac, Color(0xFF9438FA)],
              ),
            ),
            child: Text(
              _initials(displayName, email),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 38,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.ink.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    final disabled = _isContinueDisabled;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled ? 0.64 : 1,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: disabled ? null : _signIn,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lilac,
            disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.ink.withValues(alpha: 0.48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (model.isIdentifying) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                model.isIdentifying
                    ? 'Logging in'
                    : (_hasSavedAccount ? 'Continue' : 'Sign in'),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _useAnotherAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: model.isIdentifying
            ? null
            : () {
                _emailFocus.unfocus();
                _emailController.text = '';
                model.useAnotherAccount();
              },
        child: Text(
          'Sign in with another account',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink.withValues(alpha: 0.54),
          ),
        ),
      ),
    );
  }

  String _displayName(String email) {
    final name = email.split('@').first;
    final formatted = name
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('+', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    return formatted.isEmpty ? email : formatted;
  }

  String _initials(String displayName, String email) {
    final parts =
        displayName.split(' ').where((part) => part.isNotEmpty).toList();
    final letters = parts.take(2).map((part) => part[0]).join().toUpperCase();
    if (letters.isNotEmpty) return letters;
    return email
        .substring(0, email.length >= 2 ? 2 : email.length)
        .toUpperCase();
  }
}
