# Integración de Fondos Animados para Caelestia

Una integración no oficial realizada por mi para el ecosistema [Caelestia](https://github.com/caelestia-dots/caelestia) que añade soporte nativo para Fondos Animados en video (.mp4, .mkv, .webm) directamente en la interfaz.

> **Nota**: Todo el crédito de la shell es para el equipo de Caelestia. Este proyecto es simplemente mi integración personalizada para añadir capacidades de fondos animados y pequeñas funciones adicionales.

*También disponible en [Inglés (English)](README.md).*

## Nota de Compatibilidad
Este script de instalación asume el uso de rutas estándar de Linux y permisos de escritura en `/usr/lib` y `/etc`. Está pensado y probado principalmente para **Arch Linux** y sus derivadas (CachyOS, EndeavourOS, etc.).
- Asegúrate de tener Caelestia instalado antes de ejecutar este script. Esta modificación parchea los archivos del sistema en `/etc/xdg/quickshell/caelestia/` y crea copias de seguridad de los archivos originales (`.bak`).

## Características

- **Integración Nativa**: Los fondos animados aparecen en el Lanzador Rápido de Caelestia (>Wallpaper) y en los menús de Configuración (Nexus), junto a los fondos estáticos.
- **Pausa Inteligente / Modo Juego**: Los videos se pausarán automáticamente cuando una ventana esté en pantalla completa (como al jugar) para ahorrar recursos del sistema.
- **Generación Automática de Miniaturas**: Genera automáticamente miniaturas `.jpg` de los videos.
- **Integración en Ajustes (Nexus)**: El menú de configuración carga y muestra correctamente la categoría de fondos animados.

## Atajos

Al usar el carrusel (`>wallpaper`):

- **`Tab`**: Selecciona un fondo aleatorio.
- **`Shift + Tab`** / **`Backtab`**: Cicla entre los filtros de colores.
- **`Flecha Izquierda` / `Flecha Derecha`**: Cambia la vista entre fondos *Estáticos*, *Animados* y *Todos*.
- **`Ctrl + R`**: Recarga la lista de fondos y actualiza las miniaturas.

## Cómo funciona

1. Reemplaza el componente `Image` por defecto con un elemento `MediaPlayer` en el módulo de fondo de Caelestia.
2. Usa `Hypr.activeToplevel` y `GameMode.enabled` para detectar estados de pantalla completa y pausar el motor de video.
3. Instala un script en Python (`update-caelestia-live-thumbs`) que escanea automáticamente tu carpeta de Live-Wallpapers y extrae un fotograma para usarlo como miniatura en `~/.cache/caelestia/live_thumbs/`.
4. Modifica las páginas de configuración de Caelestia (`WallpaperSelect.qml`, `WallpaperCategory.qml`, y `WallpaperAndStyle.qml`) para que carguen las miniaturas sin crashear.

## Dependencias

Instala los paquetes requeridos con pacman (Arch Linux / CachyOS / EndeavourOS):

```bash
sudo pacman -S --needed ffmpeg xdg-user-dirs qt6-multimedia qt6-multimedia-ffmpeg python-pillow
```

*(Nota: `install.sh` también verificará estos paquetes y te ofrecerá instalarlos automáticamente).*

- **`ffmpeg`**: Necesario para extraer fotogramas de video para las miniaturas.
- **`xdg-user-dirs`**: Utilizado para localizar tu carpeta de Imágenes.
- **`qt6-multimedia`** y **`qt6-multimedia-ffmpeg`**: Requeridos por el `MediaPlayer` de QML para reproducir los fondos animados de forma nativa.
- **`python-pillow`**: Necesario para la generación de miniaturas, cuantización de color y clasificación de paleta.

## ¿Dónde pongo mis Fondos Animados?
Simplemente coloca tus archivos `.mp4`, `.mkv`, o `.webm` dentro de `~/Imágenes/Live-Wallpapers` (o tu carpeta de Imágenes localizada). La integración los detectará automáticamente.

## Actualizar la Base de Datos y Miniaturas

Cada vez que agregues, elimines o modifiques fondos animados, puedes actualizar la base de datos y regenerar miniaturas mediante cualquiera de estos métodos:

### 1. Desde la Interfaz (GUI)
- Abre el lanzador de fondos (`>wallpaper`) y presiona **`Ctrl + R`**, o haz clic en el botón **Actualizar (Refresh)** en el lanzador o en la configuración de fondos de Nexus.

### 2. Desde la Terminal (CLI)
- Ejecuta el comando de actualización directamente en tu terminal:
  ```bash
  update-caelestia-live-thumbs
  ```
- Para indexar también todos tus fondos estáticos en la base de datos (para extracción de paleta de colores y etiquetas de resolución):
  ```bash
  update-caelestia-live-thumbs --include-static
  ```

> **Dónde se guardan los datos:**
> - Miniaturas: `~/.cache/caelestia/live_thumbs/`
> - Base de datos de metadatos y colores: `~/.cache/caelestia/wallpaper_properties.json`

## Instalación y Configuración

1. Clona este repositorio:
   ```bash
   git clone https://github.com/amitxd75/Caelestia-Live-Wallpapers-Integration.git
   cd Caelestia-Live-Wallpapers-Integration
   ```

2. Ejecuta el menú de configuración interactivo:
   ```bash
   ./setup.sh
   ```

Esto abrirá un menú interactivo para instalar, actualizar o desinstalar la integración:
```text
=====================================================
       Caelestia Live Wallpapers Integration
=====================================================
  1) Install      Install integration & restart shell
  2) Update       Pull latest changes & re-apply
  3) Uninstall    Restore original Caelestia files
  4) Exit
=====================================================
Please choose an option [1-4]: 
```

También puedes pasar opciones directamente por línea de comandos para ejecución no interactiva:
```bash
# Instalación directa
./setup.sh --install

# Actualización directa (descarga cambios de git y los vuelve a aplicar)
./setup.sh --update

# Desinstalación directa (restaura los archivos originales)
./setup.sh --uninstall
```

El script detecta automáticamente las carpetas de Caelestia de tu usuario y del sistema, respalda los archivos originales, genera las miniaturas iniciales y **reinicia automáticamente la shell de Caelestia** para tu sesión activa.

Si alguna vez necesitas reiniciar la shell manualmente, simplemente ejecuta:
```bash
caelestia shell
```
(o presiona `Ctrl+Super+Alt+R`).

## Agradecimientos

Agradecimientos especiales a [**AdiAmbassador**](https://github.com/adiambassador) por la inspiración detrás de este proyecto. Y por supuesto, muchísimas gracias al equipo de **Caelestia**.
