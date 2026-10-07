import XCTest

// Types through the real iOS software keyboard (Korean 2-set) and prints what the field
// ended up holding (IMERESULT lines). Run with tool/ime_check/run.sh — see its header.
// testRepro drives the host app (host_main.dart): the same TextField with
// enableInteractiveSelection true vs false, the 1.5.1 root cause. testSetpad* drive setpad.
let SHOTS = ProcessInfo.processInfo.environment["SHOTS"] ?? NSTemporaryDirectory()

private let L = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
private let V = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"]
private let T = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
private let split: [String: [String]] = ["ㅘ":["ㅗ","ㅏ"],"ㅙ":["ㅗ","ㅐ"],"ㅚ":["ㅗ","ㅣ"],"ㅝ":["ㅜ","ㅓ"],"ㅞ":["ㅜ","ㅔ"],"ㅟ":["ㅜ","ㅣ"],"ㅢ":["ㅡ","ㅣ"],"ㄳ":["ㄱ","ㅅ"],"ㄵ":["ㄴ","ㅈ"],"ㄶ":["ㄴ","ㅎ"],"ㄺ":["ㄹ","ㄱ"],"ㄻ":["ㄹ","ㅁ"],"ㄼ":["ㄹ","ㅂ"],"ㄽ":["ㄹ","ㅅ"],"ㄾ":["ㄹ","ㅌ"],"ㄿ":["ㄹ","ㅍ"],"ㅀ":["ㄹ","ㅎ"],"ㅄ":["ㅂ","ㅅ"]]
private let shifted: Set<String> = ["ㄲ","ㄸ","ㅃ","ㅆ","ㅉ","ㅒ","ㅖ"]

/// Hangul text -> 2-set key presses ("스쿼트" -> ㅅㅡㅋㅜㅓㅌㅡ).
func keyPresses(_ text: String) -> [String] {
  var out: [String] = []
  for ch in text.unicodeScalars {
    let v = Int(ch.value)
    if v >= 0xAC00 && v <= 0xD7A3 {
      let i = v - 0xAC00
      for j in [L[i / 588], V[(i % 588) / 28], T[i % 28]] where !j.isEmpty { out += split[j] ?? [j] }
    } else { out.append(String(ch)) }
  }
  return out
}

final class ImeUITests: XCTestCase {
  func koreanKeyboard(_ app: XCUIApplication) {
    // First keyboard on a fresh device: the slide-to-type intro covers it.
    let intro = app.buttons.matching(NSPredicate(format: "label IN %@", ["Continue", "계속"])).firstMatch
    if intro.waitForExistence(timeout: 1) { intro.tap() }
    let probe = app.keys["ㅇ"]
    if probe.waitForExistence(timeout: 4) { return }
    for _ in 0..<4 {
      let globe = app.buttons.matching(NSPredicate(format: "label IN %@", ["Next keyboard", "다음 키보드", "Next Keyboard", "다음 키보드로 전환"])).firstMatch
      if globe.exists { globe.tap() }
      if probe.waitForExistence(timeout: 2) { return }
    }
    print("IMERESULT keys:", app.keys.allElementsBoundByIndex.map { $0.label })
    XCTFail("no Korean keyboard")
  }

  func type(_ app: XCUIApplication, _ text: String) {
    for k in keyPresses(text) {
      switch k {
      case " ":
        app.keys.matching(NSPredicate(format: "label IN %@ OR identifier IN %@", ["space", "스페이스", "간격", "Space", "공백", "띄어쓰기"], ["space", "Space"])).firstMatch.tap()
      case "\n":
        app.typeText("\n")
      default:
        if shifted.contains(k) {
          app.buttons.matching(NSPredicate(format: "label IN %@ OR identifier IN %@", ["shift", "Shift", "시프트"], ["shift", "Shift"])).firstMatch.tap()
        }
        app.keys[k].tap()
      }
    }
  }

  func tapLabel(_ app: XCUIApplication, _ label: String) {
    let e = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    if !e.waitForExistence(timeout: 5) {
      print("IMERESULT labels:", app.descendants(matching: .any).allElementsBoundByIndex.map { $0.label }.filter { !$0.isEmpty }.prefix(80))
    }
    let all = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
    print("IMERESULT tap \(label):", all.map { "\($0.elementType.rawValue)@\($0.frame)" })
    // Flutter keypad keys are plain gesture widgets: tap the visible frame's centre.
    let target = all.last { $0.frame.width > 1 && $0.frame.height > 1 } ?? e
    target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
  }

  func shot(_ name: String) {
    try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(SHOTS)/\(name).png"))
  }

  func input(_ app: XCUIApplication) -> XCUIElement {
    let f = app.textFields.firstMatch
    return f.exists ? f : app.textViews.firstMatch
  }

  func dump(_ label: String, _ app: XCUIApplication) {
    let field = input(app)
    let v = field.exists ? ((field.value as? String) ?? "nil") : "<no text input>"
    let scalars = v.unicodeScalars.map { String(format: "%04X", $0.value) }.joined(separator: " ")
    print("IMERESULT \(label) value=\(v) scalars=[\(scalars)]")
  }

  func testRepro() {
    let app = XCUIApplication()
    app.launch()
    for (i, id) in ["A", "B"].enumerated() {
      app.textFields.element(boundBy: i).tap()
      koreanKeyboard(app)
      type(app, "아이스 아메리카노")
      sleep(1)
      print("IMERESULT out\(id) label=\(app.descendants(matching: .any)["out\(id)"].label)")
    }
  }

