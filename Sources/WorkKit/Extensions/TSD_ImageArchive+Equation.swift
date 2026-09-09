extension TSD_ImageArchive {
  var isEquation: Bool {
    return self.hasTSWP_EquationInfoArchive_equationSourceText
  }

  var equation: IWorkEquation? {
    guard self.isEquation else { return nil }
    let equationSourceText = self.TSWP_EquationInfoArchive_equationSourceText
    if equationSourceText.contains("http://www.w3.org/1998/Math/MathML") {
      return .mathml(equationSourceText)
    } else {
      return .latex(equationSourceText)
    }
  }
}
