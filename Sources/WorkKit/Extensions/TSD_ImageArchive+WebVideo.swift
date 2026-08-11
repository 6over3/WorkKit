extension TSD_ImageArchive {
  var isWebVideo: Bool {
    hasTSA_WebVideoInfo_webVideoInfo
  }

  var webVideoInfo: WebVideoInfo? {
    guard self.isWebVideo else { return nil }
    let webVideoInfo = self.TSA_WebVideoInfo_webVideoInfo
    return WebVideoInfo(
      url: webVideoInfo.hasURL ? webVideoInfo.url : nil,
      attribution: webVideoInfo.hasAttribution
        ? MediaAttribution(webVideoInfo.attribution)
        : nil
    )
  }
}

extension MediaAttribution {
  init(_ attribution: TSD_Attribution) {
    self.init(
      title: attribution.hasTitle ? attribution.title : nil,
      description: attribution.hasDescriptionText ? attribution.descriptionText : nil,
      externalURL: attribution.hasExternalURL ? attribution.externalURL : nil,
      authorName: attribution.hasAuthorName ? attribution.authorName : nil,
      authorURL: attribution.hasAuthorURL ? attribution.authorURL : nil
    )
  }
}
