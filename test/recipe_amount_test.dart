import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/recipe.dart';

void main() {
  test('recipe ingredient estimates stock units for discrete amounts', () {
    expect(RecipeIngredient.estimateStockUnitsFromText('4 adet'), 4);
    expect(RecipeIngredient.estimateStockUnitsFromText('2 dilim'), 2);
    expect(RecipeIngredient.estimateStockUnitsFromText('1/2 cup'), 1);
  });

  test('recipe ingredient estimates stock units for weight and volume', () {
    expect(RecipeIngredient.estimateStockUnitsFromText('350 gram'), 4);
    expect(RecipeIngredient.estimateStockUnitsFromText('1 litre'), 4);
    expect(RecipeIngredient.estimateStockUnitsFromText('2 tablespoon'), 1);
  });
}
