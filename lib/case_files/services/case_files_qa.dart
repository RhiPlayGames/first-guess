/// TEMPORARY, opt-in Case Files QA mode. NEVER enable for production releases.
/// Use --dart-define=CASE_FILES_QA=true ONLY on internal QA builds.
class CaseFilesQa {
  CaseFilesQa._();
  static const bool enabled = bool.fromEnvironment('CASE_FILES_QA', defaultValue: false);
}
