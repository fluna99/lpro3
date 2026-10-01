#include "telemetria/kpi.hpp"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace telemetria {
namespace {

double a_real(std::size_t n) { return static_cast<double>(n); }

}  // namespace

SerieKPI::SerieKPI(std::vector<double> muestras) : muestras_(std::move(muestras)) {}

void SerieKPI::agregar(double muestra) { muestras_.push_back(muestra); }

double SerieKPI::media() const {
  if (muestras_.empty()) {
    throw std::domain_error("media() sobre una serie vacia");
  }
  double suma = 0.0;
  for (double valor : muestras_) {
    suma += valor;
  }
  return suma / a_real(muestras_.size());
}

double SerieKPI::desviacion_tipica() const {
  if (muestras_.size() < 2) {
    throw std::domain_error("desviacion_tipica() requiere al menos dos muestras");
  }
  const double m = media();
  double acumulado = 0.0;
  for (double valor : muestras_) {
    const double d = valor - m;
    acumulado += d * d;
  }
  return std::sqrt(acumulado / (a_real(muestras_.size()) - 1.0));
}

double SerieKPI::percentil(double p) const {
  if (muestras_.empty()) {
    throw std::domain_error("percentil() sobre una serie vacia");
  }
  if (p < 0.0 || p > 100.0) {
    throw std::invalid_argument("percentil() fuera del intervalo [0, 100]");
  }
  std::vector<double> ordenadas = muestras_;
  std::sort(ordenadas.begin(), ordenadas.end());
  if (ordenadas.size() == 1) {
    return ordenadas.front();
  }
  const double posicion = (p / 100.0) * (a_real(ordenadas.size()) - 1.0);
  const double inferior = std::floor(posicion);
  const auto indice = static_cast<std::size_t>(inferior);
  const double fraccion = posicion - inferior;
  if (indice + 1 >= ordenadas.size()) {
    return ordenadas.back();
  }
  return ordenadas[indice] + fraccion * (ordenadas[indice + 1] - ordenadas[indice]);
}

double SerieKPI::disponibilidad(double limite) const {
  if (muestras_.empty()) {
    throw std::domain_error("disponibilidad() sobre una serie vacia");
  }
  const auto cumplen = static_cast<std::size_t>(std::count_if(
      muestras_.begin(), muestras_.end(), [limite](double v) { return v <= limite; }));
  return a_real(cumplen) / a_real(muestras_.size());
}

umbral::Nivel SerieKPI::nivel_servicio(const umbral::Politica& politica) const {
  return umbral::clasificar(percentil(95.0), politica);
}

SerieKPI cargar_csv(const std::string& ruta) {
  std::ifstream fichero(ruta);
  if (!fichero) {
    throw std::runtime_error("no se puede abrir el fichero: " + ruta);
  }

  SerieKPI serie;
  std::string linea;
  std::size_t numero = 0;
  while (std::getline(fichero, linea)) {
    ++numero;
    if (linea.empty() || linea.front() == '#') {
      continue;
    }
    const std::size_t coma = linea.find_last_of(',');
    const std::string campo =
        (coma == std::string::npos) ? linea : linea.substr(coma + 1);
    try {
      serie.agregar(std::stod(campo));
    } catch (const std::exception&) {
      throw std::runtime_error("valor no numerico en " + ruta + ":" +
                               std::to_string(numero));
    }
  }
  return serie;
}

}  // namespace telemetria
