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
- Registro e inicio de sesión con correo y contraseña mediante Firebase.
- Inicio de sesión con una cuenta de Google en Android y web.
- Recuperación de contraseña, sesión persistente y cierre de sesión.
- Persistencia local separada para cada cuenta en el dispositivo.
- Datos de ejemplo en el primer inicio para poder recorrer la interfaz.

## Ejecutar la app

Necesitas Flutter 3.44 o posterior y un emulador Android o teléfono conectado.

```powershell
flutter pub get
flutter run
```

Para abrirla directamente en Chrome:

```powershell
flutter run -d chrome
```

La app ya está conectada al proyecto Firebase `rutaclara-gastos-polco` para
Android y web. Los proveedores Correo/Contraseña y Google están declarados en
`firebase.json`. Si se modifica esa configuración, se despliega con:

```powershell
firebase deploy --only auth --project rutaclara-gastos-polco
```

La huella SHA del certificado de desarrollo ya está registrada. Antes de
publicar en Google Play hay que registrar también en Firebase la huella SHA-1
del certificado de firma de aplicaciones que muestre Play Console y volver a
descargar `android/app/google-services.json`.

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
- `lib/auth`: acceso y sesión con Firebase Authentication.
- `lib/data`: guardado local.
- `lib/screens`: panel, gastos, fiscal y perfil.
- `lib/widgets`: componentes reutilizables y formulario.
- `lib/theme`: colores y estilos de RutaClara.

La estimación fiscal es informativa y no sustituye el criterio de una gestoría.
