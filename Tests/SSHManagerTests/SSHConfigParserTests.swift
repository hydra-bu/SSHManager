import XCTest
@testable import SSHManager

final class SSHConfigParserTests: XCTestCase {

    func testParseBasicHost() throws {
        let config = """
        Host myserver
          HostName 192.168.1.100
          User admin
          Port 22
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].alias, "myserver")
        XCTAssertEqual(hosts[0].hostname, "192.168.1.100")
        XCTAssertEqual(hosts[0].user, "admin")
        XCTAssertEqual(hosts[0].port, 22)
    }

    func testParseMultipleHosts() throws {
        let config = """
        Host server1
          HostName 10.0.0.1
          User root

        Host server2
          HostName 10.0.0.2
          User deploy
          Port 2222
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 2)
        XCTAssertEqual(hosts[0].alias, "server1")
        XCTAssertEqual(hosts[0].hostname, "10.0.0.1")
        XCTAssertEqual(hosts[1].alias, "server2")
        XCTAssertEqual(hosts[1].port, 2222)
    }

    func testParseIdentityFile() throws {
        let config = """
        Host keyserver
          HostName example.com
          IdentityFile ~/.ssh/id_ed25519
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].identityFile, "~/.ssh/id_ed25519")
    }

    func testParseComments() throws {
        let config = """
        # This is a comment
        Host myserver
          # Another comment
          HostName example.com
          User admin
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].alias, "myserver")
    }

    func testParseProxyJump() throws {
        let config = """
        Host jumphost
          HostName jump.example.com

        Host target
          HostName internal.example.com
          ProxyJump jumphost
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 2)
        XCTAssertEqual(hosts[1].jumpHosts.count, 1)
        XCTAssertEqual(hosts[1].jumpHosts[0].alias, "jumphost")
    }

    func testParsePortForwarding() throws {
        let config = """
        Host webserver
          HostName example.com
          LocalForward 8080 localhost:80
          RemoteForward 9090 localhost:90
          DynamicForward 1080
        """

        let hosts = SSHConfigParser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].portForwards.count, 3)

        let localForward = hosts[0].portForwards.first { $0.type == .local }
        XCTAssertNotNil(localForward)
        XCTAssertEqual(localForward?.localPort, 8080)
        XCTAssertEqual(localForward?.remotePort, 80)

        let dynamicForward = hosts[0].portForwards.first { $0.type == .dynamic }
        XCTAssertNotNil(dynamicForward)
        XCTAssertEqual(dynamicForward?.localPort, 1080)
    }

    func testFormatBasicHost() throws {
        let host = SSHHost(
            alias: "test",
            hostname: "10.0.0.1",
            user: "admin",
            port: 22
        )

        let output = SSHConfigParser.formatSingle(host)

        XCTAssertTrue(output.contains("Host test"))
        XCTAssertTrue(output.contains("HostName 10.0.0.1"))
        XCTAssertTrue(output.contains("User admin"))
    }

    func testFormatNonStandardPort() throws {
        let host = SSHHost(
            alias: "test",
            hostname: "10.0.0.1",
            port: 2222
        )

        let output = SSHConfigParser.formatSingle(host)

        XCTAssertTrue(output.contains("Port 2222"))
    }

    func testFormatOmitsDefaultPort() throws {
        let host = SSHHost(
            alias: "test",
            hostname: "10.0.0.1",
            port: 22
        )

        let output = SSHConfigParser.formatSingle(host)

        XCTAssertFalse(output.contains("Port 22"))
    }

    func testRoundTripPreservesData() throws {
        let original = """
        Host myserver
          HostName 192.168.1.100
          User admin
          Port 2222
          IdentityFile ~/.ssh/id_rsa
        """

        let hosts = SSHConfigParser.parse(original)
        let formatted = SSHConfigParser.format(hosts)
        let reparsed = SSHConfigParser.parse(formatted)

        XCTAssertEqual(hosts.count, reparsed.count)
        XCTAssertEqual(hosts[0].alias, reparsed[0].alias)
        XCTAssertEqual(hosts[0].hostname, reparsed[0].hostname)
        XCTAssertEqual(hosts[0].user, reparsed[0].user)
        XCTAssertEqual(hosts[0].port, reparsed[0].port)
    }

    func testParseEmptyConfig() throws {
        let hosts = SSHConfigParser.parse("")
        XCTAssertEqual(hosts.count, 0)
    }

    func testParseOnlyComments() throws {
        let config = """
        # Comment 1
        # Comment 2
        # Comment 3
        """
        let hosts = SSHConfigParser.parse(config)
        XCTAssertEqual(hosts.count, 0)
    }
}
