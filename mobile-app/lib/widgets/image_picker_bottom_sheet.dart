import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_enums.dart';
import '../themes/app_theme.dart';
import 'language_text.dart';

Future<XFile?> pickClassificationImage(BuildContext context, AppLanguage language) async {
  final picker = ImagePicker();

  return showModalBottomSheet<XFile?>(
    context: context,
    backgroundColor: AppThemeColors.card(context),
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(LanguageText.t(
                language,
                'Camera',
                'कैमरा',
                'कॅमेरा',
              )),
              onTap: () async {
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (ctx.mounted) Navigator.pop(ctx, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(LanguageText.t(
                language,
                'Gallery',
                'गैलरी',
                'गॅलरी',
              )),
              onTap: () async {
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (ctx.mounted) Navigator.pop(ctx, image);
              },
            ),
          ],
        ),
      );
    },
  );
}
