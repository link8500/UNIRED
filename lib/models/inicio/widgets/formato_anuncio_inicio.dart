enum FormatoAnuncioInicio {
  cuadrado(250, 250),
  horizontal(728, 90),
  vertical(300, 600);

  const FormatoAnuncioInicio(this.width, this.height);
  final double width;
  final double height;

  static FormatoAnuncioInicio? entreSecciones(double availableWidth) {
    if (availableWidth >= horizontal.width) return horizontal;
    return availableWidth >= cuadrado.width ? cuadrado : null;
  }
}
