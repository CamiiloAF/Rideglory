# Rideglory — Copy y ASO para stores (Beta · Colombia · Español)

> Optimizado para búsquedas como: rodadas, eventos moto, comunidad motera,
> motociclismo, salidas en moto, parche motero, tracking de rodada.

---

## Google Play Store

### Título (máx. 30 caracteres)
`Rideglory: Eventos moteros`

### Descripción corta (máx. 80 caracteres)
`Crea rodadas, únete a eventos y sigue a tu parche en vivo. Comunidad motera.`

### Descripción larga (máx. 4000 caracteres)
```
Rideglory es la app para la comunidad motera: organiza rodadas, descubre eventos
cerca de ti y mantente conectado con tu parche antes, durante y después de cada
salida.

🏍️ EVENTOS Y RODADAS
• Crea eventos en segundos: ruta, punto de encuentro, fecha y cupos.
• Explora rodadas abiertas y únete con un toque.
• Gestiona inscripciones y aprueba asistentes.

📍 SEGUIMIENTO EN VIVO
• Mira la ubicación de todos los participantes en tiempo real durante la rodada.
• Nadie se pierde: sabes dónde va el grupo en todo momento.
• Botón de SOS para pedir ayuda si algo pasa en la vía.

🛵 TU GARAJE
• Registra tus motos y lleva el historial de mantenimientos.
• Recuerda cambios de aceite, SOAT y revisiones.

👥 COMUNIDAD
• Encuentra otros moteros y arma parche.
• Perfiles, eventos y experiencias compartidas.

Rideglory nació para que rodar en grupo sea más fácil, seguro y divertido.
Descárgala gratis y vive cada kilómetro con tu comunidad.

¡Nos vemos en la vía! 🤘
```

### Keywords / ASO (Google indexa título + descripciones)
Refuerza de forma natural: rodadas, eventos moto, comunidad motera, motociclismo,
salidas en moto, tracking rodada, garaje moto, mantenimiento moto, SOAT, parche motero.

---

## Apple App Store

### Nombre de la app (máx. 30 caracteres)
`Rideglory`

### Subtítulo (máx. 30 caracteres)
`Rodadas y comunidad motera`

### Texto promocional (máx. 170 caracteres) — editable sin nueva revisión
`Organiza rodadas, únete a eventos y sigue a tu parche en vivo con seguimiento en
tiempo real y botón de SOS. ¡La app de la comunidad motera!`

### Palabras clave (máx. 100 caracteres, separadas por coma, sin espacios)
`rodada,moto,motero,eventos,motociclismo,comunidad,parche,rutas,tracking,garaje,mantenimiento`

### Descripción
```
Rideglory es la app para la comunidad motera: organiza rodadas, descubre eventos
cerca de ti y mantente conectado con tu parche en cada salida.

EVENTOS Y RODADAS
Crea eventos con ruta, punto de encuentro y cupos. Explora rodadas abiertas y
únete con un toque. Gestiona inscripciones y aprueba asistentes.

SEGUIMIENTO EN VIVO
Mira la ubicación de todos los participantes en tiempo real durante la rodada.
Botón de SOS para pedir ayuda si algo pasa en la vía.

TU GARAJE
Registra tus motos, lleva el historial de mantenimientos y no olvides el SOAT ni
las revisiones.

COMUNIDAD
Encuentra otros moteros, arma parche y comparte cada kilómetro.

Descárgala gratis y vive cada rodada con tu comunidad. ¡Nos vemos en la vía!
```

---

## Textos para los screenshots (overlay corto, 3-5 palabras)

1. **Pantalla de eventos** → "Encuentra tu próxima rodada"
2. **Crear evento** → "Organiza en segundos"
3. **Tracking en vivo (mapa)** → "Sigue a tu parche en vivo"
4. **SOS** → "Seguridad en cada vía"
5. **Garaje / mantenimiento** → "Cuida tu moto"
6. **Comunidad / perfiles** → "Conecta con moteros"

---

## Documentación de encriptación (App Store)

### Descripción corta de funcionalidad (requerida por Apple — paso 1 de 3)

