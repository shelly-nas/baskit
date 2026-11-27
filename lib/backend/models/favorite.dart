/// An item the user buys often ("vaste boodschap"), put on a list with one
/// tap.
class Favorite {
  final String id;
  final String name;
  final String? quantity;

  const Favorite({required this.id, required this.name, this.quantity});

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (quantity != null) 'quantity': quantity,
  };
}
