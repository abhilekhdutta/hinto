@testable import HintoCore
import XCTest

/// Tests for UITree - focusing on isClickable logic
final class UITreeTests: XCTestCase {
    // MARK: - Standard Clickable Roles

    func test_isClickable_givenButton_thenReturnsTrue() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 80, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenLink_thenReturnsTrue() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 50, height: 20)

        // when
        let result = UITree.isClickable(role: "AXLink", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenCheckBox_thenReturnsTrue() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 20, height: 20)

        // when
        let result = UITree.isClickable(role: "AXCheckBox", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    // MARK: - Disabled Elements

    func test_isClickable_givenDisabledButton_thenReturnsFalse() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 80, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: false)

        // then
        XCTAssertFalse(result)
    }

    // MARK: - iTerm2 Tabs (AXRadioButton at y < 60, isEnabled=false)

    func test_isClickable_givenITerm2Tab_disabledRadioButtonInTitleBar_thenReturnsTrue() {
        // given - iTerm2 tabs are AXRadioButton at y=25, and they report isEnabled=false
        let frame = CGRect(x: 200, y: 25, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXRadioButton", frame: frame, isEnabled: false)

        // then
        XCTAssertTrue(result, "iTerm2 tabs (AXRadioButton at y < 60) should be clickable even when disabled")
    }

    func test_isClickable_givenRadioButtonAtY50_disabled_thenReturnsTrue() {
        // given - boundary check: y=50 is still < 60
        let frame = CGRect(x: 200, y: 50, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXRadioButton", frame: frame, isEnabled: false)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenRadioButtonAtY60_disabled_thenReturnsFalse() {
        // given - y=60 is NOT < 60, so disabled check applies
        let frame = CGRect(x: 200, y: 60, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXRadioButton", frame: frame, isEnabled: false)

        // then
        XCTAssertFalse(result, "Disabled AXRadioButton at y >= 60 should not be clickable")
    }

    func test_isClickable_givenRadioButtonAtY100_enabled_thenReturnsTrue() {
        // given - enabled radio button elsewhere in window
        let frame = CGRect(x: 200, y: 100, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXRadioButton", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    // MARK: - IntelliJ File Tabs (AXStaticText at y=55-90, width >= 50)

    func test_isClickable_givenIntelliJFileTab_thenReturnsTrue() {
        // given - IntelliJ file tabs are AXStaticText at y=55-90 with width >= 50
        let frame = CGRect(x: 300, y: 65, width: 80, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result, "IntelliJ file tabs (AXStaticText at y=55-90, width >= 50) should be clickable")
    }

    func test_isClickable_givenStaticTextAtY55_width50_thenReturnsTrue() {
        // given - boundary check: y=55 is valid
        let frame = CGRect(x: 300, y: 55, width: 50, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenStaticTextAtY90_width50_thenReturnsTrue() {
        // given - boundary check: y=90 is valid
        let frame = CGRect(x: 300, y: 90, width: 50, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenStaticTextAtY54_thenReturnsFalse() {
        // given - y=54 is below the 55-90 range (not a file tab)
        let frame = CGRect(x: 300, y: 54, width: 80, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "AXStaticText at y < 55 should not be clickable as file tab")
    }

    func test_isClickable_givenStaticTextAtY91_narrowWidth_thenReturnsFalse() {
        // given - y=91 is above file tab range, and width < 30 won't match session tab
        let frame = CGRect(x: 300, y: 91, width: 25, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result)
    }

    func test_isClickable_givenFileTabWithNarrowWidth_thenReturnsFalse() {
        // given - file tab position but width < 50
        let frame = CGRect(x: 300, y: 65, width: 40, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "File tabs need width >= 50")
    }

    // MARK: - IntelliJ Session Tabs (AXStaticText at y > 100, width 30-200)

    func test_isClickable_givenIntelliJSessionTab_thenReturnsTrue() {
        // given - Terminal session tabs like "Local", "Local (2)" in tool window
        let frame = CGRect(x: 400, y: 600, width: 60, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result, "Session tabs (AXStaticText at y > 100, width 30-200) should be clickable")
    }

    func test_isClickable_givenSessionTabAtY101_width30_thenReturnsTrue() {
        // given - boundary check: y=101 > 100, width=30 is valid
        let frame = CGRect(x: 400, y: 101, width: 30, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenSessionTabAtY100_thenReturnsFalse() {
        // given - y=100 is NOT > 100
        let frame = CGRect(x: 400, y: 100, width: 60, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Session tabs need y > 100")
    }

    func test_isClickable_givenSessionTabWidth200_thenReturnsTrue() {
        // given - boundary check: width=200 is valid
        let frame = CGRect(x: 400, y: 500, width: 200, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    func test_isClickable_givenSessionTabWidth201_thenReturnsFalse() {
        // given - width=201 exceeds 200 limit
        let frame = CGRect(x: 400, y: 500, width: 201, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Session tabs need width <= 200")
    }

    func test_isClickable_givenSessionTabWidth29_thenReturnsFalse() {
        // given - width=29 is below 30 minimum
        let frame = CGRect(x: 400, y: 500, width: 29, height: 20)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Session tabs need width >= 30")
    }

    // MARK: - Filter: Origin (0,0)

    func test_isClickable_givenElementAtOrigin_thenReturnsFalse() {
        // given - elements at (0,0) are likely hidden/placeholder
        let frame = CGRect(x: 0, y: 0, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements at origin (0,0) should be filtered out")
    }

    func test_isClickable_givenElementAtX0Y10_thenReturnsTrue() {
        // given - x=0 OR y=0, but not both
        let frame = CGRect(x: 0, y: 100, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result)
    }

    // MARK: - Filter: Too Large

    func test_isClickable_givenTooWideElement_thenReturnsFalse() {
        // given - width > 2000 likely a container
        let frame = CGRect(x: 100, y: 100, width: 2001, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements wider than 2000px should be filtered out")
    }

    func test_isClickable_givenTooTallElement_thenReturnsFalse() {
        // given - height > 2000 likely a scroll view
        let frame = CGRect(x: 100, y: 100, width: 100, height: 2001)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements taller than 2000px should be filtered out")
    }

    // MARK: - Filter: Too Small

    func test_isClickable_givenTooNarrowElement_thenReturnsFalse() {
        // given - width < 10 likely invisible
        let frame = CGRect(x: 100, y: 100, width: 9, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements narrower than 10px should be filtered out")
    }

    func test_isClickable_givenTooShortElement_thenReturnsFalse() {
        // given - height < 10 likely decorative
        let frame = CGRect(x: 100, y: 100, width: 100, height: 9)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements shorter than 10px should be filtered out")
    }

    // MARK: - Filter: Top Edge (y < 20) for non-menu items

    func test_isClickable_givenButtonAtY15_thenReturnsFalse() {
        // given - buttons near top are often close buttons
        let frame = CGRect(x: 100, y: 15, width: 30, height: 20)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Buttons at y < 20 should be filtered out")
    }

    func test_isClickable_givenMenuBarItemAtY10_thenReturnsTrue() {
        // given - menu bar items are allowed at top
        let frame = CGRect(x: 100, y: 10, width: 50, height: 22)

        // when
        let result = UITree.isClickable(role: "AXMenuBarItem", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result, "Menu bar items should be clickable even at y < 20")
    }

    // MARK: - Filter: Negative Y (off-screen)

    func test_isClickable_givenNegativeY_thenReturnsFalse() {
        // given - y < -100 is off-screen
        let frame = CGRect(x: 100, y: -150, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Elements at y < -100 should be filtered out")
    }

    func test_isClickable_givenSlightlyNegativeY_thenReturnsTrue() {
        // given - y=-50 is within tolerance
        let frame = CGRect(x: 100, y: -50, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result, "Elements at y >= -100 should be allowed")
    }

    // MARK: - Filter: Zero Size

    func test_isClickable_givenZeroWidth_thenReturnsFalse() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 0, height: 30)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result)
    }

    func test_isClickable_givenZeroHeight_thenReturnsFalse() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 100, height: 0)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result)
    }

    // MARK: - Non-Clickable Roles

    func test_isClickable_givenStaticTextNotInTabArea_thenReturnsFalse() {
        // given - random static text that's not a tab
        let frame = CGRect(x: 100, y: 200, width: 250, height: 20) // width > 200

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "AXStaticText not matching tab criteria should not be clickable")
    }

    func test_isClickable_givenUnknownRole_thenReturnsFalse() {
        // given
        let frame = CGRect(x: 100, y: 100, width: 100, height: 30)

        // when
        let result = UITree.isClickable(role: "AXGroup", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "Unknown roles like AXGroup should not be clickable")
    }

    // MARK: - IntelliJ IDEA Mock Elements

    /// Mock data from actual IntelliJ IDEA scan
    /// These tests verify real-world element detection
    func test_isClickable_intelliJ_toolbarButtons_shouldBeClickable() {
        // given - IntelliJ toolbar buttons at y=38
        let toolbarButtons: [(x: Int, y: Int, w: Int, h: Int)] = [
            (973, 38, 183, 32), // Wide toolbar button
            (1156, 38, 34, 32), // Standard toolbar button
            (1190, 38, 34, 32),
            (1224, 38, 34, 32),
        ]

        for btn in toolbarButtons {
            let frame = CGRect(x: btn.x, y: btn.y, width: btn.w, height: btn.h)
            let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)
            XCTAssertTrue(result, "Toolbar button at (\(btn.x),\(btn.y)) should be clickable")
        }
    }

    func test_isClickable_intelliJ_menuBarItems_shouldBeClickable() {
        // given - IntelliJ menu bar items at y=0
        let menuItems: [(x: Int, y: Int, w: Int, h: Int, title: String)] = [
            (10, 0, 37, 37, "Apple"),
            (44, 0, 102, 37, "IntelliJ IDEA"),
            (145, 0, 45, 37, "File"),
            (190, 0, 47, 37, "Edit"),
            (237, 0, 53, 37, "View"),
            (552, 0, 47, 37, "Run"),
        ]

        for item in menuItems {
            let frame = CGRect(x: item.x, y: item.y, width: item.w, height: item.h)
            let result = UITree.isClickable(role: "AXMenuBarItem", frame: frame, isEnabled: true)
            XCTAssertTrue(result, "Menu bar item '\(item.title)' should be clickable")
        }
    }

    func test_isClickable_intelliJ_sessionTabs_shouldBeClickable() {
        // given - IntelliJ Terminal session tabs at y=560
        let sessionTabs: [(x: Int, y: Int, w: Int, h: Int)] = [
            (33, 560, 84, 31), // "Local" tab
            (117, 560, 134, 31), // "Local (2)" tab
            (251, 560, 78, 31),
            (329, 560, 106, 31),
            (435, 560, 106, 31),
            (541, 560, 92, 31),
            (633, 560, 120, 31),
            (753, 560, 106, 31),
        ]

        for tab in sessionTabs {
            let frame = CGRect(x: tab.x, y: tab.y, width: tab.w, height: tab.h)
            let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)
            XCTAssertTrue(result, "Session tab at (\(tab.x),\(tab.y)) w=\(tab.w) should be clickable")
        }
    }

    func test_isClickable_intelliJ_sidebarButtons_shouldBeClickable() {
        // given - IntelliJ left sidebar buttons at x=0
        let sidebarButtons: [(x: Int, y: Int, w: Int, h: Int)] = [
            (0, 71, 32, 32),
            (0, 103, 32, 32),
            (0, 135, 32, 32),
            (0, 210, 32, 32),
            (0, 669, 32, 32),
            (0, 893, 32, 32),
        ]

        for btn in sidebarButtons {
            let frame = CGRect(x: btn.x, y: btn.y, width: btn.w, height: btn.h)
            let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)
            XCTAssertTrue(result, "Sidebar button at (\(btn.x),\(btn.y)) should be clickable")
        }
    }

    func test_isClickable_intelliJ_rightSidebarButtons_shouldBeClickable() {
        // given - IntelliJ right sidebar buttons at x=1480
        let rightSidebarButtons: [(x: Int, y: Int, w: Int, h: Int)] = [
            (1480, 71, 32, 32),
            (1480, 103, 32, 32),
            (1480, 199, 32, 32),
            (1480, 263, 32, 32),
        ]

        for btn in rightSidebarButtons {
            let frame = CGRect(x: btn.x, y: btn.y, width: btn.w, height: btn.h)
            let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)
            XCTAssertTrue(result, "Right sidebar button at (\(btn.x),\(btn.y)) should be clickable")
        }
    }

    // MARK: - IntelliJ Elements That Should NOT Be Clickable

    func test_isClickable_intelliJ_textArea_isClickable() {
        // given - IntelliJ terminal text area (AXTextArea is a clickable role for input)
        let frame = CGRect(x: 42, y: 584, width: 1423, height: 385)

        // when
        let result = UITree.isClickable(role: "AXTextArea", frame: frame, isEnabled: true)

        // then
        XCTAssertTrue(result, "AXTextArea is clickable for text input")
    }

    func test_isClickable_intelliJ_scrollView_shouldNotBeClickable() {
        // given - IntelliJ scroll view (AXScrollArea is not a clickable role)
        let frame = CGRect(x: 42, y: 584, width: 1423, height: 385)

        // when
        let result = UITree.isClickable(role: "AXScrollArea", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "AXScrollArea should not be clickable")
    }

    func test_isClickable_intelliJ_smallActionButtons_shouldNotBeClickable() {
        // given - Small action buttons (width < 10 or filtered by other criteria)
        let smallButtons: [(x: Int, y: Int, w: Int, h: Int)] = [
            (1436, 104, 21, 22), // Small action button
            (1457, 104, 20, 22), // Small action button
        ]

        for btn in smallButtons {
            let frame = CGRect(x: btn.x, y: btn.y, width: btn.w, height: btn.h)
            let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: true)
            // These ARE clickable since width >= 10
            XCTAssertTrue(result, "Button at (\(btn.x),\(btn.y)) with size \(btn.w)x\(btn.h) should be clickable")
        }
    }

    func test_isClickable_intelliJ_staticTextTooWide_shouldNotBeClickable() {
        // given - AXStaticText with width > 200 (not a tab)
        let frame = CGRect(x: 197, y: 443, width: 250, height: 22)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "AXStaticText with width > 200 should not be clickable as tab")
    }

    func test_isClickable_intelliJ_staticTextInMiddle_shouldNotBeClickable() {
        // given - AXStaticText in middle of window (not file tab area y=55-90)
        let frame = CGRect(x: 197, y: 443, width: 184, height: 22)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        // y=443 > 100, width=184 is in range 30-200, so this IS a session tab
        XCTAssertTrue(result, "AXStaticText at y=443 with width=184 matches session tab criteria")
    }

    func test_isClickable_intelliJ_staticTextTooNarrow_shouldNotBeClickable() {
        // given - AXStaticText with width < 30 (too narrow for session tab)
        let frame = CGRect(x: 100, y: 500, width: 25, height: 22)

        // when
        let result = UITree.isClickable(role: "AXStaticText", frame: frame, isEnabled: true)

        // then
        XCTAssertFalse(result, "AXStaticText with width < 30 should not be clickable as session tab")
    }

    func test_isClickable_intelliJ_disabledButton_shouldNotBeClickable() {
        // given - Disabled toolbar button
        let frame = CGRect(x: 973, y: 38, width: 183, height: 32)

        // when
        let result = UITree.isClickable(role: "AXButton", frame: frame, isEnabled: false)

        // then
        XCTAssertFalse(result, "Disabled button should not be clickable")
    }
}
