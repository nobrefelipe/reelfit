import 'package:reelfit/core/helpers.dart';

class IngredientModel {
  final String item;
  final String? quantity;

  IngredientModel({required this.item, this.quantity});

  static IngredientModel fromJson(dynamic json) => IngredientModel(
        item: Helper.getString(json['item']),
        quantity: Helper.getStringOrNull(json['quantity']),
      );

  static List<IngredientModel> fromJsonToList(dynamic json) {
    if (json == null || json is! List) return [];
    return json.map((item) => fromJson(item)).toList();
  }

  @override
  String toString() => 'IngredientModel(item: $item, quantity: $quantity)';
}
