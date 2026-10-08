import Foundation

/// Interface text in English and European Portuguese, matching the terminal version.
struct Strings {
    let pt: Bool

    init(lang: String) { pt = lang == "pt" }

    static func systemLang() -> String {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("pt") ? "pt" : "en"
    }

    private func s(_ en: String, _ ptText: String) -> String { pt ? ptText : en }

    var tagline: String { s("Disk cleanup for developer Macs", "Limpeza de disco para Macs de developers") }
    var free: String { s("free", "livre") }
    var of: String { s("of", "de") }
    var used: String { s("used", "usado") }
    var rescan: String { s("Rescan", "Analisar de novo") }
    var measuring: String { s("Measuring…", "A medir…") }
    var measuringSub: String { s("Caches, simulators, emulators, projects. This can take a minute.",
                                 "Caches, simuladores, emuladores, projectos. Pode demorar um minuto.") }

    func tier(_ t: Tier) -> String {
        switch t {
        case .safe: return s("SAFE", "SEGURO")
        case .rebuild: return s("REBUILD", "REGENERÁVEL")
        case .review: return s("REVIEW", "VERIFICAR")
        }
    }
    func tierDescription(_ t: Tier) -> String {
        switch t {
        case .safe: return s("Caches that tools recreate on their own", "Caches que as ferramentas recriam sozinhas")
        case .rebuild: return s("Deletable, but you will reinstall or rebuild", "Apaga-se, mas exige reinstalar ou recompilar")
        case .review: return s("May hold your data: decide one by one", "Pode ter dados teus: decide caso a caso")
        }
    }

    func items(_ n: Int) -> String { n == 1 ? "1 item" : "\(n) " + s("items", "itens") }
    var selectAllSafe: String { s("Select All Safe", "Seleccionar todos os seguros") }
    func inUse(_ app: String) -> String { s("In use: close \(app)", "Em uso: fecha \(app)") }
    func nothingAbove(_ mb: Int) -> String { s("Nothing found above \(mb) MB", "Nada encontrado acima de \(mb) MB") }
    func selected(_ n: Int) -> String {
        n == 1 ? s("1 item selected", "1 item seleccionado") : s("\(n) items selected", "\(n) itens seleccionados")
    }
    var deselectAll: String { s("Deselect All", "Desmarcar tudo") }
    var reviewAndDelete: String { s("Review & Delete…", "Rever e apagar…") }
    func freeAfter(_ v: String) -> String { s("\(v) free after cleanup", "\(v) livres depois da limpeza") }
    var projects: String { s("Projects", "Projectos") }
    func hiding(_ mb: Int) -> String { s("Hiding items under \(mb) MB", "A esconder itens abaixo de \(mb) MB") }
    var dryRunBanner: String { s("Dry run: you can go through the whole flow, nothing will be deleted.",
                                 "Modo simulação: podes percorrer tudo, nada será apagado.") }
    func paths(_ n: Int) -> String { n == 1 ? s("1 path", "1 caminho") : "\(n) " + s("paths", "caminhos") }
    var showInFinder: String { s("Show in Finder", "Mostrar no Finder") }
    var notApplicable: String { s("n/a", "n/d") }

    // confirm
    func confirmTitle(_ n: Int) -> String { n == 1 ? s("Delete 1 item?", "Apagar 1 item?") : s("Delete \(n) items?", "Apagar \(n) itens?") }
    var confirmSub: String { s("This cannot be undone. Items marked REVIEW may hold your data.",
                               "Não dá para desfazer. Os itens VERIFICAR podem ter dados teus.") }
    var total: String { "Total" }
    var confirmWord: String { s("DELETE", "APAGAR") }
    func typeToConfirm(_ w: String) -> String { s("Type \(w) to confirm", "Escreve \(w) para confirmar") }
    var cancel: String { s("Cancel", "Cancelar") }
    var delete: String { s("Delete", "Apagar") }

    // progress
    var deleting: String { s("Deleting", "A apagar") }
    var dryRun: String { s("Dry run", "Simulação") }
    var passwordNote: String { s("Steps that need an administrator password ask for it in a macOS dialog.",
                                 "O que precisar de password de administrador pede-a numa janela do macOS.") }
    var done: String { s("Done", "Concluído") }
    var freed: String { s("freed", "libertados") }
    var dryDone: String { s("Dry run finished. Nothing was deleted.", "Simulação concluída. Nada foi apagado.") }
    var logAt: String { s("Log at", "Registo em") }
    var close: String { s("Close", "Fechar") }
    var errorTitle: String { s("Something went wrong", "Algo correu mal") }
    var tryAgain: String { s("Try Again", "Tentar de novo") }

    // settings
    var language: String { s("Language", "Idioma") }
    var automatic: String { s("Automatic", "Automático") }
    var projectsFolder: String { s("Projects folder", "Pasta de projectos") }
    var autoDetect: String { s("Detect automatically", "Detectar automaticamente") }
    var choose: String { s("Choose…", "Escolher…") }
    var reset: String { s("Reset", "Repor") }
    var inactiveAfter: String { s("Project is inactive after", "Projecto inactivo ao fim de") }
    var days: String { s("days", "dias") }
    var hideBelow: String { s("Hide items smaller than", "Esconder itens menores que") }
    var skipProjects: String { s("Skip the project scan (faster)", "Saltar a análise de projectos (mais rápido)") }
    var dryRunToggle: String { s("Dry run (never delete anything)", "Modo simulação (nunca apaga nada)") }
    var settingsNote: String { s("Changes apply to the next scan.", "As alterações valem a partir da próxima análise.") }
    var rescanNow: String { s("Rescan Now", "Analisar agora") }
    var scanSection: String { s("Scan", "Análise") }
    var general: String { s("General", "Geral") }
}
