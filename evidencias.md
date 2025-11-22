# EVIDENCIAS DE VALIDACIÓN - PC03  
**Sinclair Omar García Arellano**

---

## 🟨 FASE 1 – Integridad Temporal  
**Prueba ejecutada:**  
Se envió un mensaje malicioso con timestamp del año 2050 a través del chaos script.

**Resultado esperado:**  
El sistema debe rechazar el mensaje por estar fuera de la ventana temporal (±2000 ms),  
a menos que cumpla con causalidad (Lamport + Vector Clock).

**Log capturado:**


✔ **Validación correcta:** El sistema bloqueó el mensaje anómalo.  

---

## 🟦 FASE 2 – Consenso y Anti Split-Brain  
**Prueba ejecutada:**  
Se pausó el contenedor que actuaba como líder utilizando `docker pause`,  
provocando que el cluster iniciara una nueva elección usando quórum 3/5.

**Resultado esperado:**  
- Un nuevo líder debe levantarse.  
- El líder anterior debe detectar presencia de un nuevo líder y hacer *Stepping down*.  

**Logs capturados:**


✔ **Validación correcta:** No ocurrió split-brain.  
✔ El cluster mantuvo consistencia usando Leases + Quórum.  

---

## 🟥 FASE 3 – Persistencia y Recuperación (WAL)  
**Prueba ejecutada:**  
Se generó actividad (peticiones) y luego se reinició de forma abrupta el supuesto líder  
con `docker restart publisher-5`.

**Resultado esperado:**  
Al reiniciar, el publisher debe reconstruir la cola de solicitudes usando su archivo WAL.

**Log capturado:**


✔ **Validación correcta:**  
El líder restauró su estado previo al crash sin perder solicitudes.

---

## 🟩 CONCLUSIÓN FINAL  
El sistema pasó las **tres fases** del protocolo PC03:

- ✔ Integridad temporal  
- ✔ Consenso distribuido (Leases + Quórum + Anti Split-Brain)  
- ✔ Persistencia y recuperación mediante WAL  

El script `chaos-ultimate.sh` completó la evaluación **sin errores**,  
confirmando que la solución es consistente, tolerante a fallos  
y cumple con los requerimientos del examen.

---
