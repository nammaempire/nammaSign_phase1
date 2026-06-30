import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/legal_page.dart';

/// Tiny "By continuing, you agree to our Terms and Privacy Policy" footer.
///
/// Use under the sign-in CTA, the account-type CTA, and anywhere else
/// the user is creating or upgrading their account. Both link spans tap
/// open the corresponding legal page screen.
class ConsentFooter extends StatelessWidget {
  const ConsentFooter({
    super.key,
    this.textColor,
    this.linkColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 12,
  });

  final Color? textColor;
  final Color? linkColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.white.withValues(alpha: 0.7);
    final link = linkColor ?? AppColors.primaryAccent;

    TextStyle base = TextStyle(
      fontSize: fontSize,
      color: fg,
      height: 1.4,
    );
    TextStyle linkStyle = base.copyWith(
      color: link,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: link,
    );

    return Padding(
      padding: padding,
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(
                      AppRoutes.legalFor(LegalPageId.terms),
                    ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(
                      AppRoutes.legalFor(LegalPageId.privacy),
                    ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
