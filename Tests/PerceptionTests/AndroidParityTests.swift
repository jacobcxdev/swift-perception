// AndroidParityTests.swift
// Tests verifying behavioral parity between Apple and Android paths.
// These tests exercise public API without platform conditionals in the test body.

import Perception
import XCTest

// MARK: - withPerceptionTracking

final class PerceptionTrackingParityTests: XCTestCase {
  @Perceptible
  class Counter {
    var count = 0
    var name = "default"
  }

  func testOnChangeFiresOnMutation() {
    let counter = Counter()
    let expectation = expectation(description: "onChange fires")

    withPerceptionTracking {
      _ = counter.count
    } onChange: {
      expectation.fulfill()
    }

    counter.count = 1
    wait(for: [expectation], timeout: 1.0)
  }

  func testOnChangeDoesNotFireForUnaccessed() {
    let counter = Counter()
    let expectation = expectation(description: "onChange should not fire")
    expectation.isInverted = true

    withPerceptionTracking {
      _ = counter.count
    } onChange: {
      expectation.fulfill()
    }

    // Mutate a field that was NOT accessed in the tracking closure
    counter.name = "changed"
    wait(for: [expectation], timeout: 0.5)
  }

  func testMultipleFieldTracking() {
    let counter = Counter()
    let expectation = expectation(description: "onChange fires for either field")

    withPerceptionTracking {
      _ = counter.count
      _ = counter.name
    } onChange: {
      expectation.fulfill()
    }

    counter.name = "changed"
    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - PerceptionRegistrar

final class PerceptionRegistrarParityTests: XCTestCase {
  @Perceptible
  class Model {
    var value = 42
  }

  func testPropertyAccessDoesNotCrash() {
    // On Android, perception checking is disabled — property access outside
    // withPerceptionTracking must NOT crash (no runtime warning/assertion).
    let model = Model()
    let _ = model.value
    model.value = 100
    XCTAssertEqual(model.value, 100)
  }

  func testRegistrarWillSetDidSet() {
    // Verify the registrar correctly notifies observers through willSet/didSet.
    let model = Model()
    var observed = false

    withPerceptionTracking {
      _ = model.value
    } onChange: {
      observed = true
    }

    model.value = 99
    // Give a moment for the onChange callback
    let expectation = expectation(description: "observation")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      XCTAssertTrue(observed)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
}
