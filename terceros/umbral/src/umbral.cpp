#include "umbral/umbral.hpp"

namespace umbral {

Nivel clasificar(double valor, const Politica& politica) {
  if (valor >= politica.limite_critico) {
    return Nivel::Critico;
  }
  if (valor >= politica.limite_degradado) {
    return Nivel::Degradado;
  }
  return Nivel::Correcto;
}

const char* a_texto(Nivel nivel) {
  switch (nivel) {
    case Nivel::Correcto:
      return "CORRECTO";
    case Nivel::Degradado:
      return "DEGRADADO";
    case Nivel::Critico:
      return "CRITICO";
  }
  return "DESCONOCIDO";
}

const char* version() { return "1.2.0"; }

}  // namespace umbral
