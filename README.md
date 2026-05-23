# 🧥 La Chapita - Gestión de Deudores

Aplicación de escritorio para Windows desarrollada en **Flutter** que permite gestionar clientes, deudas y pagos de una tienda de ropa.

## 🎨 Características

- ✨ **Interfaz elegante** con paleta de colores vainilla/negro
- 👥 **Gestión de clientes**: agregar, editar, eliminar y buscar
- 💰 **Control de deudas**: registrar productos, cantidades y precios
- 💵 **Pagos parciales**: seguimiento de pagos y saldos pendientes
- 📊 **Dashboard interactivo** con estadísticas y alertas
- ⏰ **Alertas automáticas** para deudas vencidas (+30 y +60 días)
- 💾 **Base de datos local** (SQLite) - sin conexión a internet
- 🖼️ **Logo y branding** personalizable

## 🛠️ Tecnologías utilizadas

| Tecnología | Propósito |
|------------|-----------|
| Flutter 3.22.3 | Framework UI multiplataforma |
| Dart | Lenguaje de programación |
| SQLite + sqflite | Base de datos local |
| Riverpod | Manejo de estado |
| Google Fonts | Tipografías (Cormorant Garamond + Inter) |
| flutter_animate | Animaciones fluidas |

## 🎨 Paleta de colores

| Color | Código | Uso |
|-------|--------|-----|
| Vainilla | `#FFF2B3` | Primario, acentos |
| Negro | `#111111` | Fondos principales |
| Blanco | `#FFFFFF` | Texto sobre negro |
| Gris | `#777777` | Textos secundarios |

## 🚀 Instalación

### Requisitos previos

- Windows 10/11
- Flutter SDK 3.22.3
- Visual Studio 2022 (con desarrollo para escritorio C++)

### Clonar y ejecutar

```bash
git clone https://github.com/tuusuario/la_chapita.git
cd la_chapita
flutter pub get
flutter run -d windows