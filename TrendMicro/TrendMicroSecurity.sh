#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

remove_files() {
	[[ -f "TrendMicroSecurity.sh" ]] && rm -f TrendMicroSecurity.sh
}

FILENAME="/opt/TM_Agent.tar"
DIR="/opt/TM_Agent"

install_es() {
	echo -e "${YELLOW}Starting Trend Micro agent installation...${NC}"

	mkdir -p "$DIR"

	while true; do
		read -p "Trend Micro URL: " URL
		[[ -z "$URL" ]] && echo -e "${RED}[ERROR] URL must not be empty.${NC}" && continue

		echo -e "${YELLOW}[INFO] Downloading installer...${NC}"
		if curl -fL "$URL" -o "$FILENAME"; then
			echo -e "${GREEN}[OK] Download completed successfully.${NC}"
			break
		else
			echo -e "${RED}[ERROR] Failed to download the file. Please try again.${NC}"
			[[ -f "$FILENAME" ]] && rm -f "$FILENAME"
		fi
	done

	echo -e "${BLUE}[INFO] Extracting installer to $DIR...${NC}"
	if ! tar -xf "$FILENAME" -C "$DIR"; then
		echo -e "${RED}[FAIL] Failed to extract the archive.${NC}"
		rm -f "$FILENAME"
		return 1
	fi

	if [[ -x "$DIR/tmxbc" ]]; then
		echo -e "${YELLOW}[INFO] Installing Trend Micro agent...${NC}"

		if sudo "$DIR/tmxbc" install; then
			echo -e "${GREEN}[OK] Trend Micro agent installed successfully.${NC}"
			rm -f "$FILENAME"

			echo -e "${YELLOW}[INFO] Checking tmxbc service status...${NC}"
			if command -v systemctl >/dev/null 2>&1; then
				systemctl status tmxbc --no-pager
			else
				/etc/init.d/tmxbc status
			fi
		else
			echo -e "${RED}[ERROR] Trend Micro agent installation failed.${NC}"
			return 1
		fi
	else
		echo -e "${RED}[ERROR] tmxbc installer not found or not executable at $DIR/tmxbc.${NC}"
		return 1
	fi
}

install_swp() {
	echo -e "${YELLOW}Starting Trend Micro agent installation...${NC}"

	mkdir -p "$DIR"

	while true; do
		read -p "Trend Micro URL: " URL
		[[ -z "$URL" ]] && echo -e "${RED}[ERROR] URL must not be empty.${NC}" && continue

		echo -e "${YELLOW}[INFO] Downloading installer...${NC}"
		if curl -fL "$URL" -o "$FILENAME"; then
			echo -e "${GREEN}[OK] Download completed successfully.${NC}"
			break
		else
			echo -e "${RED}[ERROR] Failed to download the file. Please try again.${NC}"
			rm -f "$FILENAME" 2>/dev/null
		fi
	done

	echo -e "${BLUE}[INFO] Extracting installer to $DIR...${NC}"
	if ! tar -xf "$FILENAME" -C "$DIR"; then
		echo -e "${RED}[FAIL] Failed to extract the archive.${NC}"
		rm -f "$FILENAME"
		return 1
	fi

	if [[ -x "$DIR/tmxbc" ]]; then
		echo -e "${YELLOW}[INFO] Installing Trend Micro agent...${NC}"
		if ! sudo "$DIR/tmxbc" install; then
			echo -e "${RED}[ERROR] Trend Micro agent installation failed.${NC}"
			return 1
		fi
	else
		echo -e "${RED}[ERROR] tmxbc installer not found or not executable.${NC}"
		return 1
	fi

	rm -f "$FILENAME"

	echo -e "${YELLOW}🔎 Waiting for ds_agent and tmxbc services to be running...${NC}"

	while true; do
		DS_OK=0
		TM_OK=0

		echo -e "${YELLOW}🔎 ds_agent status:${NC}"
		if command -v systemctl &>/dev/null; then
			systemctl is-active ds_agent &>/dev/null && DS_OK=1 || systemctl status ds_agent --no-pager || true
		elif command -v service &>/dev/null; then
			service ds_agent status && DS_OK=1 || true
		fi

		echo -e "${YELLOW}🔎 tmxbc status:${NC}"
		if command -v systemctl &>/dev/null; then
			systemctl is-active tmxbc &>/dev/null && TM_OK=1 || systemctl status tmxbc --no-pager || true
		elif command -v service &>/dev/null; then
			service tmxbc status && TM_OK=1 || true
		fi

		if [[ $DS_OK -eq 1 && $TM_OK -eq 1 ]]; then
			echo -e "${GREEN}✅ ds_agent and tmxbc are running${NC}"
			break
		fi

		sleep 5
	done
}

