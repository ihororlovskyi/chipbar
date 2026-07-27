import ServiceManagement
import XCTest
@testable import sysbar

private final class FakeLoginItemService: LoginItemService {
  var status: SMAppService.Status = .notRegistered
  var registerCalls = 0
  var unregisterCalls = 0
  var registerError: Error?

  func register() throws {
    registerCalls += 1
    if let registerError { throw registerError }
    status = .enabled
  }

  func unregister() throws {
    unregisterCalls += 1
    status = .notRegistered
  }
}

private struct StubError: Error {}

final class LoginItemTests: XCTestCase {
  func test_mapsEnabledStatus() {
    let service = FakeLoginItemService()
    service.status = .enabled
    XCTAssertEqual(LoginItem(service: service).state, .enabled)
  }

  func test_mapsNotRegisteredStatus() {
    let service = FakeLoginItemService()
    service.status = .notRegistered
    XCTAssertEqual(LoginItem(service: service).state, .disabled)
  }

  func test_mapsRequiresApprovalStatus() {
    let service = FakeLoginItemService()
    service.status = .requiresApproval
    XCTAssertEqual(LoginItem(service: service).state, .requiresApproval)
  }

  func test_mapsNotFoundStatus() {
    let service = FakeLoginItemService()
    service.status = .notFound
    XCTAssertEqual(LoginItem(service: service).state, .disabled)
  }

  func test_enablingFromDisabledRegistersOnce() throws {
    let service = FakeLoginItemService()
    try LoginItem(service: service).setEnabled(true)
    XCTAssertEqual(service.registerCalls, 1)
    XCTAssertEqual(service.unregisterCalls, 0)
  }

  func test_enablingWhenAlreadyEnabledUnregistersFirst() throws {
    let service = FakeLoginItemService()
    service.status = .enabled
    try LoginItem(service: service).setEnabled(true)
    XCTAssertEqual(service.unregisterCalls, 1, "stale registrations must be cleared before re-registering")
    XCTAssertEqual(service.registerCalls, 1)
  }

  func test_enablingWhenAwaitingApprovalUnregistersFirst() throws {
    let service = FakeLoginItemService()
    service.status = .requiresApproval
    try LoginItem(service: service).setEnabled(true)
    XCTAssertEqual(service.unregisterCalls, 1)
    XCTAssertEqual(service.registerCalls, 1)
  }

  func test_disablingUnregistersWhenAwaitingApproval() throws {
    let service = FakeLoginItemService()
    service.status = .requiresApproval
    try LoginItem(service: service).setEnabled(false)
    XCTAssertEqual(service.unregisterCalls, 1, "an unapproved service must still be removable")
  }

  func test_disablingUnregistersWhenEnabled() throws {
    let service = FakeLoginItemService()
    service.status = .enabled
    try LoginItem(service: service).setEnabled(false)
    XCTAssertEqual(service.unregisterCalls, 1)
    XCTAssertEqual(service.registerCalls, 0)
  }

  func test_disablingDoesNothingWhenNotRegistered() throws {
    let service = FakeLoginItemService()
    service.status = .notRegistered
    try LoginItem(service: service).setEnabled(false)
    XCTAssertEqual(service.unregisterCalls, 0)
  }

  func test_enablingWhenServiceRecordIsNotFoundRegisters() throws {
    let service = FakeLoginItemService()
    service.status = .notFound
    try LoginItem(service: service).setEnabled(true)
    XCTAssertEqual(service.registerCalls, 1, "registration must recreate a record removed by macOS")
    XCTAssertEqual(service.unregisterCalls, 0)
  }

  func test_disablingDoesNothingWhenServiceRecordIsNotFound() throws {
    let service = FakeLoginItemService()
    service.status = .notFound
    try LoginItem(service: service).setEnabled(false)
    XCTAssertEqual(service.unregisterCalls, 0)
    XCTAssertEqual(service.registerCalls, 0)
  }

  func test_registrationErrorPropagates() {
    let service = FakeLoginItemService()
    service.registerError = StubError()
    XCTAssertThrowsError(try LoginItem(service: service).setEnabled(true))
  }
}
