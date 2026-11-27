import '../models/shopping_list.dart';

/// Sections of a Dutch supermarket, in the order of a usual walk through
/// the shop (FR-006).
enum StoreSection {
  produce('Vegetables and fruit'),
  bakery('Bakery'),
  meatAndFish('Meat and fish'),
  cheeseAndCuts('Cheese and cold cuts'),
  dairy('Dairy and eggs'),
  meals('Meals and salads'),
  breakfast('Breakfast and spreads'),
  pastaAndWorld('Pasta, rice and world food'),
  pantry('Soups, sauces and tins'),
  sweets('Sweets, biscuits and snacks'),
  coffeeAndTea('Coffee and tea'),
  drinks('Drinks'),
  frozen('Frozen'),
  household('Household'),
  personalCare('Personal care and baby'),
  other('Other');

  final String label;

  const StoreSection(this.label);
}

/// Items of one section, in the order they have on the list.
class StoreGroup {
  final StoreSection section;
  final List<ListItem> items;

  const StoreGroup(this.section, this.items);
}

/// Puts list items in the order of a walk through the shop. The section
/// comes from the supermarket category when the item has one (added from an
/// offer or product), otherwise from words in the name. When several words
/// match, the longest wins: "melkchocolade" is sweets, not dairy.
class StoreLayout {
  /// Words in a category or item name, per section; lower case, Dutch.
  static const Map<StoreSection, List<String>> _words = {
    StoreSection.produce: [
      'groente',
      'fruit',
      'aardappel',
      'appel',
      'banaan',
      'bananen',
      'tomaat',
      'tomaten',
      'komkommer',
      'sla',
      'ui',
      'uien',
      'paprika',
      'wortel',
      'peer',
      'peren',
      'druiven',
      'citroen',
      'avocado',
      'champignon',
      'broccoli',
      'spinazie',
      'courgette',
      'prei',
      'knoflook',
      'sinaasappel',
      'mandarijn',
      'aardbei',
      'bloemkool',
      'andijvie',
      'boontjes',
      'kiwi',
      'mango',
      'meloen',
    ],
    StoreSection.bakery: [
      'bakkerij',
      'brood',
      'bolletje',
      'bollen',
      'croissant',
      'beschuit',
      'krentenbol',
      'stokbrood',
      'pistolet',
      'cracker',
    ],
    StoreSection.meatAndFish: [
      'vlees',
      'vis',
      'kip',
      'kipfilet',
      'gehakt',
      'rundvlees',
      'varkensvlees',
      'speklapjes',
      'spek',
      'worst',
      'rookworst',
      'hamburger',
      'schnitzel',
      'zalm',
      'kabeljauw',
      'garnalen',
      'vegetarisch',
      'vegan',
    ],
    StoreSection.cheeseAndCuts: [
      'kaas',
      'vleeswaren',
      'ham',
      'salami',
      'rookvlees',
      'filet americain',
      'leverworst',
      'boterhamworst',
    ],
    StoreSection.dairy: [
      'zuivel',
      'eieren',
      'ei',
      'melk',
      'karnemelk',
      'yoghurt',
      'kwark',
      'vla',
      'boter',
      'roomboter',
      'room',
      'slagroom',
      'margarine',
    ],
    StoreSection.meals: ['maaltijd', 'maaltijden', 'salade', 'pizza'],
    StoreSection.breakfast: [
      'ontbijt',
      'beleg',
      'hagelslag',
      'pindakaas',
      'jam',
      'muesli',
      'cornflakes',
      'havermout',
      'honing',
      'chocoladepasta',
      'granola',
    ],
    StoreSection.pastaAndWorld: [
      'pasta',
      'rijst',
      'wereldkeuken',
      'spaghetti',
      'macaroni',
      'penne',
      'noedels',
      'tortilla',
      'wraps',
      'couscous',
    ],
    StoreSection.pantry: [
      'soep',
      'saus',
      'sauzen',
      'kruiden',
      'olie',
      'conserven',
      'ketchup',
      'mayonaise',
      'mosterd',
      'azijn',
      'peper',
      'zout',
      'bouillon',
      'tomatenpuree',
      'tonijn',
      'bonen',
      'meel',
      'suiker',
    ],
    StoreSection.sweets: [
      'koek',
      'koekjes',
      'snoep',
      'chocolade',
      'melkchocolade',
      'chips',
      'borrel',
      'snacks',
      'tussendoortjes',
      'drop',
      'nootjes',
      'pinda',
      'kaasstengels',
      'stroopwafels',
      'reep',
    ],
    StoreSection.coffeeAndTea: ['koffie', 'koffiebonen', 'thee', 'cappuccino'],
    StoreSection.drinks: [
      'frisdrank',
      'sappen',
      'sap',
      'water',
      'bier',
      'wijn',
      'drank',
      'cola',
      'limonade',
      'ranja',
      'aperitieven',
    ],
    StoreSection.frozen: ['diepvries', 'ijs', 'ijsjes', 'friet', 'patat'],
    StoreSection.household: [
      'huishouden',
      'wc-papier',
      'toiletpapier',
      'keukenrol',
      'wasmiddel',
      'afwasmiddel',
      'vaatwas',
      'vuilniszak',
      'schoonmaak',
      'allesreiniger',
    ],
    StoreSection.personalCare: [
      'drogisterij',
      'verzorging',
      'baby',
      'gezondheid',
      'tandpasta',
      'tandenborstel',
      'shampoo',
      'douchegel',
      'zeep',
      'deodorant',
      'luiers',
      'scheermesjes',
    ],
  };

  static StoreSection sectionOf(ListItem item) {
    final category = item.category;
    if (category != null && category.trim().isNotEmpty) {
      final fromCategory = _match(category);
      if (fromCategory != StoreSection.other) return fromCategory;
    }
    return _match(item.name);
  }

  /// [items] grouped by section, sections in shop order, empty ones left out.
  static List<StoreGroup> group(List<ListItem> items) {
    final bySection = <StoreSection, List<ListItem>>{};
    for (final item in items) {
      bySection.putIfAbsent(sectionOf(item), () => []).add(item);
    }
    return [
      for (final section in StoreSection.values)
        if (bySection[section] case final sectionItems?)
          StoreGroup(section, sectionItems),
    ];
  }

  static StoreSection _match(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9\-]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final joined = words.join(' ');
    var best = StoreSection.other;
    var bestLength = 0;
    for (final entry in _words.entries) {
      for (final keyword in entry.value) {
        // A whole word ("ui" not in "fruit"), a phrase, or the start or end
        // of a compound word ("kipfilet", "volkorenbrood") of 4+ letters.
        final matches = keyword.contains(' ')
            ? joined.contains(keyword)
            : words.any(
                (w) =>
                    w == keyword ||
                    (keyword.length >= 4 &&
                        (w.startsWith(keyword) || w.endsWith(keyword))),
              );
        if (matches && keyword.length > bestLength) {
          best = entry.key;
          bestLength = keyword.length;
        }
      }
    }
    return best;
  }
}
