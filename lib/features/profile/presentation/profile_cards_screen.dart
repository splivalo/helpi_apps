import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/network/token_storage.dart';

/// Sub-screen: credit cards list + add/delete.
class ProfileCardsScreen extends StatefulWidget {
  const ProfileCardsScreen({
    super.key,
    required this.cards,
    required this.onCardsChanged,
  });

  final List<Map<String, dynamic>> cards;
  final ValueChanged<List<Map<String, dynamic>>> onCardsChanged;

  @override
  State<ProfileCardsScreen> createState() => _ProfileCardsScreenState();
}

class _ProfileCardsScreenState extends State<ProfileCardsScreen> {
  static const _dummyCardBrands = ['Visa', 'Mastercard', 'Maestro'];

  late List<Map<String, dynamic>> _cards;
  bool _isSavingCard = false;

  @override
  void initState() {
    super.initState();
    _cards = List.of(widget.cards);
  }

  Future<void> _addDummyCard() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null) return;

    final nextIndex = _cards.length;
    final brand = _dummyCardBrands[nextIndex % _dummyCardBrands.length];
    final last4 = (4242 + nextIndex).toString().padLeft(4, '0');

    setState(() => _isSavingCard = true);

    final result = await AppApiService().createPaymentMethod({
      'userId': userId,
      'processor': 0,
      'brand': brand,
      'last4': last4.substring(last4.length - 4),
      'isDefault': _cards.isEmpty,
    });

    if (!mounted) return;

    setState(() {
      _isSavingCard = false;
      if (result.success && result.data != null) {
        _cards = [..._cards, result.data!];
        widget.onCardsChanged(_cards);
      }
    });

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final cardId = (card['id'] as num?)?.toInt();
    if (cardId == null) return;

    final result = await AppApiService().deletePaymentMethod(cardId);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
      return;
    }

    setState(() {
      _cards = _cards.where((item) => item['id'] != card['id']).toList();
      widget.onCardsChanged(_cards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.creditCards)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_cards.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 20,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.noCards,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._cards.map((card) {
              final brand = card['brand'] as String? ?? '';
              final last4 = card['last4'] as String? ?? '****';
              final display = brand.isNotEmpty
                  ? '$brand **** $last4'
                  : '**** $last4';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.credit_card,
                      color: theme.colorScheme.secondary,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => _deleteCard(card),
                      child: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                        size: 22,
                      ),
                    ),
                  ),
                  child: Text(
                    display,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSavingCard ? null : _addDummyCard,
            icon: _isSavingCard
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 20),
            label: Text(AppStrings.addCard),
          ),
        ],
      ),
    );
  }
}
