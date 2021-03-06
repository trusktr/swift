// RUN: %target-parse-verify-swift

// Test requirements and conformance for Objective-C protocols.

@objc class ObjCClass { }

@objc protocol P1 {
  func method1()

  var property1: ObjCClass { get }
  var property2: ObjCClass { get set }
}

@objc class C1 : P1 {
  @objc(method1renamed)
  func method1() { // expected-error{{Objective-C method 'method1renamed' provided by method 'method1()' does not match the requirement's selector ('method1')}}{{9-23=method1}}
  }

  var property1: ObjCClass {
    @objc(getProperty1) get { // expected-error{{Objective-C method 'getProperty1' provided by getter for 'property1' does not match the requirement's selector ('property1')}}{{11-23=property1}}
      return ObjCClass()
    } 
  }

  var property2: ObjCClass {
    get { return ObjCClass() }
    @objc(setProperty2Please:) set { } // expected-error{{Objective-C method 'setProperty2Please:' provided by setter for 'property2' does not match the requirement's selector ('setProperty2:')}}{{11-30=setProperty2:}}
  }
}

class C1b : P1 {
  func method1() { }
  var property1: ObjCClass = ObjCClass()
  var property2: ObjCClass = ObjCClass()
}

@objc protocol P2 {
  @objc(methodWithInt:withClass:)
  func method(_: Int, class: ObjCClass)

  var empty: Bool { @objc(checkIfEmpty) get }
}

class C2a : P2 {
  func method(_: Int, class: ObjCClass) { }

  var empty: Bool {
    get { } // expected-error{{Objective-C method 'empty' provided by getter for 'empty' does not match the requirement's selector ('checkIfEmpty')}}
  }
}

class C2b : P2 {
  @objc func method(_: Int, class: ObjCClass) { }

  @objc var empty: Bool {
    @objc get { } // expected-error{{Objective-C method 'empty' provided by getter for 'empty' does not match the requirement's selector ('checkIfEmpty')}}{{10-10=(checkIfEmpty)}}
  }
}

@objc protocol P3 {
  optional func doSomething(x: Int)
  optional func doSomething(y: Int)
}

class C3a : P3 {
  @objc func doSomething(x: Int) { }
}

// Complain about optional requirements that aren't satisfied
// according to Swift, but would conflict in Objective-C.
@objc protocol OptP1 {
  optional func method() // expected-note 2{{requirement 'method()' declared here}}

  optional var property1: ObjCClass { get } // expected-note 2{{requirement 'property1' declared here}}
  optional var property2: ObjCClass { get set } // expected-note{{requirement 'property2' declared here}}
}

@objc class OptC1a : OptP1 { // expected-note 3{{class 'OptC1a' declares conformance to protocol 'OptP1' here}}
  @objc(method) func otherMethod() { } // expected-error{{Objective-C method 'method' provided by method 'otherMethod()' conflicts with optional requirement method 'method()' in protocol 'OptP1'}}
  // expected-note@-1{{rename method to match requirement 'method()'}}{{22-33=method}}

  var otherProp1: ObjCClass {
    @objc(property1) get { return ObjCClass() } // expected-error{{Objective-C method 'property1' provided by getter for 'otherProp1' conflicts with optional requirement getter for 'property1' in protocol 'OptP1'}}
  }

  var otherProp2: ObjCClass {
    get { return ObjCClass() }
    @objc(setProperty2:) set { } // expected-error{{Objective-C method 'setProperty2:' provided by setter for 'otherProp2' conflicts with optional requirement setter for 'property2' in protocol 'OptP1'}}
  }
}

@objc class OptC1b : OptP1 { // expected-note 2{{class 'OptC1b' declares conformance to protocol 'OptP1' here}}
  @objc(property1) func someMethod() { } // expected-error{{Objective-C method 'property1' provided by method 'someMethod()' conflicts with optional requirement getter for 'property1' in protocol 'OptP1'}}

  var someProp: ObjCClass {
    @objc(method) get { return ObjCClass() } // expected-error{{Objective-C method 'method' provided by getter for 'someProp' conflicts with optional requirement method 'method()' in protocol 'OptP1'}}
  }
}

// rdar://problem/19879598
@objc protocol Foo {
  init()
}

class Bar: Foo {
  required init() {}
}

@objc protocol P4 {
  @objc(foo:bar:)
  func method(x: Int, y: Int)
}

// Infer @objc and selector from requirement.
class C4a : P4 {
  func method(x: Int, y: Int) { }
}

// Infer selector from requirement.
class C4b : P4 {
  @objc
  func method(x: Int, y: Int) { }
}

@objc protocol P5 {
  @objc(wibble:wobble:)
  func method(x: Int, y: Int)
}

// Don't infer when there is an ambiguity.
class C4_5a : P4, P5 {
  func method(x: Int, y: Int) { }
  // expected-error@-1{{Objective-C method 'methodWithX:y:' provided by method 'method(x:y:)' does not match the requirement's selector ('foo:bar:')}}
  // expected-error@-2{{Objective-C method 'methodWithX:y:' provided by method 'method(x:y:)' does not match the requirement's selector ('wibble:wobble:')}}
}