uninstall_tm() {
	echo -e "${YELLOW}Stopping Trend Micro services...${NC}"

	if command -v systemctl >/dev/null 2>&1; then
		sudo systemctl stop tmxbc ds_agent 2>/dev/null || true
	else
		sudo /etc/init.d/tmxbc stop 2>/dev/null || true
		sudo /etc/init.d/ds_agent stop 2>/dev/null || true
	fi

	echo -e "${YELLOW}[INFO] Removing Trend Micro agent...${NC}"

	if command -v tmxbc >/dev/null 2>&1; then
		sudo tmxbc uninstall || true
	elif [[ -x "$DIR/tmxbc" ]]; then
		sudo $DIR/tmxbc uninstall || true
	fi

	if command -v rpm >/dev/null 2>&1; then
		echo -e "${BLUE}[INFO] RPM-based system detected${NC}"
		sudo rpm -ev ds_agent || true
	elif command -v dpkg >/dev/null 2>&1; then
		echo -e "${BLUE}[INFO] Debian-based system detected${NC}"
		sudo dpkg -r ds-agent || true
		sudo dpkg --purge ds-agent || true
	else
		echo -e "${RED}[ERROR] Package manager not detected (rpm/dpkg).${NC}"
		return 1
	fi

	echo -e "${YELLOW}[INFO] Checking service status after uninstall...${NC}"

	if command -v systemctl >/dev/null 2>&1; then
		if systemctl list-unit-files | grep -q '^tmxbc'; then
			systemctl status tmxbc --no-pager || true
		else
			echo -e "${GREEN}[OK] tmxbc service not found (removed).${NC}"
		fi
	else
		if [ -x /etc/init.d/tmxbc ]; then
			/etc/init.d/tmxbc status || true
		else
			echo -e "${GREEN}[OK] tmxbc init script not found (removed).${NC}"
		fi
	fi

	if command -v systemctl >/dev/null 2>&1; then
		if systemctl list-unit-files | grep -q '^ds_agent'; then
			systemctl status ds_agent --no-pager || true
		else
			echo -e "${GREEN}[OK] ds_agent service not found (removed).${NC}"
		fi
	else
		if [ -x /etc/init.d/ds_agent ]; then
			/etc/init.d/ds_agent status || true
		else
			echo -e "${GREEN}[OK] ds_agent init script not found (removed).${NC}"
		fi
	fi
	rm -rf $DIR /opt/TrendMicro/
	
	echo -e "${GREEN}[OK] Trend Micro agent uninstall completed.${NC}"
}

while true; do
	echo -e "${CYAN}🚀 Menu:${NC}"
	echo "1) 🔽 Install Endpoint Sensor"
	echo "2) 🔽 Install Server & Workload Protection"
	echo "3) 🔧 Uninstall Agent"
	echo "4) ❌ Exit"
	read -p "$(echo -e ${CYAN}👉 Choice [1-4]: ${NC}) " choice

	case $choice in
	1) install_es ;;
	2) install_swp ;;
	3) uninstall_tm ;;
	4)
		echo -e "${GREEN}👋 Bye!${NC}"
		remove_files
		exit 0
		;;
	*) echo -e "${RED}❌ Invalid Choice. Try again.${NC}" ;;
	esac

	echo
done
