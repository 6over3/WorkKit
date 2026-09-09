extension TSD_ImageArchive {
  func resolveMediaStyle(using document: IWorkDocument, mask: Mask? = nil) -> MediaStyle? {
    guard self.hasStyle,
      let styleRef = self.style as TSP_Reference?,
      let mediaStyle = document.dereference(styleRef) as? TSD_MediaStyleArchive
    else {
      return nil
    }

    let styleChain = StyleResolver.buildMediaStyleChain(mediaStyle, document: document)
    return StyleResolver.extractMediaProperties(from: styleChain, mask: mask)
  }
}
