# Integración de Fondos Animados para Caelestia

Una integración no oficial realizada por mi para el ecosistema [Caelestia](https://github.com/caelestia-dots/caelestia) que añade soporte nativo para Fondos Animados en video (.mp4, .mkv, .webm) directamente en la interfaz.

> **Nota**: Todo el crédito de la shell es para el equipo de Caelestia. Este proyecto es simplemente mi integración personalizada para añadir capacidades de fondos animados y pequeñas funciones adicionales.

*También disponible en [Inglés (English)](README.md).*

## Características

- **Integración Nativa**: Los fondos animados aparecen en el Lanzador Rápido de Caelestia (>Wallpaper) y en los menús de Configuración (Nexus), junto a los fondos estáticos.
- **Pausa Inteligente / Modo Juego**: Los videos se pausarán automáticamente cuando una ventana esté en pantalla completa (como al jugar) para ahorrar recursos del sistema. Ignora específicamente los navegadores, para que no pierdas tu fondo animado mientras ves un video de YouTube a pantalla completa.
- **Generación Automática de Miniaturas**: Genera automáticamente miniaturas `.jpg` de tus videos en segundo plano para que los menús de Caelestia carguen rapidísimo sin congelarse.
- **Integración Perfecta en Ajustes**: El menú de configuración carga y muestra correctamente la categoría de fondos animados.

## Cómo funciona

1. Reemplaza el componente `Image` por defecto con un elemento `MediaPlayer` en el módulo de fondo de Caelestia.
2. Se engancha a `Hypr.activeToplevel` y `GameMode.enabled` para detectar estados de pantalla completa y pausar el motor de video.
3. Instala un script en Python (`update-caelestia-live-thumbs`) que escanea automáticamente tu carpeta de Live-Wallpapers y extrae un fotograma para usarlo como miniatura en `~/.cache/caelestia/live_thumbs/`.
4. Modifica las páginas de configuración de Caelestia (`WallpaperSelect.qml`, `WallpaperCategory.qml`, y `WallpaperAndStyle.qml`) para que carguen de forma inteligente estas miniaturas sin crashear.

## Dependencias

Antes de instalar, asegúrate de tener los siguientes paquetes instalados en tu sistema:
- **`ffmpeg`**: Necesario para extraer miniaturas en segundo plano.
- **`xdg-user-dirs`**: Utilizado para localizar de forma precisa tu carpeta de Imágenes.
- **`qt6-multimedia`** y **`qt6-multimedia-ffmpeg`** (o el backend equivalente en tu distribución): Necesarios por el `MediaPlayer` de QML para reproducir los archivos de video en la interfaz.

## ¿Dónde pongo mis Fondos Animados?
Simplemente coloca tus archivos `.mp4`, `.mkv`, o `.webm` dentro de `~/Imágenes/Live-Wallpapers` (o tu carpeta equivalente localizada, siempre que esté junto a tu carpeta normal de `Wallpapers` o fondos). El script los detectará automáticamente.


## Instalación

1. Clona este repositorio en tu máquina local:
   ```bash
   git clone https://github.com/SunnydeuS/Caelestia-Live-Wallpapers-Integration.git
   cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
   ```

2. Ejecuta el script de instalación con privilegios sudo:
   ```bash
   sudo ./install.sh
   ```

3. Reinicia tu sistema para aplicar los cambios y cargar correctamente las resoluciones de imagen/video:
   ```bash
   systemctl reboot
   ```

## Actualización

Para obtener los últimos cambios de este repositorio, ejecuta el script de actualización:
```bash
cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
sudo ./update.sh
```

## Desinstalación

Si deseas eliminar esta modificación y volver al comportamiento original de Caelestia, ejecuta el script de desinstalación:
```bash
cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
sudo ./uninstall.sh
```

## Nota
Asegúrate de tener Caelestia instalado antes de ejecutar este script. Esta modificación parchea los archivos del sistema en `/etc/xdg/quickshell/caelestia/` y crea copias de seguridad de los archivos originales (`.bak`).

## Agradecimientos

Agradecimientos especiales a [**AdiAmbassador**](https://github.com/adiambassador) por la inspiración detrás de este proyecto. Y por supuesto, muchísimas gracias al equipo de **Caelestia** por su increíble shell.
