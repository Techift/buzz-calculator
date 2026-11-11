import 'package:buzz_calculator/calculator_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('numberToEnglish', () {
    test('translates whole numbers with English grouping', () {
      expect(numberToEnglish('25'), 'Twenty-five');
      expect(numberToEnglish('150'), 'One hundred and fifty');
      expect(numberToEnglish('1250'), 'One thousand, two hundred and fifty');
      expect(numberToEnglish('25000'), 'Twenty-five thousand');
      expect(numberToEnglish('1000000'), 'One million');
      expect(
        numberToEnglish('3450750'),
        'Three million, four hundred and fifty thousand, seven hundred and fifty',
      );
    });

    test('translates zero, negatives, decimals, and scientific notation', () {
      expect(numberToEnglish('0'), 'Zero');
      expect(numberToEnglish('-25'), 'Negative twenty-five');
      expect(numberToEnglish('12.05'), 'Twelve point zero five');
      expect(numberToEnglish('1e+6'), 'One million');
    });
  });

  test('formats floating-point results without excess precision', () {
    expect(formatCalculationResult(25.0), '25');
    expect(formatCalculationResult(0.49999999999999994), '0.5');
    expect(formatCalculationResult(double.infinity), 'Error');
  });
}
