#Requires AutoHotkey v2.0

/**
 * Módulo de Análisis y Reportes
 * Este bloque se encarga de la "Minería de Datos": lee el historial,
 * consolida tiempos duplicados y genera archivos compatibles con software externo.
 */

/**
 * Lee el archivo JSON línea por línea y agrupa los tiempos por ventana.
 * @param {String} Filter - Palabras clave (separadas por coma) para incluir solo apps específicas.
 */
ProcessData(Filter := "") {
    ; Evitamos errores de ejecución si el usuario intenta filtrar sin haber generado logs previos.
    if !FileExist(QueryFile)
        return Map()

    Stats := Map()
    FileContent := FileRead(QueryFile, "UTF-8")
    
    ; Calculamos el total de líneas de antemano para que la barra de progreso 
    ; proporcione un feedback visual preciso del avance del procesamiento.
    Lines := StrSplit(FileContent, "`n")
    TotalLines := Lines.Length
    
    Loop Parse, FileContent, "`n", "`r" {
        if (Trim(A_LoopField) == "")
            continue
            
        ; Retroalimentación visual: permite al usuario saber que el programa no se ha colgado
        ; durante el procesamiento de archivos de log muy extensos.
        MyProgress.Value := (A_Index / TotalLines) * 100
        
        ; Usamos Expresiones Regulares (RegEx) para extraer datos de forma flexible. 
        ; Esto permite que, aunque el formato del JSON cambie ligeramente, el extractor siga funcionando.
        if RegExMatch(A_LoopField, '"Window":\s*"(.*?)".*?"Duration":\s*"(.*?)"', &Match) {
            WindowTitle := Match[1]
            DurationStr := Match[2] ; Formato "HH:MM:SS"

            ; Lógica de filtrado multi-palabra: permite al usuario buscar "Chrome, Code, Slack" 
            ; para obtener un reporte consolidado de herramientas de trabajo.
            if (Filter != "") {
                Keywords := StrSplit(Filter, ",") 
                FoundMatch := false
        
                for word in Keywords {
                    if InStr(WindowTitle, Trim(word)) {
                        FoundMatch := true
                        break
                    }
                }
                if !FoundMatch
                    continue ; Saltamos si la ventana no encaja en el interés del usuario.
            }

            ; Convertimos el tiempo a una unidad común (segundos) para poder realizar 
            ; operaciones aritméticas de suma de forma sencilla y precisa.
            TimeParts := StrSplit(DurationStr, ":")
            Seconds := (Number(TimeParts[1]) * 3600) + (Number(TimeParts[2]) * 60) + Number(TimeParts[3])

            ; Consolidamos: si la ventana ya existe, acumulamos el tiempo; 
            ; de lo contrario, iniciamos el registro para ese título.
            if Stats.Has(WindowTitle)
                Stats[WindowTitle] += Seconds
            else
                Stats[WindowTitle] := Seconds
        }
    }
    MyProgress.Value := 0 ; Limpiamos la interfaz al terminar la tarea.
    return Stats
}

/**
 * Construye una representación visual del mapa de datos para mostrar en pantalla.
 */
GenerateReport(StatsMap) {
    Report := "--- INFORME DE TIEMPO ---`n`n"
    for Title, TotalSeconds in StatsMap {
        ; Desglosamos los segundos acumulados de nuevo a formato humano HH:MM:SS.
        H := TotalSeconds // 3600
        M := Mod(TotalSeconds // 60, 60)
        S := Mod(TotalSeconds, 60)
        
        TimeFormatted := Format("{:02}:{:02}:{:02}", H, M, S)
        Report .= "Ventana: " . Title . "`nTiempo Total: " . TimeFormatted . "`n`n"
    }
    return Report
}

/**
 * Crea un archivo .csv optimizado para Microsoft Excel.
 */
ExportarCSV(Datos, NombreArchivo) {
    ; Usamos UTF-16 porque es el formato nativo de Windows, evitamos incompatibilidades con diversas configuraciones regionales
    Archivo := FileOpen(NombreArchivo, "w", "UTF-16")
    
    ; Escribimos los encabezados separados por tabulación `t
    Archivo.WriteLine("Actividad`tTiempo (ms)`tTiempo (Horas)`tTiempo (Minutos)`tTiempo (Segundos)")
    
    for Titulo, Tiempo in Datos {
        Horas := Tiempo / 3600
        Minutos := Tiempo / 60
        Miliseg := Tiempo * 1000
        
        ; Construimos la fila usando `t como separador
        Linea := Titulo "`t" Miliseg "`t" Format("{:.2f}", Horas) "`t" Format("{:.2f}", Minutos) "`t" Format("{:.1f}", Tiempo)
        Archivo.WriteLine(Linea)
    }
    
    Archivo.Close()
}
