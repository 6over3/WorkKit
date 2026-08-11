import CoreGraphics
import Foundation
import RegexBuilder
import Testing

@testable import WorkKit

@Test func webVideoRetainsDirectURLAndAttribution() throws {
  var attribution = TSD_Attribution()
  attribution.title = "An embedded video"
  attribution.externalURL = "https://www.youtube.com/watch?v=source"
  attribution.authorName = "Creator"

  var webVideo = TSA_WebVideoInfo()
  webVideo.url = "https://www.youtube.com/embed/source"
  webVideo.attribution = attribution

  var archive = TSD_ImageArchive()
  archive.TSA_WebVideoInfo_webVideoInfo = webVideo

  let parsed = try #require(archive.webVideoInfo)
  #expect(parsed.url == "https://www.youtube.com/embed/source")
  #expect(
    parsed.attribution?.externalURL
      == "https://www.youtube.com/watch?v=source"
  )
  #expect(parsed.attribution?.title == "An embedded video")
  #expect(parsed.attribution?.authorName == "Creator")
}

@Test func webVideoWithoutAttributionRetainsDirectURL() throws {
  var webVideo = TSA_WebVideoInfo()
  webVideo.url = "https://video.example/watch/1"

  var archive = TSD_ImageArchive()
  archive.TSA_WebVideoInfo_webVideoInfo = webVideo

  let parsed = try #require(archive.webVideoInfo)
  #expect(parsed.url == "https://video.example/watch/1")
  #expect(parsed.attribution == nil)
}
