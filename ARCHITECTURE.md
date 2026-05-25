# Arquitectura del Ecosistema odoo-ai v3

> El núcleo inteligente de orquestación de agentes y adaptadores para la ingeniería de sistemas en Odoo.

---

## 1. Visión General del Ecosistema

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
flowchart LR
    Dev["Desarrollador"] -->|Ejecuta comandos| CLI["Claude Code CLI"]
    CLI -->|Carga/Usa| Adp["Adaptadores Core"]
    subgraph Motores["Adaptadores de Ejecución"]
        Adp -->|Razonamiento complejo| Cl["Claude Code"]
        Adp -->|Documentación / exploración| Agy["Antigravity (agy)"]
        Adp -->|Generación de código| Cx["Codex"]
        Adp -->|Completado inline| Cp["Copilot"]
    end
    subgraph Orq["Orquestador"]
        Iris["Iris MCP Server\norquesta fases SDD"]
    end
    Iris -->|Delega via iris_delegate| CLI
```

---

## 2. Flujo de Orquestación SDD

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
sequenceDiagram
    autonumber
    actor Dev as Desarrollador
    participant Cl as Claude (Antigravity)
    participant Del as Orquestador SDD
    participant Sel as Selector (selector.ts)
    participant Adp as Adaptadores (agy/codex)
    participant Eng as Engram IPC
    
    Dev->>Cl: Inicia flujo SDD (/sdd new)
    Cl->>Del: Delega ejecución del plan
    Del->>Sel: Consulta enrutador de fases
    Sel->>Adp: Selecciona adaptador óptimo
    Adp->>Eng: Persiste estado y observaciones
    Eng-->>Adp: Retorna confirmación IPC
    Adp-->>Del: Devuelve resultados de fase
    Del-->>Cl: Sincroniza estado de ejecución
    Cl-->>Dev: Presenta propuesta / spec
```

---

## 3. Phase→Adapter Routing

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
flowchart TD
    subgraph Fases["Fases del Proceso SDD"]
        direction TB
        F1["explore / propose"]
        F2["spec / tasks / verify"]
        F3["design / apply"]
        F4["document / report"]
    end

    subgraph Adaptadores["Motores de Destino"]
        direction TB
        A_Cl["Claude (Principal)"]
        A_Ag["Agy (Agente Local)"]
        A_Cx["Codex (ORM Engine)"]
        A_Cp["Copilot (Frontend)"]
    end

    F1 -->|Principal| A_Cl
    F1 -.->|Fallback| A_Ag

    F2 -->|Principal| A_Ag
    F2 -.->|Fallback| A_Cl

    F3 -->|Principal| A_Cx
    F3 -.->|Fallback| A_Ag

    F4 -->|Principal| A_Cp
    F4 -.->|Fallback| A_Cl
```

### Tabla de Ruteo de Fases

| Fase | Adapter Principal | Fallback | Razón |
| :--- | :--- | :--- | :--- |
| **explore** | Claude | Agy | Análisis semántico avanzado de código y dependencias. |
| **propose** | Claude | Agy | Generación de propuestas de alto nivel alineadas al negocio. |
| **spec** | Agy | Claude | Precisión técnica y modelamiento de escenarios BDD/TDD. |
| **design** | Claude | Codex | Arquitectura de patrones y consistencia en el diseño del sistema. |
| **tasks** | Agy | Claude | Desglose granular de tareas ejecutables con criterios de aceptación. |
| **apply** | Codex | Agy | Alta eficiencia en generación de modelos Odoo, backend y ORM. |
| **verify** | Agy | Claude | Validación robusta de pruebas de integración y cobertura. |
| **document** | Copilot | Claude | Redacción fluida de documentación técnica y manuales de usuario. |
| **report** | Copilot | Claude | Reportes detallados y análisis estructurado del ciclo de vida. |

---

## 4. Engram IPC Pipeline

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
sequenceDiagram
    autonumber
    participant Iris as Iris (Orquestador Externo)
    participant Eng as Engram (Memoria)
    participant Ag as Agente Agy
    
    Iris->>Eng: Guarda prompt tarea - saveTaskPrompt(obsId)
    Note over Eng: Observación persistida
    Ag->>Eng: Recupera prompt - mem_get_observation(obsId)
    Eng-->>Ag: Retorna instrucciones de tarea
    Note over Ag: Procesa la tarea y genera resultados
    Ag->>Eng: Guarda resultado - mem_save(output)
    Ag->>Eng: Cambia estado - mem_save(DONE:taskId)
    loop Bucle de Sondeo (Polling)
        Iris->>Eng: Monitorea estado de tarea
        Eng-->>Iris: Retorna estado actual
    end
    Note over Iris: Detecta estado DONE
    Iris->>Iris: Completa tarea - completeTask()
```

