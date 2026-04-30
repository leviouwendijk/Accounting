import Writers

func makeSafeWriteOptions(
    overwrite: Bool,
    backup: Bool,
    whitespaceOnlyIsBlank: Bool,
    backupSuffix: String
) -> SafeWriteOptions {
    .init(
        existingFilePolicy: overwrite ? .overwrite : .abort,
        makeBackupOnOverride: backup,
        whitespaceOnlyIsBlank: whitespaceOnlyIsBlank,
        backupSuffix: backupSuffix,
        addTimestampIfBackupExists: true,
        createIntermediateDirectories: true,
        atomic: true,
        createBackupDirectory: true,
        backupDirectoryName: "safe-file-backups",
        backupSetPrefix: "overwrite_",
        maxBackupSets: 10
    )
}
