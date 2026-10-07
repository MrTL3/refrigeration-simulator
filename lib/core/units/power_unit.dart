/// Unidades de potencia frigorífica, calorífica y eléctrica.
/// La unidad base canónica interna es el Vatio (W).
enum PowerUnit {
  watt('W', 1.0),
  kilowatt('kW', 1000.0),
  kcalPerHour('kcal/h', 1.163), // 1 kcal/h ≈ 1.163 W
  btuPerHour('BTU/h', 0.29307107), // 1 BTU/h ≈ 0.293 W
  refrigerationTon('TR', 3516.8528); // 1 US RT ≈ 3516.85 W

  final String symbol;
  final double wattsPerUnit;

  const PowerUnit(this.symbol, this.wattsPerUnit);

  double toWatts(double value) => value * wattsPerUnit;
  double fromWatts(double watts) => watts / wattsPerUnit;
}
