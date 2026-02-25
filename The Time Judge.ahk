#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib/Tracker.ahk
#Include lib/Processor.ahk

/**
 * ARCHIVO PRINCIPAL: The Time Judge v1.0.1
 * Este script coordina la Interfaz Gráfica (GUI) con los módulos de rastreo y procesamiento.
 */

; --- Configuración Inicial y Estado Global ---
Global QueryFile := TodayLog  ; Apuntamos por defecto al log de la sesión actual
Global TrackingActive := false

; Personalizamos el menú de la bandeja para que el usuario controle el tiempo sin abrir la ventana
A_TrayMenu.Delete() 
A_TrayMenu.Add("Iniciar Rastreo", (*) => IniciarRastreo())
A_TrayMenu.Add("Detener Rastreo", (*) => DetenerRastreo())
A_TrayMenu.Add() 
A_TrayMenu.Add("Abrir Interfaz", (*) => MainGui.Show())
A_TrayMenu.Add("Salir", (*) => ExitApp())
A_TrayMenu.Default := "Abrir Interfaz"
A_TrayMenu.ClickCount := 2

; --- Construcción de la Interfaz (UX Moderno) ---
MainGui := Gui(, "The Time Judge v1.0.1")
ActualizarIconos("Detenido") ; Establecemos el estado visual inicial
OnMessage(0x0112, DetectarMinimizar) ; Capturamos los eventos del botón de minimizar en la ventana
MainGui.SetFont("s10", "Segoe UI") 

; Limpiamos la ruta del archivo para mostrar solo el nombre al usuario (más estético)
SplitPath(QueryFile, &FileNameOnly)
Global SelectedFileText1 := MainGui.Add("Text", "w400 cBlue", "Log de rastreo: " FileNameOnly)
Global SelectedFileText := MainGui.Add("Text", "w400 yp+18 cBlue", "Log seleccionado: " FileNameOnly)

; Organización por pestañas para no saturar al usuario con demasiados controles
MyTabs := MainGui.Add("Tab3", "w450 h300", ["Rastreador", "Reportes", "Filtros"])

; --- PESTAÑA 1: RASTREADOR (Control de Tiempo) ---
MyTabs.UseTab(1)
MainGui.Add("Text", "xp+20 yp+40", "Duración del rastreo:")
ChooseTime := MainGui.Add("DropDownList", "vTimeLimit Choose8 x+10 yp-2", ["10 minutos", "30 minutos", "1 hora", "4 horas", "8 horas", "12 horas", "24 horas", "Indefinido"])

BtnStart := MainGui.Add("Button", "w138 h40 xp-133 yp+35", "Iniciar")
BtnStart.OnEvent("Click", IniciarRastreo)

BtnStop := MainGui.Add("Button", "x+9 w138 h40 Disabled", "Detener")
BtnStop.OnEvent("Click", DetenerRastreo)

MainGui.Add("Text", "xp-145 yp+50", "Estado del sistema:")
StatusText := MainGui.Add("Text", "w400 x+10 cRed", "🔴 Detenido")

; --- PESTAÑA 2: REPORTES (Visualización de Datos) ---
MyTabs.UseTab(2)
MainGui.Add("Text", , "Generar informe de actividad total:")
MyProgress := MainGui.Add("Progress", "w410 h20 cGreen", 0) ; Feedback visual para procesos largos

BtnSelectFile := MainGui.Add("Button", "w200", "📂 Seleccionar Log")
BtnSelectFile.OnEvent("Click", SeleccionarArchivoLog)

BtnReport := MainGui.Add("Button", "w200 x+10", "Crear Informe Final")
BtnReport.OnEvent("Click", (*) => MostrarInforme()) 

; --- PESTAÑA 3: FILTROS (Búsqueda Específica) ---
MyTabs.UseTab(3)
MainGui.Add("Text", , "Buscar palabra(s) clave (ej. Chrome, Excel):")
EditFilter := MainGui.Add("Edit", "vKeyword w410 h60")
BtnSelectFile := MainGui.Add("Button", "w200", "📂 Seleccionar Log")
BtnSelectFile.OnEvent("Click", SeleccionarArchivoLog)

BtnSearch := MainGui.Add("Button", "w200 x+10", "Buscar")
BtnSearch.OnEvent("Click", (*) => ValidarYBuscar())

MainGui.OnEvent("Close", Salir)
MainGui.Show()

; --- LÓGICA DE CONTROL ---

/**
 * Activa el cronómetro y configura el temporizador de auto-detención.
 * Cambia el estado visual de toda la aplicación para indicar actividad.
 */
IniciarRastreo(*) {
    Global TrackingActive
    ; Mapeo de texto a milisegundos para el temporizador de Windows
    Minutos := (ChooseTime.Text = "10 minutos") ? 10 
             : (ChooseTime.Text = "30 minutos") ? 30 
             : (ChooseTime.Text = "1 hora") ? 60 
             : (ChooseTime.Text = "4 horas") ? 240 
             : (ChooseTime.Text = "8 horas") ? 480 
             : (ChooseTime.Text = "12 horas") ? 720 
             : (ChooseTime.Text = "24 horas") ? 1440 
             : 0

    ; Si el usuario eligió un tiempo límite, programamos el apagado automático
    if (ChooseTime.Text != "Indefinido")
        SetTimer(DetenerRastreo, -(Minutos * 60000))

    ; Bloqueo de seguridad: Evita que el usuario interactúe hasta que se detenga el proceso
    TrackingActive := true
    BtnStart.Enabled := false
    BtnStop.Enabled := true
    ActualizarIconos("Activo")
    A_TrayMenu.Disable("Iniciar Rastreo")
    A_TrayMenu.Enable("Detener Rastreo")
    StatusText.Value := "🟢 Rastreando actividad..."
    StatusText.Opt("cGreen")
    MainGui.Hide()
    TrayTip("The Time Judge sigue trabajando en segundo plano...")
    SetTimer(TrackActivity, 1000) 
    MsgBox("Rastreo iniciado.", "The Time Judge - Rastreo", "Iconi T3")
}

