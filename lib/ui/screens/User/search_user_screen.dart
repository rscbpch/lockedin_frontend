import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/screens/User/widget/user_search_tile.dart';
import 'package:lockedin_frontend/ui/widgets/display/simple_back_sliver_app_bar.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/search_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/user_search_provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/user_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class SearchUserScreen extends StatelessWidget {
  const SearchUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return ChangeNotifierProvider(
      create: (_) => UserSearchProvider(
        service: UserService(getAuthToken: () async => auth.token),
      ),
      child: const _SearchUserView(),
    );
  }
}

class _SearchUserView extends StatefulWidget {
  const _SearchUserView();

  @override
  State<_SearchUserView> createState() => _SearchUserViewState();
}

class _SearchUserViewState extends State<_SearchUserView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<UserSearchProvider>().search(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged); // 👈 clean up listener
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserSearchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SimpleBackSliverAppBar(
              title: 'Find People',
              onBack: () => Navigator.pop(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBarWidget(
                  controller: _controller,
                  hintText: 'Search by name or username...',
                  onChanged: provider.search, // 👈 live search
                  onClear: () {
                    _controller.clear();
                    context.read<UserSearchProvider>().clear();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverFillRemaining(
              child: _buildBody(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserSearchProvider provider) {
    if (provider.status == UserSearchStatus.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.backgroundBox,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search, size: 48, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Find people to follow',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search by name or username',
              style: TextStyle(color: AppColors.grey, fontSize: 13, fontFamily: 'Quicksand'),
            ),
          ],
        ),
      );
    }

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.status == UserSearchStatus.error) {
      return Center(
        child: Text(
          provider.errorMessage ?? 'Something went wrong',
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }

    if (provider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              'No results for "${_controller.text}"',
              style: const TextStyle(color: AppColors.grey, fontSize: 14, fontFamily: 'Quicksand'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 72,
        endIndent: 16,
        color: AppColors.accent,
      ),
      itemBuilder: (context, index) => UserSearchTile(user: provider.results[index]),
    );
  }
}