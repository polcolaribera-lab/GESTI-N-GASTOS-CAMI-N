# RutaClara

MVP de un gestor de gastos para transportistas autónomos, creado con Flutter y
preparado para Android/Google Play.

## Qué incluye

- Panel mensual con presupuesto, gasto deducible e IVA soportado.
- Alta rápida de gastos con categoría, proveedor, fecha y forma de pago.
- Cálculo automático de base imponible e IVA incluido.
- Histórico con búsqueda, filtros y borrado reversible.
- Edición de cualquier gasto tocando su tarjeta.
- Eliminación visible con confirmación y opción de deshacer.
- Prorrateo mensual, trimestral, semestral o anual de seguros.
- Captura de fotos y selección múltiple de facturas, tickets y documentos.
- Justificantes guardados localmente y asociados a cada gasto.
- Exportación trimestral ZIP para la gestoría con CSV, resumen y justificantes.
- Resumen fiscal trimestral orientativo.
- Persistencia local en el dispositivo.
- Datos de ejemplo en el primer inicio para poder recorrer la interfaz.

## Ejecutar la app

Necesitas Flutter 3.44 o posterior y un emulador Android o teléfono conectado.

```powershell
flutter pub get
flutter run
```

Para comprobar el proyecto:

```powershell
flutter analyze
flutter test
```

Para generar el paquete de Google Play:

```powershell
flutter build appbundle --release
```

El archivo resultante estará en
`build/app/outputs/bundle/release/app-release.aab`. Antes de publicarlo hay que
configurar una clave de firma propia y revisar el identificador
`com.rutaclara.ruta_clara`.

## Estructura

- `lib/models`: modelo de gasto y categorías.
- `lib/data`: guardado local.
- `lib/screens`: panel, gastos, fiscal y perfil.
- `lib/widgets`: componentes reutilizables y formulario.
- `lib/theme`: colores y estilos de RutaClara.

La estimación fiscal es informativa y no sustituye el criterio de una gestoría.
