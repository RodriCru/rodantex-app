/// Estados de carga de una sección de pantalla.
///
/// La UI pinta siempre uno de los cuatro casos: cargando, con datos, sin datos
/// o error. `idle` es el estado previo a la primera carga.
enum LoadStatus { idle, loading, success, empty, failure }
