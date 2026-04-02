import XCTest
@testable import SSHManager

final class PortForwardTests: XCTestCase {

    func testLocalForwardSSHArgument() throws {
        let forward = PortForward(
            type: .local,
            localPort: 8080,
            remoteHost: "localhost",
            remotePort: 80
        )

        let arg = forward.toSSHArgument()
        XCTAssertEqual(arg, "-L 8080:localhost:80")
    }

    func testRemoteForwardSSHArgument() throws {
        let forward = PortForward(
            type: .remote,
            localPort: 9090,
            remoteHost: "localhost",
            remotePort: 90
        )

        let arg = forward.toSSHArgument()
        XCTAssertEqual(arg, "-R 9090:localhost:90")
    }

    func testDynamicForwardSSHArgument() throws {
        let forward = PortForward(
            type: .dynamic,
            localPort: 1080
        )

        let arg = forward.toSSHArgument()
        XCTAssertEqual(arg, "-D 1080")
    }

    func testLocalForwardConfigString() throws {
        let forward = PortForward(
            type: .local,
            localPort: 8080,
            remoteHost: "10.0.0.1",
            remotePort: 443
        )

        let config = forward.toConfigString()
        XCTAssertEqual(config, "LocalForward 8080 10.0.0.1:443")
    }

    func testRemoteForwardConfigString() throws {
        let forward = PortForward(
            type: .remote,
            localPort: 9090,
            remoteHost: "localhost",
            remotePort: 90
        )

        let config = forward.toConfigString()
        XCTAssertEqual(config, "RemoteForward 9090 localhost:90")
    }

    func testDynamicForwardConfigString() throws {
        let forward = PortForward(
            type: .dynamic,
            localPort: 1080
        )

        let config = forward.toConfigString()
        XCTAssertEqual(config, "DynamicForward 1080")
    }

    func testParseLocalForward() throws {
        let forward = PortForward.parse(from: "LocalForward 8080 localhost:80")

        XCTAssertNotNil(forward)
        XCTAssertEqual(forward?.type, .local)
        XCTAssertEqual(forward?.localPort, 8080)
        XCTAssertEqual(forward?.remoteHost, "localhost")
        XCTAssertEqual(forward?.remotePort, 80)
    }

    func testParseRemoteForward() throws {
        let forward = PortForward.parse(from: "RemoteForward 9090 localhost:90")

        XCTAssertNotNil(forward)
        XCTAssertEqual(forward?.type, .remote)
        XCTAssertEqual(forward?.localPort, 9090)
        XCTAssertEqual(forward?.remotePort, 90)
    }

    func testParseDynamicForward() throws {
        let forward = PortForward.parse(from: "DynamicForward 1080")

        XCTAssertNotNil(forward)
        XCTAssertEqual(forward?.type, .dynamic)
        XCTAssertEqual(forward?.localPort, 1080)
    }

    func testIsValidValidPort() throws {
        let forward = PortForward(
            type: .local,
            localPort: 8080,
            remoteHost: "localhost",
            remotePort: 80
        )

        XCTAssertTrue(forward.isValid)
    }

    func testIsValidInvalidPortZero() throws {
        let forward = PortForward(
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 80
        )

        XCTAssertFalse(forward.isValid)
    }

    func testIsValidInvalidPortTooHigh() throws {
        let forward = PortForward(
            type: .local,
            localPort: 70000,
            remoteHost: "localhost",
            remotePort: 80
        )

        XCTAssertFalse(forward.isValid)
    }

    func testDisplayDescriptionLocal() throws {
        let forward = PortForward(
            type: .local,
            localPort: 8080,
            remoteHost: "localhost",
            remotePort: 80
        )

        let desc = forward.displayDescription
        XCTAssertTrue(desc.contains("8080"))
        XCTAssertTrue(desc.contains("80"))
    }

    func testDisplayDescriptionWithCustomDescription() throws {
        let forward = PortForward(
            type: .local,
            localPort: 8080,
            remoteHost: "localhost",
            remotePort: 80,
            description: "Web UI Access"
        )

        let desc = forward.displayDescription
        XCTAssertEqual(desc, "Web UI Access")
    }

    func testDynamicForwardIsValidWithoutRemote() throws {
        let forward = PortForward(
            type: .dynamic,
            localPort: 1080,
            remoteHost: "",
            remotePort: 0
        )

        XCTAssertTrue(forward.isValid)
    }
}
