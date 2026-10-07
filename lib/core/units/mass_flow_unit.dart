/// Unidades de caudal másico de refrigerante.
/// La unidad base canónica interna es kg/s.
enum MassFlowUnit {
  kilogramsPerSecond('kg/s', 1.0),
  kilogramsPerHour('kg/h', 1.0 / 3600.0),
  gramsPerSecond('g/s', 0.001);

  final String symbol;
  final double kgPerSecondPerUnit;

  const MassFlowUnit(this.symbol, this.kgPerSecondPerUnit);

  double toKgPerSecond(double value) => value * kgPerSecondPerUnit;
  double fromKgPerSecond(double kgPerSecond) => kgPerSecond / kgPerSecondPerUnit;
}

/// Unidades de entalpía específica.
/// La unidad base canónica interna es J/kg.
enum EnthalpyUnit {
  joulesPerKg('J/kg', 1.0),
  kilojoulesPerKg('kJ/kg', 1000.0),
  kcalPerKg('kcal/kg', 4186.8),
  btuPerPound('BTU/lb', 2326.0);

  final String symbol;
  final double joulesPerUnit;

  const EnthalpyUnit(this.symbol, this.joulesPerUnit);

  double toJoulesPerKg(double value) => value * joulesPerUnit;
  double fromJoulesPerKg(double joules) => joules / joulesPerUnit;
}
