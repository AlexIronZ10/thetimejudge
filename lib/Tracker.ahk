#Requires AutoHotkey v2.0

; --- Configuración de Persistencia ---
; Buscamos un nombre de archivo disponible para evitar sobrescribir sesiones previas
Global TodayLog := GetNewLogName()
; Variables de estado para comparar el contexto actual frente al anterior
Global CurrentTitle := ""
Global StartTime := A_TickCount

/**
 * Genera un nombre de archivo incremental (Activity_Log2, 3...) en la carpeta "logs"
 * para asegurar que cada ejecución sea tratada como una sesión independiente
 * sin riesgo de pérdida de datos por colisión de nombres.
 */
GetNewLogName(BaseName := "Activity_Log") {
    CarpetaLogs := A_ScriptDir "\logs"
    if !DirExist(CarpetaLogs)
        DirCreate(CarpetaLogs)
    Loop {
        ActualName := (A_Index == 1) ? BaseName ".json" : BaseName A_Index ".json"
        if !FileExist(CarpetaLogs "\" ActualName)
            return CarpetaLogs "\" ActualName
    }
}

/**
 * Función núcleo que detecta el cambio de contexto del usuario.
 * Se encarga de cerrar el ciclo de tiempo de la ventana anterior 
 * y abrir el de la nueva tarea activa.
 */
TrackActivity() {
    Global CurrentTitle, StartTime
    ActiveTitle := "System/Idle"
    
    Try {
        ; Intentamos capturar el título, pero usamos un bloque Try porque Windows
        ; puede fallar al consultar ventanas con privilegios elevados o en proceso de cierre.
        TempTitle := WinGetTitle("A")
        if (TempTitle != "") {
            ActiveTitle := TempTitle
        }
    } Catch {
        ; Si hay error (ej. permisos), marcamos como Idle para no interrumpir el flujo del script
        ActiveTitle := "System/Idle"
    }

    ; Solo actuamos si el usuario ha cambiado de ventana para minimizar operaciones de escritura
    if (ActiveTitle != CurrentTitle) {
        if (CurrentTitle != "") {
            ; Al detectar el cambio, guardamos lo acumulado de la ventana que acaba de terminar
            SaveActivity(CurrentTitle, A_TickCount - StartTime)
        }
        ; Reiniciamos el cronómetro para la nueva ventana enfocada
        CurrentTitle := ActiveTitle
        StartTime := A_TickCount
    }
}

/**
 * Transforma los datos crudos de memoria en un registro físico legible.
 * Maneja la limpieza de strings para mantener la integridad del formato JSON.
 */
SaveActivity(Title, ElapsedMS) {
    Seconds := ElapsedMS // 1000
    ; Formateamos a HH:MM:SS para facilitar la lectura humana rápida en el log
    Timestamp := Format("{:02}:{:02}:{:02}", Seconds // 3600, Mod(Seconds // 60, 60), Mod(Seconds, 60))

    ; Reemplazamos comillas dobles por simples para evitar que el JSON se corrompa
    ; y sea imposible de parsear posteriormente por otras herramientas.
    CleanTitle := StrReplace(Title, '"', "'")
    
    ; Estructuramos como objeto JSON por línea para permitir una carga incremental eficiente
    DataLine := '{"Timestamp": "' A_Now '", "Window": "' CleanTitle '", "Duration": "' Timestamp '"}'
    
    ; Forzamos UTF-8 para asegurar que tildes y caracteres especiales de las ventanas se guarden bien
    FileAppend(DataLine "`n", TodayLog, "UTF-8")
}
