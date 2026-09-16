import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/recorder_choice.dart';
import '../session_info/session_info_page.dart';
import 'components/recorder_choice_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(AppStrings.homeTitle),
            backgroundColor: scheme.surface,
            actions: [
              IconButton(
                tooltip: AppStrings.sessionInfoTooltip,
                icon: const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 20),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SessionInfoPage()),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  AppStrings.homeDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                for (final choice in RecorderChoice.values.where(
                  (c) => c != RecorderChoice.clarity,
                )) ...[
                  RecorderChoiceCard(
                    choice: choice,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRouter.playground, arguments: choice),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