> App de comunidad motera para organizar rodadas, seguimiento en tiempo real y gestión del garaje. Usa HTTPS (TLS) para todas las comunicaciones vía iOS ATS y Firebase Auth para autenticación. No implementa ni exporta algoritmos criptográficos propios.

---

## URLs para las stores

Todas las páginas están en `docs/web/` y se publican vía GitHub Pages (configurar Pages → source: `docs/`).

| Campo              | URL                                                                              |
|--------------------|----------------------------------------------------------------------------------|
| **URL de marketing** | `https://camiiloaf.github.io/Rideglory/web/`                                   |
| **URL de soporte**   | `https://camiiloaf.github.io/Rideglory/web/support.html`                       |
| Política de privacidad | `https://camiiloaf.github.io/Rideglory/web/privacy-policy.html`            |
| Términos y condiciones | `https://camiiloaf.github.io/Rideglory/web/terms-and-conditions.html`      |
| Eliminar cuenta    | `https://camiiloaf.github.io/Rideglory/web/delete-account.html`                 |

> Para activar GitHub Pages: Settings → Pages → Source: Deploy from branch → Branch: `main` → Folder: `/docs`.

---

## Notas para el revisor (App Store — campo "Notas", máx. 4 000 caracteres)

```
La app está en fase beta cerrada dirigida a la comunidad motociclista en Colombia. A continuación se incluye la información necesaria para la revisión.

Cuenta de prueba
- Email: reviewer@rideglory.com
- Contraseña: Review2025!

Flujos principales a revisar

1. Registro e inicio de sesión — El usuario puede registrarse con email/contraseña o con Google Sign-In. El inicio de sesión con Apple ID también está disponible.

2. Explorar y unirse a eventos — Desde la pantalla principal se listan eventos de rodada disponibles. El usuario puede ver el detalle, aplicar filtros por tipo y dificultad, y solicitar inscripción. La aprobación queda pendiente hasta que el organizador la confirme.

3. Crear un evento — El organizador completa un formulario de 4 pasos: información básica, ruta (punto de inicio y fin en mapa), configuración (cupos, precio, dificultad) y revisión final. Hay una opción de generar descripción con IA que requiere conexión al backend.

4. Seguimiento GPS (tracking) — Durante un evento activo, el participante puede activar el tracking desde la pantalla de detalle. La ubicación se comparte en tiempo real con los demás participantes. Este flujo requiere permiso de ubicación en primer plano y segundo plano. El botón SOS envía una alerta de emergencia.

5. Garaje — El usuario registra sus motos con datos técnicos y fotos. Puede escanear el SOAT con la cámara (OCR local, sin conexión a servidores externos) y registrar mantenimientos.

Permisos solicitados
- Ubicación precisa y en segundo plano: necesaria para el tracking en tiempo real durante rodadas. Solo se activa cuando el usuario inicia explícitamente el seguimiento en un evento.
- Cámara: para fotografiar vehículos y escanear el SOAT (procesamiento on-device con ML Kit).
- Galería/Fotos: para seleccionar imágenes de perfil, portada de eventos y vehículos.
- Notificaciones: para alertas de aprobación de registro, inicio de rodada y emergencias SOS.

Backend y conectividad
La app consume una API REST propia alojada en AWS. Algunas funciones como la generación de descripciones con IA y el tracking en tiempo real requieren conexión activa. Las funciones de garaje y consulta de eventos funcionan con conectividad estándar.

Notas adicionales
- La app está disponible únicamente en español (Colombia).
- No se procesan pagos dentro de la app; los eventos con costo se coordinan directamente entre organizador y participantes.
- La información médica de emergencia (tipo de sangre, EPS) es opcional y solo visible para el organizador en caso de alerta SOS.
- No hay contenido generado por usuarios de forma pública; los eventos son visibles para todos los usuarios registrados.
```

---

## Notas generales

- Verificar límites exactos en la consola al subir (los caracteres con tilde/emoji
  pueden contar distinto en algunos campos).
- Los emojis funcionan en Play; en App Store evítalos en nombre/subtítulo.
- Para beta cerrada: este copy sirve tal cual para la ficha de Internal/Closed
  Testing y para TestFlight.
- Reemplazar las credenciales de prueba antes de enviar a revisión.
