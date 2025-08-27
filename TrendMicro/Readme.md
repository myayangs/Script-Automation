# 🛠️ TrendMicro Agent Installer

Panduan ini untuk install/uninstall **TrendMicro Agent** menggunakan script `trendmicro.sh`.

---

## 📥 Download & Jalankan Script
```bash
curl -O https://example.com/trendmicro.sh
chmod +x trendmicro.sh
./trendmicro.sh
```

---

## 🚀 Menu Pilihan
```
1) 🔽 Install TrendMicro
2) 🔧 Uninstall TrendMicro
3) ❌ Exit
```

---

## 🔽 Install Agent
- Pilih **1**  
- Masukkan URL TrendMicro Agent `.tar` (contoh: `https://example.com/TrendMicro_Agent.tar`)  
- Script akan:
  - Download → Extract → Install  
  - Cek service `ds_agent`  

✅ Jika sukses → tampil:
```
TrendMicro installed successfully!
```

---

## 🗑️ Uninstall Agent
- Pilih **2**  
- Script otomatis hapus agent sesuai OS:
  - RPM-based → `rpm -ev ds_agent`
  - Debian-based → `dpkg -r ds-agent && dpkg --purge ds-agent`

✅ Jika sukses → tampil:
```
TrendMicro agent removed successfully!
```

---
