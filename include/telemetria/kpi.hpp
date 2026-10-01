/// \file kpi.hpp
/// \brief Analisis estadistico de series de medidas de KPIs de red.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include <umbral/umbral.hpp>

namespace telemetria {

/// Serie de medidas de un indicador de red (por ejemplo, RTT en milisegundos).
class SerieKPI {
 public:
  SerieKPI() = default;

  /// Construye la serie a partir de un conjunto de muestras.
  explicit SerieKPI(std::vector<double> muestras);

  /// Anade una muestra al final de la serie.
  void agregar(double muestra);

  /// Numero de muestras almacenadas.
  [[nodiscard]] std::size_t tamano() const noexcept { return muestras_.size(); }

  /// Indica si la serie no contiene muestras.
  [[nodiscard]] bool vacia() const noexcept { return muestras_.empty(); }

  /// Acceso de solo lectura a las muestras.
  [[nodiscard]] const std::vector<double>& muestras() const noexcept { return muestras_; }

  /// Media aritmetica. \throws std::domain_error si la serie esta vacia.
  [[nodiscard]] double media() const;

  /// Desviacion tipica muestral (denominador n-1).
  /// \throws std::domain_error si hay menos de dos muestras.
  [[nodiscard]] double desviacion_tipica() const;

  /// Percentil \p p (0-100) por interpolacion lineal.
  /// \throws std::domain_error si la serie esta vacia.
  /// \throws std::invalid_argument si \p p esta fuera de [0, 100].
  [[nodiscard]] double percentil(double p) const;

  /// Fraccion de muestras que no superan \p limite, en el intervalo [0, 1].
  [[nodiscard]] double disponibilidad(double limite) const;

  /// Clasifica el percentil 95 de la serie frente a la politica de servicio.
  [[nodiscard]] umbral::Nivel nivel_servicio(const umbral::Politica& politica) const;

 private:
  std::vector<double> muestras_;
};

/// Carga una serie desde un CSV de una columna, o de la forma "instante,valor".
/// Las lineas vacias y las que empiezan por '#' se ignoran.
/// \throws std::runtime_error si el fichero no puede abrirse o esta malformado.
SerieKPI cargar_csv(const std::string& ruta);

}  // namespace telemetria
