import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ThemeUploadLearnMoreButton extends StatelessWidget {
  const ThemeUploadLearnMoreButton({super.key});

  static const learnMoreURL =
      'https://appflowy.gitbook.io/docs/essential-documentation/themes';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ThemeUploadWidget.buttonSize.height,
      child: IntrinsicWidth(
        child: SecondaryButton(
          outlineColor: Theme.of(context).colorScheme.onBackground,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FlowyText.medium(
              fontSize: ThemeUploadWidget.buttonFontSize,
              LocaleKeys.document_plugins_autoGeneratorLearnMore.tr(),
            ),
          ),
          onPressed: () async {
            final uri = Uri.parse(learnMoreURL);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (context.mounted) {
                Dialogs.show(
                  context,
                  child: FlowyDialog(
                    child: FlowyErrorPage.message(
                      LocaleKeys
                          .settings_appearance_themeUpload_urlUploadFailure
                          .tr()
                          .replaceAll(
                            '{}',
                            uri.toString(),
                          ),
                      howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