  // The 1.5.1 report: finish an exercise, come back to the empty name line, type Korean.
  func testSetpadAfterFinish() {
    let app = XCUIApplication(bundleIdentifier: "com.tskim.workoutlog")
    app.launch()
    _ = app.textFields.firstMatch.waitForExistence(timeout: 25)
    input(app).tap()
    koreanKeyboard(app)
    type(app, "스쿼트\n")
    sleep(2)
    tapLabel(app, "운동 완료")
    sleep(2)
    shot("f1-name-line")
    dump("f1-before-typing", app)
    if !app.keys["ㅇ"].exists { input(app).tap() }
    koreanKeyboard(app)
    type(app, "아메리카노")
    sleep(1)
    dump("f2-typed-americano", app)
    shot("f2-typed")
    type(app, " 아이스")
    sleep(1)
    dump("f3-typed-more", app)
    app.typeText("\n")
    sleep(2)
    shot("f4-enter")
    dump("f4-after-enter", app)
  }

  func backspace(_ app: XCUIApplication, _ n: Int) {
    let key = app.keys.matching(NSPredicate(format: "label IN %@ OR identifier IN %@", ["delete", "Delete", "삭제", "지우기"], ["delete", "Delete"])).firstMatch
    for _ in 0..<n { key.tap() }
  }

  func tapPoint(_ app: XCUIApplication, _ x: CGFloat, _ y: CGFloat) {
    app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
  }

  /// Fresh app -> 스쿼트 with one set (60 x 5) -> finish -> empty name line.
  func toNameLineAfterSet(_ app: XCUIApplication) {
    app.launch()
    _ = app.textFields.firstMatch.waitForExistence(timeout: 25)
    input(app).tap()
    koreanKeyboard(app)
    type(app, "스쿼트\n")
    sleep(2)
    for k in ["6", "0", "다음", "5", "세트 추가"] { tapLabel(app, k); usleep(300_000) }
    sleep(1)
    shot("s0-after-set")
    tapLabel(app, "운동 완료")
    sleep(2)
    if !app.keys["ㅇ"].exists { input(app).tap() }
    koreanKeyboard(app)
  }

  /// Type, erase it all, then one more backspace on the empty line.
  func testSetpadBackspace() {
    let app = XCUIApplication(bundleIdentifier: "com.tskim.workoutlog")
    toNameLineAfterSet(app)
    dump("b0-name-line", app)
    type(app, "아")
    dump("b1-typed", app)
    backspace(app, 2)
    sleep(1)
    dump("b2-erased", app)
    shot("b2-erased")
    backspace(app, 1)
    sleep(2)
    dump("b3-backspace-on-empty", app)
    shot("b3-backspace-on-empty")
  }

  /// Memo line: the keypad's keyboard key switches the set line to a Korean memo.
  func testSetpadMemo() {
    let app = XCUIApplication(bundleIdentifier: "com.tskim.workoutlog")
    app.launch()
    _ = app.textFields.firstMatch.waitForExistence(timeout: 25)
    input(app).tap()
    koreanKeyboard(app)
    type(app, "스쿼트\n")
    sleep(2)
    for k in ["6", "0", "다음", "5", "세트 추가"] { tapLabel(app, k); usleep(300_000) }
    sleep(1)
    // keypad's keyboard key (icon only): top-right of the keypad grid, iPhone 17 Pro points
    tapPoint(app, 346, 650)
    sleep(1)
    koreanKeyboard(app)
    type(app, "오늘 컨디션 좋음")
    sleep(1)
    dump("m1-memo", app)
    shot("m1-memo")
  }

  /// Judge end to end (local server + real Solar): a custom exercise name, then a food.
  func testSetpadJudge() {
    let app = XCUIApplication(bundleIdentifier: "com.tskim.workoutlog")
    app.launch()
    _ = app.textFields.firstMatch.waitForExistence(timeout: 25)
    input(app).tap()
    koreanKeyboard(app)
    type(app, "민수식 로우\n")
    sleep(4)
    shot("j1-custom-exercise")
    print("IMERESULT j1-keypad=\(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "운동 완료")).firstMatch.exists)")
    tapLabel(app, "운동 완료")
    sleep(2)
    if !app.keys["ㅇ"].exists { input(app).tap() }
    koreanKeyboard(app)
    type(app, "마라샹궈\n")
    sleep(4)
    shot("j2-food")
    print("IMERESULT j2-meal-line=\(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "끼니로 남겼어요")).firstMatch.exists)")
    dump("j2-after", app)
  }

  /// Meal text mode from the first screen.
  func testSetpadMealMode() {
    let app = XCUIApplication(bundleIdentifier: "com.tskim.workoutlog")
    app.launch()
    _ = app.textFields.firstMatch.waitForExistence(timeout: 25)
    tapLabel(app, "식단 남기기")
    sleep(1)
    tapLabel(app, "글로 적기")
    sleep(2)
    if !app.keys["ㅇ"].exists && input(app).exists { input(app).tap() }
    koreanKeyboard(app)
    type(app, "김치찌개 한 그릇")
    sleep(1)
    dump("k1-meal-typed", app)
    shot("k1-meal-typed")
  }
}
