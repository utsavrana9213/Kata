import 'package:servekeen/service_model.dart';

enum VendorTier { standard, premium }

String normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

bool isTier(Service service, VendorTier tier) =>
    tier == VendorTier.premium ? service.isPremium : !service.isPremium;

const _ignoredSearchWords = {
  'a',
  'an',
  'and',
  'for',
  'i',
  'in',
  'me',
  'near',
  'need',
  'of',
  'please',
  'service',
  'services',
  'show',
  'the',
  'to',
  'want',
};

const _searchAliases = <String, List<String>>{
  'car': ['car', 'cars', 'auto', 'automotive', 'vehicle'],
  'auto': ['auto', 'automotive', 'car', 'vehicle'],
  'doctor': ['doctor', 'clinic', 'hospital', 'medical'],
  'clinic': ['clinic', 'doctor', 'hospital', 'medical'],
  'gym': ['gym', 'fitness', 'workout'],
  'photo': ['photo', 'photography', 'photographer', 'camera'],
  'food': ['food', 'catering', 'caterer', 'restaurant'],
  'party': ['party', 'event', 'banquet', 'wedding'],
  'delivery': ['delivery', 'courier', 'parcel'],
  'moving': ['moving', 'mover', 'packers', 'shifting'],
  'travel': ['travel', 'tour', 'adventure'],
  'beauty': ['beauty', 'salon', 'spa', 'makeup'],
};

List<List<String>> _queryGroups(String query) {
  final terms = normalizeSearch(query)
      .split(' ')
      .where((term) => term.length > 1 && !_ignoredSearchWords.contains(term));
  return terms.map((term) => _searchAliases[term] ?? [term]).toList();
}

bool _containsWordOrPhrase(String haystack, String value) {
  return ' $haystack '.contains(' $value ') ||
      haystack.split(' ').any((word) => word.startsWith(value));
}

String _searchableText(Service service, Map<String, String> categories) =>
    normalizeSearch(
      [
        service.companyName,
        service.serviceName,
        service.subcategory ?? '',
        categories[service.categorys] ?? '',
        service.locations ?? '',
        service.address ?? '',
        service.shortDescription ?? '',
        service.description ?? '',
      ].join(' '),
    );

List<Service> rankRelevantServicesAllTiers(
  Iterable<Service> services,
  String query, {
  Map<String, String> categoryNames = const {},
}) {
  final normalizedQuery = normalizeSearch(query);
  final groups = _queryGroups(query);
  if (groups.isEmpty) return [];
  final results = services.where((service) {
    final haystack = _searchableText(service, categoryNames);
    return groups.every(
      (alternatives) =>
          alternatives.any((value) => _containsWordOrPhrase(haystack, value)),
    );
  }).toList();
  results.sort(
    (a, b) => _relevanceScore(
      a,
      normalizedQuery,
      groups,
      categoryNames,
    ).compareTo(_relevanceScore(b, normalizedQuery, groups, categoryNames)),
  );
  return results;
}

/// Conservative client-side relevance guard for imperfect backend search.
/// A service is shown only when a query matches a real vendor field/category.
List<Service> rankRelevantServices(
  Iterable<Service> services,
  String query, {
  required VendorTier tier,
  Map<String, String> categoryNames = const {},
}) {
  return rankRelevantServicesAllTiers(
    services.where((service) => isTier(service, tier)),
    query,
    categoryNames: categoryNames,
  );
}

int _relevanceScore(
  Service service,
  String query,
  List<List<String>> groups,
  Map<String, String> categories,
) {
  final fields = [
    service.serviceName,
    service.subcategory ?? '',
    categories[service.categorys] ?? '',
    service.companyName,
  ].map(normalizeSearch).toList();
  for (var index = 0; index < fields.length; index++) {
    if (fields[index] == query) return index;
    if (fields[index].startsWith(query)) return index + 4;
  }
  var score = 20;
  for (var index = 0; index < fields.length; index++) {
    for (final group in groups) {
      if (group.any((value) => _containsWordOrPhrase(fields[index], value))) {
        score += index;
      } else {
        score += 8;
      }
    }
  }
  return score;
}