---

## 5. Skills Hub Architecture

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
flowchart TD
    subgraph Hubs["Skills Hub Architecture"]
        direction TB
        HubAI["Hub odoo-ai"]
        HubContribute["Hub odoo-contribute"]
    end

    subgraph PluginsAI["Plugins odoo-ai"]
        direction LR
        P_Source["odoo-source"]
        P_Dev["odoo-development"]
        P_Alesco["odoo-dev-alesco"]
    end

    subgraph PluginsContribute["Plugins odoo-contribute"]
        direction LR
        P_OCA["odoo-oca"]
        P_Mod["odoo-module"]
        P_Cmt["odoo-commit"]
        P_PR["odoo-pr"]
        P_CI["odoo-ci"]
        P_Ops["odoo-ops"]
        P_View["odoo-overview"]
    end

    HubAI -->|Contiene plugins| PluginsAI
    HubContribute -->|Contiene plugins| PluginsContribute
```

---

## 6. Decisiones de Arquitectura

| Decisión | Alternativas consideradas | Razón elegida | Trade-offs |
| :--- | :--- | :--- | :--- |
| **Engram como IPC en lugar de archivos .txt** | Archivos locales temporales .txt, Redis local, base de datos PostgreSQL. | Mayor robustez de persistencia entre reinicios de contenedores/sesiones y acoplamiento nativo con la memoria a largo plazo del ecosistema. | Ligera latencia adicional de red (milisegundos) en la serialización, pero se gana aislamiento absoluto del filesystem. |
| **fire_and_forget para tareas de documentación** | Espera síncrona en hilo de ejecución bloqueante. | Los reportes e informes de documentación tardan más tiempo y no deben bloquear el flujo de desarrollo activo de código. | Requiere monitoreo asíncrono secundario, pero incrementa significativamente la velocidad de respuesta del orquestador. |
| **Phase→adapter routing estático vs dinámico** | Enrutamiento dinámico basado en LLM Router. | Mayor determinismo técnico y menor consumo de tokens al asignar fases predecibles a adaptadores óptimos. | Menor adaptabilidad automática ante tareas altamente atípicas, pero mayor fiabilidad en producción. |
| **confirm_threshold como two-phase commit** | Commit directo de una sola fase (Auto-commit). | Garantiza que tanto la memoria del agente como los archivos físicos estén sincronizados antes de marcar la fase como exitosa. | Aumento en el número de operaciones de red, pero elimina por completo los estados inconsistentes. |
| **summary truncado en lugar de output completo** | Retorno de outputs completos en cada llamada del CLI. | Prevención del desbordamiento del contexto de la conversación (bloat), lo que preserva la consistencia semántica. | El orquestador debe consultar explícitamente Engram para obtener detalles finos de la ejecución si los requiere. |
| **CodeGraph para búsqueda estructural** | Búsqueda exacta de cadenas por ripgrep (grep), Semble (semántico). | AST real via tree-sitter: ~57% menos tokens y ~71% menos tool calls. Sub-millisecond lookups. Sin indexación periódica — file watcher automático. | Requiere inicialización del índice (`codegraph init`), pero no depende de vectores semánticos ni embeddings. |

---

## 7. Flujo de Datos

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#0d1117', 'primaryColor': '#161b22', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#22d3ee', 'secondaryColor': '#1e1e2e', 'secondaryTextColor': '#FFFFFF', 'secondaryBorderColor': '#a855f7', 'tertiaryColor': '#0d2a2a', 'tertiaryTextColor': '#FFFFFF', 'tertiaryBorderColor': '#22d3ee', 'lineColor': '#a855f7', 'textColor': '#e6edf3', 'clusterBkg': '#0a1628', 'clusterBorder': '#22d3ee'}}}%%
flowchart LR
    Eng["Engram (Memoria)"] <-->|Sincroniza estado| Core["odoo-ai Core"]
    Core <-->|Enruta tareas| Adp["Adaptadores (Ejecutores)"]
    Adp <-->|Consulta contexto| CG["CodeGraph (AST)"]
    CG <-->|Indexa símbolos| Eng
```

---

## Integraciones del Ecosistema

| Herramienta | Repositorio | Rol | Relación |
|-------------|-------------|-----|----------|
| Iris MCP Server | github.com/Geraldow/iris | Orquestador multi-agente: delega tareas SDD a Claude, Gemini, Codex, Copilot según la fase | Integración externa — proyecto separado |
| Engram | engram.sh | Memoria persistente cross-session | Dependencia directa |
| CodeGraph | github.com/colbymchenry/codegraph | Búsqueda estructural de código AST (tree-sitter), MCP server | Dependencia directa |
