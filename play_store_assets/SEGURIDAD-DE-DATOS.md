# Guía para «Seguridad de los datos» en Google Play

Esta guía refleja la versión 1.0.0 actual. Debe revisarse si se añaden analítica,
publicidad, copia de seguridad en la nube u otros SDK.

## Respuestas generales

- ¿La app recopila o comparte alguno de los tipos de datos obligatorios? `Sí`
- ¿Todos los datos se cifran en tránsito? `Sí`
- ¿Los usuarios pueden solicitar que se eliminen sus datos? `Sí`
- URL de eliminación: `https://rutaclara-gastos-polco.web.app/eliminar-cuenta`
- ¿La app comparte datos con terceros para sus propios fines? `No`

Firebase/Google presta el servicio de autenticación como proveedor tecnológico;
no se usa para publicidad ni para vender información.

## Datos que se declaran como recopilados

### Información personal → Dirección de correo electrónico

- Recopilada: `Sí`
- Compartida: `No`
- Tratamiento: `Obligatorio para usar una cuenta`
- Finalidades: `Funcionalidad de la aplicación` y `Gestión de cuentas`

### Información personal → Identificadores de usuario

- Recopilados: `Sí`
- Compartidos: `No`
- Tratamiento: `Obligatorio`
- Finalidades: `Funcionalidad de la aplicación` y `Gestión de cuentas`

### Información personal → Nombre

- Recopilado: `Sí, solo si el proveedor de acceso con Google lo facilita`
- Compartido: `No`
- Tratamiento: `Opcional, depende del método de acceso`
- Finalidad: `Gestión de cuentas`

### Dispositivo u otros identificadores

- Recopilados: `Sí`
- Compartidos: `No`
- Incluye: identificador de instalación de Firebase e información técnica de autenticación.
- Tratamiento: `Obligatorio`
- Finalidades: `Funcionalidad de la aplicación`, `Seguridad` y `Prevención de fraude`

Firebase Authentication también procesa dirección IP y agente de usuario para
proteger el registro y el inicio de sesión frente a abusos.

## Datos que permanecen en el dispositivo

Los siguientes datos no se marcan como «recopilados» en el formulario porque la
app no los transmite al desarrollador ni a un servidor propio:

- Información financiera introducida en los gastos.
- Fotos de tickets y facturas.
- Archivos justificantes.
- Categorías, proveedores, importes, IVA, IRPF y formas de pago.

Solo salen del dispositivo cuando el usuario decide exportarlos o compartirlos;
en ese caso el usuario elige el destinatario y el canal.

## Prácticas de seguridad y eliminación

- Firebase cifra en tránsito la información recopilada mediante HTTPS.
- No hay anuncios ni SDK de analítica publicitaria.
- La app permite borrar la cuenta desde `Mi negocio → Eliminar mi cuenta`.
- La eliminación borra la cuenta de Firebase y los gastos y justificantes
  locales asociados en ese dispositivo.
- También existe un mecanismo externo de solicitud por correo en la URL indicada.

