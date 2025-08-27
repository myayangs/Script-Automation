#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

remove_files() {
  [[ -f "TrendMicroSecurity.sh" ]] && rm -f TrendMicroSecurity.sh
}

FILENAME="/opt/TrendMicro_Agent.tar"
DIR="/opt/TrendMicro_Agent"

install_TrendMicro() {
  echo -e "${YELLOW}🔽 Installing TrendMicro...${NC}"

  mkdir -p "$DIR"

  while true; do
    read -p "🔗 Masukkan URL TrendMicro: " URL
    echo -e "${YELLOW}⏳ Mengunduh file...${NC}"

    if curl -sSL "$URL" -o "$FILENAME"; then
      break
    else
      echo -e "❌ ${RED}Gagal mengunduh file. Silakan coba lagi.${NC}"
      [[ -f "$FILENAME" ]] && rm -f "$FILENAME"
    fi
  done

  echo -e "📦 ${BLUE}Mengekstrak file ke $DIR...${NC}"
  tar -xvf "$FILENAME" -C "$DIR"

  if [ -x "$DIR/tmxbc" ]; then
    sudo "$DIR/tmxbc" install
    echo -e "${GREEN}✅ TrendMicro installed successfully!${NC}"

    echo -e "${YELLOW}🔎 Checking ds_agent service status...${NC}"
    if command -v systemctl &>/dev/null && systemctl >/dev/null 2>&1; then
      systemctl status ds_agent --no-pager || true
    elif command -v service &>/dev/null; then
      service ds_agent status || true
    else
      echo -e "❌ ${RED}Tidak ditemukan systemctl maupun service command.${NC}"
    fi
  else
    echo -e "❌ ${RED}File tmxbc tidak ditemukan atau tidak executable.${NC}"
  fi
}

uninstall_TrendMicro() {
  echo -e "${YELLOW}🗑️ Uninstalling TrendMicro...${NC}"

  if command -v rpm &>/dev/null; then
    echo -e "📦 ${BLUE}Detected RPM-based system${NC}"
    sudo rpm -ev ds_agent || true
  elif command -v dpkg &>/dev/null; then
    echo -e "📦 ${BLUE}Detected Debian-based system${NC}"
    sudo dpkg -r ds-agent || true
    sudo dpkg --purge ds-agent || true
  else
    echo -e "❌ ${RED}Tidak dapat mendeteksi package manager (rpm/dpkg).${NC}"
    return 1
  fi

  echo -e "${GREEN}✅ TrendMicro agent removed successfully!${NC}"
}

while true; do
  echo -e "${CYAN}🚀 Menu:${NC}"
  echo "1) 🔽 Install TrendMicro"
  echo "2) 🔧 Uninstall TrendMicro"
  echo "3) ❌ Exit"
  read -p "$(echo -e ${CYAN}👉 Masukkan pilihan [1-3]: ${NC}) " choice

  case $choice in
  1) install_TrendMicro ;;
  2) uninstall_TrendMicro ;;
  3)
    echo -e "${GREEN}👋 Bye!${NC}"
    remove_files
    exit 0
    ;;
  *) echo -e "${RED}❌ Invalid Choice. Try again.${NC}" ;;
  esac

  echo
done
