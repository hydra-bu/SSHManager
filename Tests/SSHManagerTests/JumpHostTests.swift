import XCTest
@testable import SSHManager

final class JumpHostTests: XCTestCase {

    func testManualJumpHostProxyString() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "jumphost",
            hostname: "jump.example.com",
            user: "admin",
            port: 22
        )

        let proxy = jump.toProxyJumpString()
        XCTAssertEqual(proxy, "admin@jump.example.com")
    }

    func testManualJumpHostWithNonStandardPort() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "jumphost",
            hostname: "jump.example.com",
            user: "admin",
            port: 2222
        )

        let proxy = jump.toProxyJumpString()
        XCTAssertEqual(proxy, "admin@jump.example.com:2222")
    }

    func testManualJumpHostWithoutUser() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "jumphost",
            hostname: "jump.example.com",
            port: 22
        )

        let proxy = jump.toProxyJumpString()
        XCTAssertEqual(proxy, "jump.example.com")
    }

    func testReferenceJumpHostDisplayName() throws {
        let jump = JumpHost(
            type: .reference,
            alias: "My Jump Server"
        )

        XCTAssertEqual(jump.displayName, "My Jump Server")
    }

    func testManualJumpHostDisplayName() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "",
            hostname: "10.0.0.1",
            user: "root",
            port: 22
        )

        XCTAssertEqual(jump.displayName, "root@10.0.0.1")
    }

    func testManualJumpHostDisplayNameNoAliasNoUser() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "",
            hostname: "10.0.0.1",
            user: "",
            port: 22
        )

        XCTAssertEqual(jump.displayName, "10.0.0.1")
    }

    func testManualJumpHostDisplayNameEmpty() throws {
        let jump = JumpHost(
            type: .manual,
            alias: "",
            hostname: "",
            user: "",
            port: 22
        )

        XCTAssertEqual(jump.displayName, "未命名跳板")
    }

    func testIsValidReferenceWithAlias() throws {
        let jump = JumpHost(
            type: .reference,
            alias: "jumphost"
        )

        XCTAssertTrue(jump.isValid)
    }

    func testIsValidReferenceWithoutAlias() throws {
        let jump = JumpHost(
            type: .reference,
            alias: ""
        )

        XCTAssertFalse(jump.isValid)
    }

    func testIsValidManualWithHostname() throws {
        let jump = JumpHost(
            type: .manual,
            hostname: "jump.example.com"
        )

        XCTAssertTrue(jump.isValid)
    }

    func testIsValidManualWithoutHostname() throws {
        let jump = JumpHost(
            type: .manual,
            hostname: ""
        )

        XCTAssertFalse(jump.isValid)
    }

    func testParseSingleJumpHost() throws {
        let jumps = JumpHost.parse(from: "jumphost")

        XCTAssertEqual(jumps.count, 1)
        XCTAssertEqual(jumps[0].alias, "jumphost")
    }

    func testParseManualJumpHost() throws {
        let jumps = JumpHost.parse(from: "admin@jump.example.com:2222")

        XCTAssertEqual(jumps.count, 1)
        XCTAssertEqual(jumps[0].type, .manual)
        XCTAssertEqual(jumps[0].user, "admin")
        XCTAssertEqual(jumps[0].hostname, "jump.example.com")
        XCTAssertEqual(jumps[0].port, 2222)
    }

    func testParseMultipleJumpHosts() throws {
        let jumps = JumpHost.parse(from: "jump1,jump2,jump3")

        XCTAssertEqual(jumps.count, 3)
    }

    func testConfigStringReference() throws {
        let jump = JumpHost(
            type: .reference,
            alias: "jumphost"
        )

        let config = jump.toConfigString()
        XCTAssertEqual(config, "ProxyJump jumphost")
    }

    func testConfigStringManual() throws {
        let jump = JumpHost(
            type: .manual,
            hostname: "jump.example.com",
            user: "admin",
            port: 2222
        )

        let config = jump.toConfigString()
        XCTAssertEqual(config, "ProxyJump admin@jump.example.com:2222")
    }
}
