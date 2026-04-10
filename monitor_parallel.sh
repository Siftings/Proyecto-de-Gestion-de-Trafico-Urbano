#!/bin/bash

# Script para monitorear 3 PCs en paralelo
# Crea logs locales que puedes monitorear

mkdir -p /tmp/trafico_monitor
LOG_PC1="/tmp/trafico_monitor/pc1.log"
LOG_PC2="/tmp/trafico_monitor/pc2.log"
LOG_PC3="/tmp/trafico_monitor/pc3.log"

> $LOG_PC1
> $LOG_PC2
> $LOG_PC3

echo "Monitoreando 3 PCs..."
echo "Logs en:"
echo "  PC1: $LOG_PC1"
echo "  PC2: $LOG_PC2"
echo "  PC3: $LOG_PC3"
echo ""

# PC1
(
  echo "[$(date)] Conectando a PC1..." >> $LOG_PC1
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 estudiante@10.43.99.128 \
    "cd ~/trafico_urbano && bash lanzar_pc1.sh && tail -f logs/broker.log logs/cam_C5.log logs/gps_C5.log" 2>&1 >> $LOG_PC1
) &
PID_PC1=$!

# PC2
(
  echo "[$(date)] Conectando a PC2..." >> $LOG_PC2
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 estudiante@10.43.100.144 \
    "cd ~/trafico_urbano && bash lanzar_pc2.sh && tail -f logs/analitica.log logs/semaforos.log logs/bd_replica.log" 2>&1 >> $LOG_PC2
) &
PID_PC2=$!

# PC3
(
  echo "[$(date)] Conectando a PC3..." >> $LOG_PC3
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 estudiante@10.43.100.90 \
    "cd ~/trafico_urbano && bash lanzar_pc3.sh && tail -f logs/bd_principal.log" 2>&1 >> $LOG_PC3
) &
PID_PC3=$!

echo "PIDs: PC1=$PID_PC1, PC2=$PID_PC2, PC3=$PID_PC3"
echo ""
echo "En otra terminal, ejecuta:"
echo "  tail -f /tmp/trafico_monitor/pc1.log /tmp/trafico_monitor/pc2.log /tmp/trafico_monitor/pc3.log"
echo ""
echo "O monitorea cada uno por separado:"
echo "  tail -f /tmp/trafico_monitor/pc1.log"
echo "  tail -f /tmp/trafico_monitor/pc2.log"
echo "  tail -f /tmp/trafico_monitor/pc3.log"
echo ""
echo "Presiona Ctrl+C aquí para terminar todas las conexiones"
echo ""

wait $PID_PC1 $PID_PC2 $PID_PC3
echo "Todas las conexiones terminadas."
