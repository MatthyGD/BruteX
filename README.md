## ⚠️ Precaución
 
![WARNING](WARNING-12-12-2024.png)
 
👮 Usa la herramienta solo con autorización o en entornos controlados.  
👮 BruteX está pensada únicamente para fines éticos, educativos o de investigación.  
👮 No se recomienda ni se respalda su uso en sistemas sin permiso explícito.
 
El autor no se hace responsable del mal uso de esta herramienta. La responsabilidad recae por completo en quien la ejecuta.
 
---
 
# 💥 Descubre para Avanzar con BruteX
 
![BruteX](BruteX-banner.png)
 
## 💥 ¿Qué es BruteX?
 
BruteX es una herramienta de ataque de diccionario local para sistemas Linux. Automatiza la detección de usuarios válidos del sistema y lanza un ataque de fuerza bruta contra todos ellos de forma simultánea, ideal para fases de post-explotación, CTF y auditorías de seguridad interna:
 
⭐ Detección automática de usuarios con shells interactivas (`bash`, `sh`, `zsh`)  
⭐ Ataque de diccionario paralelo contra todos los usuarios encontrados a la vez  
⭐ Pool de jobs concurrentes escalable al número de cores de la máquina  
⭐ Progreso en tiempo real con porcentaje, ETA y contraseña en prueba  
⭐ Reporte automático de credenciales comprometidas guardado en archivo `.txt`
 
---
 
## ✨ Características
 
🎨 Banner con degradado truecolor (cian → magenta) y fallback automático a 8 colores en terminales sin soporte de 24 bits.  
🧭 Salida estructurada por secciones con cabeceras degradadas, iconos y mensajes de estado uniformes (✔ ✖ ⚠ ➜).  
⚡ Paralelismo real: lanza un job por usuario de forma concurrente, controlado por un pool basado en `nproc` para no saturar la máquina.  
📊 Barra de progreso dinámica con contraseña actual, línea, porcentaje y tiempo estimado restante (ETA).  
💾 Guarda automáticamente las credenciales encontradas en un archivo `brutex_YYYYMMDD_HHMMSS.txt`.  
🔒 Interrupción limpia: `Ctrl+C` detiene el ataque, espera a que terminen los jobs activos y muestra el resumen parcial.  
🔍 Doble método de detección de usuarios: primero por shell válida, con fallback por UID (1000–60000).
 
---
 
## 🔎 ¿Qué hace BruteX?
 
| Fase | Descripción |
|---|---|
| 👤 Detección de usuarios | Escanea `/etc/passwd` buscando usuarios con shells interactivas (`bash`, `sh`, `zsh`). Fallback por rango de UID si el método principal no encuentra resultados. |
| ⚙️ Configuración del ataque | Muestra el wordlist seleccionado, número de líneas y usuarios objetivo antes de empezar. |
| 💥 Ataque paralelo | Para cada contraseña del diccionario, lanza un job en paralelo por cada usuario no crackeado. El pool se ajusta a `nproc × usuarios` con un mínimo de 4 jobs concurrentes. |
| 📊 Progreso en tiempo real | Barra dinámica con porcentaje, progreso de líneas, ETA calculado y contraseña en prueba visible. |
| ✔ Reporte inmediato | En cuanto se encuentra una credencial válida se muestra en pantalla. Si se crackean todos los usuarios, el ataque se detiene automáticamente. |
| 💾 Guardado de resultados | Las credenciales encontradas se guardan en `brutex_YYYYMMDD_HHMMSS.txt` en el directorio de ejecución. |
 
---
 
## 📦 Requisitos
 
BruteX usa utilidades estándar presentes en la mayoría de distribuciones Linux:
 
- `bash` 4.0+
- `su` — para probar credenciales contra el sistema PAM
- `timeout` — incluido en `coreutils`
- `getent` — incluido en `libc-bin`
> 💡 Para ver el banner con degradado a todo color usa una terminal con soporte truecolor. Si no, BruteX cae automáticamente a colores básicos.
 
> 🔑 BruteX está diseñada para ejecutarse como **usuario no-root** desde una sesión comprometida, ya que `su` requiere autenticación PAM correcta en ese contexto.
 
---
 
## 🚀 Instalación y uso
 
🔴 Clonamos el repositorio
 
```bash
git clone https://github.com/MatthyGD/BruteX.git
```
 
🔴 Entramos dentro del repositorio
 
```bash
cd BruteX/
```
 
🔴 Garantizamos permisos de ejecución
 
```bash
chmod +x BruteX.sh
```
 
🔴 Desplegamos la herramienta con un wordlist
 
```bash
./BruteX.sh -w <wordlist.txt>
```
 
🔴 Descargamos diccionarios optimizados para el ataque (proporcionados por **d4t4s3c**)
 
```bash
wget --no-check-certificate -q "https://raw.githubusercontent.com/VulNyx/Arsenal/refs/heads/main/suForce/techyou.txt"
wget --no-check-certificate -q "https://raw.githubusercontent.com/VulNyx/Arsenal/refs/heads/main/suForce/top12000.txt"
```
 
### Opciones disponibles
 
| Opción | Descripción |
|---|---|
| `-w <wordlist>` | Especifica el archivo de diccionario a utilizar |
| `-h` | Muestra la ayuda |
 
---
 
## 🧭 Demostración de uso
 
✅ **1 → Detección de usuarios**
 
BruteX escanea el sistema y lista los usuarios con shells interactivas, mostrando su shell y directorio home.
 
![USER DETECTION](screenshots/1_user_detection.png)
 
✅ **2 → Configuración del ataque**
 
Muestra el wordlist cargado, el número total de contraseñas y los usuarios objetivo antes de comenzar.
 
![ATTACK CONFIGURATION](screenshots/2_attack_config.png)
 
✅ **3 → Ataque en curso**
 
Barra de progreso dinámica con porcentaje, línea actual sobre total, ETA y contraseña siendo probada en tiempo real. Las credenciales encontradas se muestran en pantalla al instante.
 
![BRUTE FORCE ATTACK](screenshots/3_attack.png)
 
✅ **4 → Resumen final**
 
Listado de usuarios crackeados con sus contraseñas, ruta del archivo de resultados guardado y tiempo total de ejecución.
 
![ATTACK SUMMARY](screenshots/4_summary.png)
 
---
 
## ❤️ ¡Hasta aquí todo!
 
Si BruteX te resulta útil, ⭐ deja una estrella en el repositorio y comparte tu feedback. ¡Gracias por usarla!
