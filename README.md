[![Stars](https://img.shields.io/github/stars/MatthyGD/BruteX?style=for-the-badge&color=00e6c8&labelColor=0d1117&logo=github)](https://github.com/MatthyGD/BruteX/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/MatthyGD/BruteX?style=for-the-badge&color=78b4ff&labelColor=0d1117&logo=git&logoColor=white)](https://github.com/MatthyGD/BruteX/commits)
[![Language](https://img.shields.io/badge/Shell-Bash-ff5ab4?style=for-the-badge&logo=gnubash&logoColor=white&labelColor=0d1117)](https://github.com/MatthyGD/BruteX)
[![Platform](https://img.shields.io/badge/Platform-Linux-557C94?style=for-the-badge&logo=linux&logoColor=white&labelColor=0d1117)](https://github.com/MatthyGD/BruteX)
[![Ethics](https://img.shields.io/badge/Use-Ethical%20Only-64f082?style=for-the-badge&labelColor=0d1117)](https://github.com/MatthyGD/BruteX)
 
---
 
## ⚠️ Precaución
 
> 👮 Usa la herramienta **solo con autorización** o en entornos controlados.
> 👮 BruteX está pensada únicamente para **fines éticos, educativos o de investigación**.
> 👮 No se recomienda ni se respalda su uso en sistemas sin permiso explícito.
>
> El autor no se hace responsable del mal uso de esta herramienta. La responsabilidad recae por completo en quien la ejecuta.
 
---
 
<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:ff5a6e,100:ff5ab4&height=220&section=header&text=BruteX&fontSize=72&fontColor=ffffff&animation=twinkling&fontAlignY=40&desc=Advanced%20Password%20Cracking%20Tool%20%E2%80%94%20by%20MatthyGD&descSize=18&descAlignY=62&descColor=ffc0d0" />
<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=18&duration=3000&pause=800&color=FF5A6E&center=true&vCenter=true&width=700&lines=Parallel+Dictionary+Attack+via+su;Auto-detects+All+Interactive+Users;nproc+%C3%97+users+Concurrent+Jobs;Real-time+Progress+%2B+ETA+Display" alt="Typing SVG" />
</div>
---
 
## 💥 ¿Qué es BruteX?
 
**BruteX** es una herramienta de ataque de diccionario local para sistemas Linux. Detecta automáticamente todos los usuarios con shells interactivas y lanza un ataque de fuerza bruta contra todos ellos de forma **simultánea y paralela**, sin esperar a que un usuario termine para pasar al siguiente. Ideal para fases de post-explotación, CTF y auditorías de seguridad interna donde ya tienes acceso al sistema.
 
⭐ Detección automática de usuarios con shells interactivas (`bash`, `sh`, `zsh`) con **fallback por UID**
⭐ Ataque de diccionario **paralelo** contra todos los usuarios encontrados a la vez
⭐ **Pool de jobs concurrentes** escalable: `nproc × usuarios` con mínimo 4 jobs simultáneos
⭐ Barra de progreso dinámica con **porcentaje**, **ETA** y contraseña en prueba en tiempo real
⭐ Reporte automático de credenciales encontradas guardado en archivo `.txt` con timestamp
 
---
 
## ✨ Características
 
| | Feature | Descripción |
|---|---|---|
| 🎨 | Paleta truecolor | Degradado cian → magenta con fallback automático a 8 colores |
| 🧭 | Salida estructurada | 4 secciones claras con cabeceras degradadas y mensajes de estado |
| ⚡ | Paralelismo real | Jobs concurrentes controlados por pool — no secuencial sino simultáneo |
| 📊 | Progreso dinámico | `[%]` + `línea/total` + ETA calculado + contraseña en prueba visible |
| 💾 | Guardado automático | Credenciales en `brutex_YYYYMMDD_HHMMSS.txt` al finalizar |
| 🔒 | Interrupción limpia | `Ctrl+C` drena jobs activos y muestra resumen parcial antes de salir |
| 🔍 | Detección dual | Shell válida primero, fallback por rango de UID (1000–60000) |
 
---
 
## 🔎 Flujo de ataque
 
| Fase | Sección | Descripción |
|---|---|---|
| `1` | 👤 USER DETECTION | Escanea `/etc/passwd` por usuarios con `bash`, `sh` o `zsh`. Fallback por UID si no encuentra resultados. Muestra shell y home de cada uno. |
| `2` | ⚙️ ATTACK CONFIGURATION | Confirma el wordlist cargado, número total de contraseñas y usuarios objetivo antes de comenzar. |
| `3` | 💥 BRUTE FORCE ATTACK | Por cada contraseña lanza `_test_user` en paralelo para cada usuario no crackeado. El pool `nproc × usuarios` evita saturar la máquina. Reporta credenciales al instante. |
| `4` | 📊 ATTACK SUMMARY | Listado de usuarios crackeados con sus contraseñas, ruta del archivo guardado y tiempo total de ejecución. |
 
---
 
## 📦 Requisitos
 
BruteX usa únicamente utilidades estándar — no requiere instalación de dependencias externas:
 
| Herramienta | Paquete | Función |
|---|---|---|
| `bash` 4.0+ | Preinstalado | Ejecución del script y arrays asociativos |
| `su` | Preinstalado | Prueba de credenciales contra PAM |
| `timeout` | `coreutils` | Límite de tiempo por intento de autenticación |
| `getent` | `libc-bin` | Lectura de usuarios del sistema |
| `nproc` | `coreutils` | Detección de cores para el pool de jobs |
 
> 💡 Para ver el banner con degradado a todo color usa una terminal con soporte **truecolor**.
 
> 🔑 BruteX está diseñada para ejecutarse como **usuario no-root** desde una sesión comprometida — `su` requiere autenticación PAM correcta en ese contexto.
 
---
 
## 🚀 Instalación y uso
 
🔴 Clonar el repositorio
 
```bash
git clone https://github.com/MatthyGD/BruteX.git
```
 
🔴 Entrar en el directorio
 
```bash
cd BruteX/
```
 
🔴 Garantizar permisos de ejecución
 
```bash
chmod +x BruteX.sh
```
 
🔴 Desplegar con un wordlist
 
```bash
./BruteX.sh -w <wordlist.txt>
```
 
🔴 Diccionarios recomendados — proporcionados por **d4t4s3c**
 
```bash
wget --no-check-certificate -q "https://raw.githubusercontent.com/VulNyx/Arsenal/refs/heads/main/suForce/techyou.txt"
wget --no-check-certificate -q "https://raw.githubusercontent.com/VulNyx/Arsenal/refs/heads/main/suForce/top12000.txt"
```
 
### Opciones
 
| Opción | Descripción |
|---|---|
| `-w <wordlist>` | Especifica el archivo de diccionario a utilizar |
| `-h` | Muestra la ayuda |
 
---
 
## 🧭 Demostración de uso
 
✅ **1 → Detección de usuarios**
 
BruteX escanea el sistema y lista todos los usuarios con shells interactivas, mostrando su shell y directorio home. Si el método principal falla, usa un fallback por rango de UID para no dejar ningún usuario fuera.
 
✅ **2 → Configuración del ataque**
 
Muestra el wordlist cargado, el número total de contraseñas y los usuarios objetivo. Todo verificado antes de disparar el ataque para evitar errores de configuración.
 
✅ **3 → Ataque en curso**
 
Barra de progreso dinámica con porcentaje, línea actual sobre total, ETA y contraseña en prueba. Las credenciales encontradas aparecen en pantalla al instante sin detener el ataque. Si todos los usuarios son crackeados, se detiene automáticamente.
 
✅ **4 → Resumen final**
 
Listado de usuarios crackeados con sus contraseñas, ruta del archivo `.txt` guardado con timestamp y tiempo total de ejecución del ataque. Si se interrumpió con `Ctrl+C`, muestra el resumen parcial de lo encontrado hasta ese momento.
 
---
 
<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:ff5ab4,100:0d1117&height=120&section=footer" />

Desarrollado por MatthyGD (https://github.com/MatthyGD)
</div>
