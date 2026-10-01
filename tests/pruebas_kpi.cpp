// Marco de pruebas minimo: suficiente para el taller y sin dependencias
// externas. En un proyecto real se usaria GoogleTest, Catch2 o doctest,
// integrados igualmente con CTest.
#include <cmath>
#include <cstring>
#include <functional>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>

#include <telemetria/kpi.hpp>

namespace {

int fallos = 0;

void comprobar(bool condicion, const char* descripcion) {
  if (!condicion) {
    std::cerr << "  FALLO: " << descripcion << "\n";
    ++fallos;
  }
}

void casi_igual(double obtenido, double esperado, const char* descripcion,
                double tolerancia = 1e-9) {
  if (std::fabs(obtenido - esperado) > tolerancia) {
    std::cerr << "  FALLO: " << descripcion << " (obtenido " << obtenido << ", esperado "
              << esperado << ")\n";
    ++fallos;
  }
}

telemetria::SerieKPI serie_ejemplo() {
  return telemetria::SerieKPI({10.0, 20.0, 30.0, 40.0, 50.0});
}

void media() { casi_igual(serie_ejemplo().media(), 30.0, "media de la serie"); }

void desviacion() {
  casi_igual(serie_ejemplo().desviacion_tipica(), std::sqrt(250.0),
             "desviacion tipica muestral");
}

void percentil() {
  const telemetria::SerieKPI s = serie_ejemplo();
  casi_igual(s.percentil(0.0), 10.0, "percentil 0");
  casi_igual(s.percentil(50.0), 30.0, "percentil 50");
  casi_igual(s.percentil(100.0), 50.0, "percentil 100");
  casi_igual(s.percentil(95.0), 48.0, "percentil 95 interpolado");
}

void disponibilidad() {
  casi_igual(serie_ejemplo().disponibilidad(30.0), 0.6, "disponibilidad al limite 30");
  casi_igual(serie_ejemplo().disponibilidad(100.0), 1.0, "disponibilidad total");
}

void nivel_servicio() {
  const umbral::Politica politica{30.0, 60.0};
  comprobar(serie_ejemplo().nivel_servicio(politica) == umbral::Nivel::Degradado,
            "p95 = 48 ms debe clasificarse como DEGRADADO");
  const telemetria::SerieKPI buena({1.0, 2.0, 3.0});
  comprobar(buena.nivel_servicio(politica) == umbral::Nivel::Correcto,
            "serie por debajo del limite debe ser CORRECTO");
}

void serie_vacia() {
  const telemetria::SerieKPI vacia;
  bool lanzo = false;
  try {
    (void)vacia.media();
  } catch (const std::domain_error&) {
    lanzo = true;
  }
  comprobar(lanzo, "media() sobre serie vacia debe lanzar domain_error");
}

void percentil_invalido() {
  bool lanzo = false;
  try {
    (void)serie_ejemplo().percentil(120.0);
  } catch (const std::invalid_argument&) {
    lanzo = true;
  }
  comprobar(lanzo, "percentil(120) debe lanzar invalid_argument");
}

void carga_csv() {
  const telemetria::SerieKPI s = telemetria::cargar_csv("datos/rtt.csv");
  comprobar(s.tamano() == 12, "el CSV de ejemplo tiene 12 muestras utiles");
  comprobar(!s.vacia(), "la serie cargada no debe estar vacia");
}

void csv_inexistente() {
  bool lanzo = false;
  try {
    (void)telemetria::cargar_csv("datos/no-existe.csv");
  } catch (const std::runtime_error&) {
    lanzo = true;
  }
  comprobar(lanzo, "cargar_csv() de un fichero inexistente debe lanzar runtime_error");
}

}  // namespace

int main(int argc, char* argv[]) {
  const std::map<std::string, std::function<void()>> casos = {
      {"media", media},
      {"desviacion", desviacion},
      {"percentil", percentil},
      {"disponibilidad", disponibilidad},
      {"nivel_servicio", nivel_servicio},
      {"serie_vacia", serie_vacia},
      {"percentil_invalido", percentil_invalido},
      {"carga_csv", carga_csv},
      {"csv_inexistente", csv_inexistente}};

  if (argc != 2) {
    std::cerr << "Uso: pruebas_kpi <caso>\nCasos disponibles:\n";
    for (const auto& [nombre, funcion] : casos) {
      (void)funcion;
      std::cerr << "  " << nombre << "\n";
    }
    return 2;
  }

  const auto it = casos.find(argv[1]);
  if (it == casos.end()) {
    std::cerr << "Caso desconocido: " << argv[1] << "\n";
    return 2;
  }

  std::cout << "Ejecutando caso: " << it->first << "\n";
  it->second();
  if (fallos == 0) {
    std::cout << "  OK\n";
    return 0;
  }
  std::cerr << "  " << fallos << " comprobacion(es) fallida(s)\n";
  return 1;
}
