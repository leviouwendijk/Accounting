import Accounting
import AccountingCompiler
import Foundation
import Interfaces

// use Writers lib instead!
// placeholder
enum EntryCompilerPDFWriter {
    static func write(
        root: URL,
        filename: String,
        html: String,
        margins: Double
    ) throws {
        let project = EntryCompilerProject(
            root: root
        )

        let outDir = project.url(
            .statements
        )

        try FileManager.default.createDirectory(
            at: outDir,
            withIntermediateDirectories: true
        )

        let css = CSSPageSetting(
            margins: CSSMargins(
                margins
            )
        )

        try html.weasyPDF(
            css: css,
            destination: outDir
                .appendingPathComponent(
                    filename
                )
                .path
        )
    }
}
