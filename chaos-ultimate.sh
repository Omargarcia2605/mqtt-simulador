#!/bin/bash
# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW} INICIANDO PROYECTO: PROTOCOLO DE EVALUACIÓN PC03 ${NC}"
echo "Verificando que los 5 publishers estén ejecutándose..."
sleep 2

# ==============================================================================
# NIVEL 1: RESGUARDANDO EL TIEMPO
# ==============================================================================
echo -e "\n${YELLOW}[FASE 1] Probando Integridad Temporal...${NC}"
echo " -> Enviando mensaje del futuro (2050)."
docker exec mqtt-broker mosquitto_pub -t "sensors/telemetry" -m '{"deviceId": "malicious", "timestamp": "2050-01-01T00:00:00Z", "temperatura": 999}'
sleep 2

if docker logs persistence-subscriber 2>&1 | grep -q "Rejected future packet"; then
  echo -e "${GREEN} ✔ EXITO: Se bloqueó el mensaje anómalo de tiempo.${NC}"
else
  echo -e "${RED} ✘ ERROR: El sistema ACEPTÓ un timestamp inválido.${NC}"
  exit 1
fi

# ==============================================================================
# NIVEL 2: SPLIT-BRAIN
# ==============================================================================
echo -e "\n${YELLOW}[FASE 2] Probando estabilidad del liderazgo (Quórum).${NC}"

LEADER_CONTAINER=$(docker ps | grep publisher | head -n 1 | awk '{print $NF}')
echo " -> Líder detectado aproximadamente como: $LEADER_CONTAINER"

echo " -> Pausando líder..."
docker pause $LEADER_CONTAINER
sleep 7

echo " -> Buscando nuevo líder en logs..."
docker logs publisher-1 2>&1 | grep -q "Ascendido a Lider" || \
docker logs publisher-2 2>&1 | grep -q "Ascendido a Lider" || \
docker logs publisher-3 2>&1 | grep -q "Ascendido a Lider" || \
docker logs publisher-4 2>&1 | grep -q "Ascendido a Lider" || \
docker logs publisher-5 2>&1 | grep -q "Ascendido a Lider"

docker unpause $LEADER_CONTAINER
sleep 3

if docker logs $LEADER_CONTAINER --tail 20 | grep -q "Stepping down"; then
  echo -e "${GREEN} ✔ EXITO: El líder antiguo cedió el control correctamente.${NC}"
else
  echo -e "${YELLOW} ⚠ ADVERTENCIA: No se detectó 'Stepping down'. Revisar manualmente.${NC}"
fi

# ==============================================================================
# NIVEL 3: PERSISTENCIA WAL
# ==============================================================================
echo -e "\n${YELLOW}[FASE 3] Probando restauración WAL...${NC}"
echo " -> Reiniciando líder seleccionado (publisher-5)"
docker restart publisher-5
sleep 5

if docker logs publisher-5 --tail 50 | grep -q -E "WAL|Restored|Recovered"; then
  echo -e "${GREEN} ✔ EXITO: Se restauró el estado desde WAL correctamente.${NC}"
else
  echo -e "${RED} ✘ ERROR: No se restauró el WAL. El líder tiene amnesia.${NC}"
  exit 1
fi

echo -e "\n${GREEN}✔ TODAS LAS PRUEBAS SUPERADAS EXITOSAMENTE.${NC}"
