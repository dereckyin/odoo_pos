/// A selectable value within an option group (e.g. 半糖, 珍珠).
class OptionChoice {
  const OptionChoice({
    required this.id,
    required this.name,
    this.priceDeltaCents = 0,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int priceDeltaCents;
  final bool isDefault;
  final int sortOrder;
}

/// Tenant-level option group (e.g. 甜度, 冰塊, 加料).
class OptionGroup {
  const OptionGroup({
    required this.id,
    required this.name,
    this.selectionType = 'single',
    this.isRequired = true,
    this.minSelections = 0,
    this.maxSelections,
    this.sortOrder = 0,
    this.choices = const [],
  });

  final String id;
  final String name;
  final String selectionType;
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final int sortOrder;
  final List<OptionChoice> choices;

  bool get isMulti => selectionType == 'multi';
}

/// Option group bound to a product with optional per-product overrides applied.
class ProductOptionConfig {
  const ProductOptionConfig({
    required this.group,
    required this.isRequired,
    required this.sortOrder,
  });

  final OptionGroup group;
  final bool isRequired;
  final int sortOrder;
}

/// A customer's selection frozen for cart / order lines.
class SelectedOption {
  const SelectedOption({
    required this.groupId,
    required this.groupName,
    required this.choiceId,
    required this.choiceName,
    this.priceDeltaCents = 0,
  });

  factory SelectedOption.fromJson(Map<String, dynamic> j) => SelectedOption(
        groupId: j['group_id'] as String,
        groupName: j['group_name'] as String,
        choiceId: j['choice_id'] as String,
        choiceName: j['choice_name'] as String,
        priceDeltaCents: (j['price_delta_cents'] as num?)?.toInt() ?? 0,
      );

  final String groupId;
  final String groupName;
  final String choiceId;
  final String choiceName;
  final int priceDeltaCents;

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'choice_id': choiceId,
        'choice_name': choiceName,
        'price_delta_cents': priceDeltaCents,
      };

  String get signature => '$groupId:$choiceId';
}

extension SelectedOptionListX on List<SelectedOption> {
  String get optionsSignature {
    final parts = map((o) => o.signature).toList()..sort();
    return parts.join('|');
  }

  int get totalPriceDeltaCents =>
      fold(0, (sum, o) => sum + o.priceDeltaCents);

  String get displayLabel =>
      map((o) => o.choiceName).join(' · ');
}

/// Default selections for a product's option groups.
List<SelectedOption> defaultSelectionsFor(List<ProductOptionConfig> configs) {
  final out = <SelectedOption>[];
  for (final cfg in configs) {
    final g = cfg.group;
    if (g.isMulti) continue;
    OptionChoice? pick;
    for (final c in g.choices) {
      if (c.isDefault) {
        pick = c;
        break;
      }
    }
    pick ??= g.choices.isNotEmpty ? g.choices.first : null;
    if (pick != null) {
      out.add(SelectedOption(
        groupId: g.id,
        groupName: g.name,
        choiceId: pick.id,
        choiceName: pick.name,
        priceDeltaCents: pick.priceDeltaCents,
      ));
    }
  }
  return out;
}
