import 'package:flutter/material.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../l10n/app_localizations.dart';

/// Bottom sheet for selecting product options before adding to cart.
class OptionPickerSheet extends StatefulWidget {
  const OptionPickerSheet({
    super.key,
    required this.product,
    this.initialSelections = const [],
  });

  final Product product;
  final List<SelectedOption> initialSelections;

  static Future<List<SelectedOption>?> show(
    BuildContext context, {
    required Product product,
    List<SelectedOption> initialSelections = const [],
  }) {
    return showModalBottomSheet<List<SelectedOption>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => OptionPickerSheet(
        product: product,
        initialSelections: initialSelections,
      ),
    );
  }

  @override
  State<OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<OptionPickerSheet> {
  late final Map<String, Set<String>> _selectedByGroup;

  @override
  void initState() {
    super.initState();
    _selectedByGroup = {};
    for (final cfg in widget.product.optionConfigs) {
      _selectedByGroup[cfg.group.id] = {};
    }
    for (final sel in widget.initialSelections) {
      _selectedByGroup.putIfAbsent(sel.groupId, () => {}).add(sel.choiceId);
    }
    for (final cfg in widget.product.optionConfigs) {
      final g = cfg.group;
      if (_selectedByGroup[g.id]!.isEmpty && !g.isMulti) {
        final defaults = g.choices.where((c) => c.isDefault);
        if (defaults.isNotEmpty) {
          _selectedByGroup[g.id] = {defaults.first.id};
        } else if (g.isRequired && g.choices.isNotEmpty) {
          _selectedByGroup[g.id] = {g.choices.first.id};
        }
      }
    }
  }

  int get _optionsTotalCents {
    var total = 0;
    for (final cfg in widget.product.optionConfigs) {
      for (final choiceId in _selectedByGroup[cfg.group.id] ?? {}) {
        final choice = cfg.group.choices.firstWhere((c) => c.id == choiceId);
        total += choice.priceDeltaCents;
      }
    }
    return total;
  }

  Money get _unitPrice => widget.product.price + Money(_optionsTotalCents);

  List<SelectedOption> _buildSelections() {
    final out = <SelectedOption>[];
    for (final cfg in widget.product.optionConfigs) {
      for (final choiceId in _selectedByGroup[cfg.group.id] ?? {}) {
        final choice = cfg.group.choices.firstWhere((c) => c.id == choiceId);
        out.add(SelectedOption(
          groupId: cfg.group.id,
          groupName: cfg.group.name,
          choiceId: choice.id,
          choiceName: choice.name,
          priceDeltaCents: choice.priceDeltaCents,
        ));
      }
    }
    return out;
  }

  String? _validate() {
    for (final cfg in widget.product.optionConfigs) {
      final g = cfg.group;
      final count = _selectedByGroup[g.id]?.length ?? 0;
      if (g.isMulti) {
        final min = g.minSelections > 0 ? g.minSelections : (cfg.isRequired ? 1 : 0);
        if (count < min) return '請選擇${g.name}（至少 $min 項）';
        if (g.maxSelections != null && count > g.maxSelections!) {
          return '${g.name}最多選 ${g.maxSelections} 項';
        }
      } else if (cfg.isRequired && count != 1) {
        return '請選擇${g.name}';
      }
    }
    return null;
  }

  void _toggleSingle(String groupId, String choiceId) {
    setState(() => _selectedByGroup[groupId] = {choiceId});
  }

  void _toggleMulti(String groupId, String choiceId, int? max) {
    setState(() {
      final set = _selectedByGroup.putIfAbsent(groupId, () => {});
      if (set.contains(choiceId)) {
        set.remove(choiceId);
      } else {
        if (max != null && set.length >= max) return;
        set.add(choiceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name, style: theme.textTheme.titleLarge),
                        MoneyText(_unitPrice, style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final cfg in widget.product.optionConfigs) ...[
                    Text(
                      '${cfg.group.name}${cfg.isRequired ? ' *' : ''}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (cfg.group.isMulti)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in cfg.group.choices)
                            FilterChip(
                              label: Text(_choiceLabel(c)),
                              selected: _selectedByGroup[cfg.group.id]?.contains(c.id) ?? false,
                              onSelected: (_) => _toggleMulti(
                                cfg.group.id,
                                c.id,
                                cfg.group.maxSelections,
                              ),
                            ),
                        ],
                      )
                    else
                      ...cfg.group.choices.map(
                        (c) => RadioListTile<String>(
                          value: c.id,
                          groupValue: _selectedByGroup[cfg.group.id]?.firstOrNull,
                          title: Text(_choiceLabel(c)),
                          onChanged: (_) => _toggleSingle(cfg.group.id, c.id),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: BigButton(
                label: '${AppLocalizations.of(context)!.addToOrder} ${_unitPrice.format()}',
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  final err = _validate();
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    return;
                  }
                  Navigator.pop(context, _buildSelections());
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _choiceLabel(OptionChoice c) {
    if (c.priceDeltaCents <= 0) return c.name;
    return '${c.name} (+${Money(c.priceDeltaCents).format()})';
  }
}

extension _FirstOrNull<T> on Set<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