/**
 * Detiene el rastreo, asegura el guardado de la última actividad pendiente
 * y restaura la interfaz al estado de reposo.
 */
DetenerRastreo(*) {
    Global TrackingActive

    ; IMPORTANTE: Guardamos el tiempo acumulado de la ventana actual antes de apagar
    SaveActivity(CurrentTitle, A_TickCount - StartTime)

    TrackingActive := false
    BtnStart.Enabled := true
    BtnStop.Enabled := false
    ActualizarIconos("Detenido")
    A_TrayMenu.Enable("Iniciar Rastreo")
    A_TrayMenu.Disable("Detener Rastreo")
    StatusText.Value := "🔴 Detenido"
    StatusText.Opt("cRed")
    SetTimer(TrackActivity, 0) 
    MsgBox("Rastreo detenido.", "The Time Judge - Rastreo", "Iconi")
}

/**
 * Crea una ventana emergente para visualizar los resultados calculados.
 * Se separa de la lógica de procesamiento para permitir reutilización con o sin filtros.
 */
MostrarInforme(Filtro := "") {
    Resultados := ProcessData(Filtro) 
    if (Resultados.Count == 0) {
        MsgBox("No se encontraron datos" . (Filtro ? " para: " Filtro : ""), "The Time Judge - Aviso", "Icon!")
        return
    }
    
    Informe := GenerateReport(Resultados) 
    
    ; Creamos una ventana secundaria (Modal) para que el informe no bloquee la ventana principal
    ReportGui := Gui()
    ReportGui.Add("Edit", "ReadOnly w500 h400", Informe)
    BtnExportCSV := ReportGui.Add("Button", "w500 h30 xm", "📊 Exportar a Excel (CSV)")
    BtnExportCSV.OnEvent("Click", (*) => PrepararGuardadoCSV())
    ReportGui.Show()
}

/**
 * Verifica que el campo de búsqueda no esté vacío antes de estresar al procesador
 * leyendo archivos JSON potencialmente grandes.
 */
ValidarYBuscar() {
    Palabra := EditFilter.Value 
    if (Trim(Palabra) == "") {
        MsgBox("Introduce al menos una palabra clave para filtrar.", "The Time Judge - Campo Vacío", "Iconx")
        return
    }
    MostrarInforme(Palabra)
}

/**
 * Permite al usuario cambiar el contexto de análisis hacia archivos históricos.
 */
SeleccionarArchivoLog(*) {
    Global QueryFile
    ArchivoElegido := FileSelect(3, A_ScriptDir, "Seleccione un archivo de Log", "JSON (*.json)")
    
    if (ArchivoElegido != "") {
        QueryFile := ArchivoElegido
        SplitPath(ArchivoElegido, &FileName)
        SelectedFileText.Value := "Log seleccionado: " . FileName
        MsgBox("Log cargado con éxito.", "The Time Judge - Éxito", "Iconi T3")
    }
}

/**
 * Actúa como puente entre la GUI y la función de exportación física del módulo Processor.
 * Maneja la selección de destino y el nombre de archivo para asegurar que el usuario tenga el control de su data.
 */
PrepararGuardadoCSV() {
    Resultados := ProcessData(EditFilter.Value)

    Ruta := FileSelect("S16", A_ScriptDir "\Informe_Final.csv", "Guardar como CSV", "Archivo CSV (*.csv)")
    
    if (Ruta != "") {
        if ExportarCSV(Resultados, Ruta) {
            MsgBox("¡CSV generado! Compatible con Excel.", "The Time Judge - Éxito", "Iconi")
        }
    }
}

/**
 * Sincroniza los iconos de la ventana y la bandeja del sistema para
 * ofrecer una experiencia visual coherente en todo el SO.
 */
ActualizarIconos(Estado) {
    Ruta := (Estado = "Activo") ? "Green.ico" : "Red.ico"
    TraySetIcon(Ruta) ; Icono de la barra de tareas (junto al reloj)
    
    ; Cargamos el icono con dimensiones específicas para evitar que Windows 
    ; lo redimensione con pérdida de calidad en la barra de título.
    hIcon := LoadPicture(Ruta, "w32 h32", &Tipo)
    SendMessage(0x80, 0, hIcon, MainGui.Hwnd) ; Icono pequeño
    SendMessage(0x80, 1, hIcon, MainGui.Hwnd) ; Icono grande
}

/**
 * Si se minimiza teniendo iniciado un rastreador escondemos en la bandeja del sistema la aplicación.
 */
DetectarMinimizar(wParam, lParam, msg, hwnd) {
    if (wParam = 0xF020 && hwnd = MainGui.Hwnd && TrackingActive) {
        MainGui.Hide()
        TrayTip("The Time Judge sigue trabajando en segundo plano...")
        SetTimer(() => TrayTip(), -2500)
        return 0
    }
}

/**
 * Garantiza que no se pierdan datos si el usuario cierra la aplicación repentinamente.
 */
Salir(*) {
    Global TrackingActive, CurrentTitle, StartTime
    if (TrackingActive && CurrentTitle != "") {
        SaveActivity(CurrentTitle, A_TickCount - StartTime)
    }
    ExitApp()
}
