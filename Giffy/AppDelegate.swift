import Foundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {}
  
  func application(_ sender: Any, openFileWithoutUI filename: String) -> Bool {
    true
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      convertVideoToGif(videoUrl: url)
    }
  }

  func convertVideoToGif(videoUrl: URL) {
    do {
      let palettePath = videoUrl.deletingPathExtension()
        .deletingLastPathComponent()
        .appendingPathComponent("\(videoUrl.lastPathComponent)-palette")
        .appendingPathExtension("png")
        .path

      try ffmpegTask(
        [
          "-i",
          videoUrl.path,
          "-vf",
          "fps=15,scale=640:-1:flags=lanczos,palettegen=stats_mode=diff",
          palettePath
        ]
      )

      // TODO: Handle case of existing files.
      let savePath = videoUrl.deletingPathExtension().appendingPathExtension("gif").path

      // TODO: Don't assume success of palette task.

      try ffmpegTask([
        "-i",
        videoUrl.path,
        "-i",
        palettePath,
        "-filter_complex",
        "fps=15,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5",
        "-y",
        savePath
      ])

    } catch {
      print("Failed to execute process: \(error)")
    }
  }

  private func ffmpegTask(_ arguments: [String]) throws {
    // TODO: Address hardcoded path
    let ffmpegURL = URL(fileURLWithPath: "/opt/homebrew/Cellar/ffmpeg/7.0/bin/ffmpeg")
    let task = Process()
    task.executableURL = ffmpegURL
    task.arguments = arguments

    try task.run()
    task.waitUntilExit()
  }
}
