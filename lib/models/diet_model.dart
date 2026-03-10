import 'package:reelfit/core/helpers.dart';
import 'package:reelfit/models/ingredient_model.dart';

class DietModel {
  final String title;
  final List<IngredientModel> ingredients;
  final List<String> steps;
  final Map<String, dynamic>? nutrition;
  final String? prepTime;
  final String? cookTime;
  final int? servings;
  final String url;

  DietModel({
    required this.title,
    required this.ingredients,
    required this.steps,
    this.nutrition,
    this.prepTime,
    this.cookTime,
    this.servings,
    required this.url,
  });

  static DietModel fromJson(dynamic json) => DietModel(
        title: Helper.getString(json['title']),
        ingredients: IngredientModel.fromJsonToList(json['ingredients']),
        steps: Helper.getStringList(json['steps']),
        nutrition: json['nutrition'] is Map
            ? Helper.getMap(json['nutrition'])
            : null,
        prepTime: Helper.getStringOrNull(json['prep_time']),
        cookTime: Helper.getStringOrNull(json['cook_time']),
        servings: Helper.getIntOrNull(json['servings']),
        url: Helper.getString(json['url']),
      );

  @override
  String toString() =>
      'DietModel(title: $title, ingredients: ${ingredients.length}, url: $url)';
}
