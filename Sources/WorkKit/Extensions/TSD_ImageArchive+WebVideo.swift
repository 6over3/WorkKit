extension TSD_ImageArchive {
  var isWebVideo: Bool {
    hasTSA_WebVideoInfo_webVideoInfo
  }

  var webVideoInfo: WebVideoInfo? {
    guard self.isWebVideo else { return nil }
    let webVideoInfo = self.TSA_WebVideoInfo_webVideoInfo
    guard webVideoInfo.hasAttribution else { return nil }
    let attribution = webVideoInfo.attribution
    return WebVideoInfo(
      title: attribution.hasTitle ? attribution.title : nil,
      description: attribution.hasDescriptionText ? attribution.descriptionText : nil,
      externalURL: attribution.hasExternalURL ? attribution.externalURL : nil,
      authorName: attribution.hasAuthorName ? attribution.authorName : nil,
      authorURL: attribution.hasAuthorURL ? attribution.authorURL : nil
    )
  }
}
