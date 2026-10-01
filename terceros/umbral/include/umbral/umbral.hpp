// Dependencia de terceros simulada: politica de umbrales de calidad de servicio.
#pragma once

namespace umbral {

/// Nivel de cumplimiento de un indicador frente a la politica acordada.
enum class Nivel { Correcto, Degradado, Critico };

/// Politica de servicio (los limites proceden del acuerdo de nivel de servicio).
struct Politica {
  double limite_degradado = 50.0;
  double limite_critico = 100.0;
};

/// Clasifica un valor medido segun la politica.
Nivel clasificar(double valor, const Politica& politica);

/// Representacion textual del nivel, apta para informes.
const char* a_texto(Nivel nivel);

/// Version de la biblioteca en formato "mayor.menor.parche".
const char* version();

}  // namespace umbral
