/// Aplicacion de linea de ordenes: resumen de calidad de servicio de una serie.
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <string>

#include <telemetria/kpi.hpp>
#include <telemetria/version.hpp>

namespace {

void ayuda(const char* programa) {
  std::cout << "Uso: " << programa << " <fichero.csv> [opciones]\n"
            << "  --degradado <ms>  limite de degradacion (por omision 50)\n"
            << "  --critico   <ms>  limite critico        (por omision 100)\n"
            << "  --json            salida en formato JSON\n"
            << "  --version         muestra la version y termina\n"
            << "  --help            muestra esta ayuda\n";
}

}  // namespace

int main(int argc, char* argv[]) {
  std::string ruta;
  umbral::Politica politica;
  bool json = false;

  for (int i = 1; i < argc; ++i) {
    const std::string arg = argv[i];
    if (arg == "--version") {
      std::cout << "telemetria " << telemetria::kVersionLarga << " (umbral "
                << umbral::version() << ")\n";
      return EXIT_SUCCESS;
    }
    if (arg == "--help" || arg == "-h") {
      ayuda(argv[0]);
      return EXIT_SUCCESS;
    }
    if (arg == "--json") {
      json = true;
    } else if (arg == "--degradado" && i + 1 < argc) {
      politica.limite_degradado = std::stod(argv[++i]);
    } else if (arg == "--critico" && i + 1 < argc) {
      politica.limite_critico = std::stod(argv[++i]);
    } else if (!arg.empty() && arg.front() != '-') {
      ruta = arg;
    } else {
      std::cerr << "Opcion no reconocida: " << arg << "\n";
      ayuda(argv[0]);
      return EXIT_FAILURE;
    }
  }

  if (ruta.empty()) {
    ayuda(argv[0]);
    return EXIT_FAILURE;
  }

  try {
    const telemetria::SerieKPI serie = telemetria::cargar_csv(ruta);
    const double p95 = serie.percentil(95.0);
    const char* nivel = umbral::a_texto(serie.nivel_servicio(politica));

    std::cout << std::fixed << std::setprecision(3);
    if (json) {
      std::cout << R"({"fichero":")" << ruta << R"(","muestras":)" << serie.tamano()
                << R"(,"media":)" << serie.media() << R"(,"p95":)" << p95
                << R"(,"disponibilidad":)"
                << serie.disponibilidad(politica.limite_degradado) << R"(,"nivel":")"
                << nivel << "\"}\n";
    } else {
      std::cout << "Fichero        : " << ruta << "\n"
                << "Muestras       : " << serie.tamano() << "\n"
                << "Media          : " << serie.media() << " ms\n"
                << "Desv. tipica   : " << serie.desviacion_tipica() << " ms\n"
                << "Percentil 95   : " << p95 << " ms\n"
                << "Disponibilidad : "
                << 100.0 * serie.disponibilidad(politica.limite_degradado) << " %\n"
                << "Nivel servicio : " << nivel << "\n";
    }
  } catch (const std::exception& error) {
    std::cerr << "Error: " << error.what() << "\n";
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
