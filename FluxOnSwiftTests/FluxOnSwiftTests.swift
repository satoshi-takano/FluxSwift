//
//  FluxOnSwiftTests.swift
//  FluxOnSwiftTests
//
//  Created by Satoshi Takano on 2017/10/20.
//  Copyright © 2017年 freee. All rights reserved.
//

import XCTest
@testable import FluxOnSwift
import Result

extension ActionBase {
    static func dispatch(_ result: Result<Payload, ActionError>) {
        Dispatcher.shared.post(
            name: self.name,
            object: result
        )
    }
}

class TodoStoreTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFetch() {
        let store = ToDoStore()
        XCTAssertTrue(store.todos.value.isEmpty)
        
        ToDoAction.Fetch.dispatch(Result(value: [
            ToDo(text: "foo"),
            ToDo(text: "bar")
        ]))
        
        XCTAssertEqual(store.todos.value.count, 2)
        XCTAssertEqual(store.todos.value.first?.text, "foo")
        XCTAssertEqual(store.todos.value.last?.text, "bar")
    }
    
    func testAdd() {
        let store = ToDoStore()
        XCTAssertTrue(store.todos.value.isEmpty)
        XCTAssertEqual(store.addedIndex, -1)
        
        ToDoAction.Add.dispatch(Result(value: ToDo(text: "foo")))
        XCTAssertEqual(store.todos.value.count, 1)
        XCTAssertEqual(store.todos.value.first?.text, "foo")
        XCTAssertEqual(store.addedIndex, 0)
    }
    
    func testDelete() {
        let store = ToDoStore()
        ToDoAction.Fetch.dispatch(Result(value: [
            ToDo(text: "foo"),
            ToDo(text: "bar")
        ]))
        XCTAssertEqual(store.todos.value.count, 2)
        XCTAssertEqual(store.deletedIndex, -1)
        
        ToDoAction.Delete(index: 0).dispatch(Result(value: 0))
        XCTAssertEqual(store.todos.value.count, 1)
        XCTAssertEqual(store.todos.value.first?.text, "bar")
        XCTAssertEqual(store.deletedIndex, 0)
    }
}
