@testable import HintoCore
import XCTest

/// Tests for LabelMaker - focusing on pure functions
/// Unit tests for LabelMaker
final class LabelMakerTests: XCTestCase {
    private var sut: LabelMaker!

    override func setUp() {
        super.setUp()
        sut = LabelMaker()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - generateLabels Tests

    func test_generateLabels_givenZeroCount_thenReturnsEmptyArray() {
        // given
        let count = 0

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertTrue(labels.isEmpty)
    }

    func test_generateLabels_givenNegativeCount_thenReturnsEmptyArray() {
        // given
        let count = -5

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertTrue(labels.isEmpty)
    }

    func test_generateLabels_givenSingleElement_thenReturnsSingleCharacterLabel() {
        // given
        let count = 1

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 1)
        XCTAssertEqual(labels[0], "A")
    }

    func test_generateLabels_givenFewElements_thenReturnsSingleCharacterLabels() {
        // given
        let count = 5

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 5)
        XCTAssertEqual(labels, ["A", "S", "D", "F", "G"])
    }

    func test_generateLabels_givenExactlyAlphabetCount_thenReturnsSingleCharacterLabels() {
        // given
        let count = 26

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 26)
        XCTAssertTrue(labels.allSatisfy { $0.count == 1 })
    }

    func test_generateLabels_givenMoreThanAlphabetCount_thenReturnsMultiCharacterLabels() {
        // given
        let count = 30

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 30)
        XCTAssertTrue(labels.allSatisfy { $0.count == 2 })
    }

    func test_generateLabels_givenLargeCount_thenReturnsUniqueLabels() {
        // given
        let count = 100

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 100)
        let uniqueLabels = Set(labels)
        XCTAssertEqual(uniqueLabels.count, 100, "All labels should be unique")
    }

    func test_generateLabels_givenVeryLargeCount_thenReturnsUniqueLabels() {
        // given
        let count = 500

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 500)
        let uniqueLabels = Set(labels)
        XCTAssertEqual(uniqueLabels.count, 500, "All labels should be unique")
    }

    func test_generateLabels_givenCustomCharacters_thenUsesCustomCharacters() {
        // given - with only 3 characters and count > 3, all labels become 2-char
        let customMaker = LabelMaker(characters: "ABC")
        let count = 5

        // when
        let labels = customMaker.generateLabels(count: count)

        // then
        XCTAssertEqual(labels.count, 5)
        // When count > charCount, uses multi-char labels starting from AA, AB, AC...
        XCTAssertEqual(labels[0], "AA")
        XCTAssertEqual(labels[1], "AB")
        XCTAssertEqual(labels[2], "AC")
        XCTAssertEqual(labels[3], "BA")
        XCTAssertEqual(labels[4], "BB")
    }

    func test_generateLabels_givenCustomCharactersWithinLimit_thenReturnsSingleChar() {
        // given
        let customMaker = LabelMaker(characters: "ABC")
        let count = 3

        // when
        let labels = customMaker.generateLabels(count: count)

        // then
        XCTAssertEqual(labels, ["A", "B", "C"])
    }

    func test_generateLabels_givenHomeRowCharacters_thenStartsWithHomeRow() {
        // given - default characters start with home row: ASDFGHJKL
        let count = 9

        // when
        let labels = sut.generateLabels(count: count)

        // then
        XCTAssertEqual(labels, ["A", "S", "D", "F", "G", "H", "J", "K", "L"])
    }

    func test_generateLabels_labelsAreUppercase() {
        // given
        let lowercaseMaker = LabelMaker(characters: "abc")
        let count = 3

        // when
        let labels = lowercaseMaker.generateLabels(count: count)

        // then
        XCTAssertEqual(labels, ["A", "B", "C"])
    }
}
