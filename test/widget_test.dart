import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/recipe.dart';

void main() {
  test('recipe match percentage is calculated correctly', () {
    const recipe = Recipe(
      id: 'menemen',
      nameTr: 'Menemen',
      nameEn: 'Menemen',
      descriptionTr: 'Test recipe',
      descriptionEn: 'Test recipe',
      ingredients: [
        RecipeIngredient(ingredientId: 'egg', amountTr: '2 adet', amountEn: '2'),
        RecipeIngredient(
          ingredientId: 'tomato',
          amountTr: '2 adet',
          amountEn: '2',
        ),
        RecipeIngredient(
          ingredientId: 'pepper',
          amountTr: '1 adet',
          amountEn: '1',
        ),
      ],
      stepsTr: [
        RecipeStep(stepNumber: 1, instruction: 'Mix'),
      ],
      stepsEn: [
        RecipeStep(stepNumber: 1, instruction: 'Mix'),
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 10,
      servings: 2,
      difficulty: 'easy',
      category: 'main',
    );

    expect(recipe.getMatchPercentage(['egg', 'tomato']), closeTo(2 / 3, 0.001));
    expect(recipe.canMakeWith(['egg', 'tomato']), isFalse);
    expect(recipe.canMakeWith(['egg', 'tomato', 'pepper']), isTrue);
  });

  test('ingredient amount scales with serving multiplier', () {
    const ingredient = RecipeIngredient(
      ingredientId: 'milk',
      amountTr: '2 bardak',
      amountEn: '2 cups',
    );

    expect(ingredient.getScaledAmount('en', 1.5), '3 cups');
    expect(ingredient.getScaledAmount('tr', 0.5), '1 bardak');
  });
}
