enum StockLevel { normal, low, out }

extension StockLevelX on StockLevel {
  static StockLevel classify(int remaining) {
    if (remaining <= 0) return StockLevel.out;
    if (remaining <= 5) return StockLevel.low;
    return StockLevel.normal;
  }
}
