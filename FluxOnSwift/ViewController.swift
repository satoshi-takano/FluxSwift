//
//  ViewController.swift
//  FluxOnSwift
//
//  Created by Satoshi Takano on 2017/10/18.
//  Copyright © 2017年 freee. All rights reserved.
//

import UIKit
import Result
import RxSwift

struct ToDo {
    let text: String
}

struct ToDoAction {
    struct Fetch: AsyncAction {
        typealias Payload = [ToDo]
        
        func invoke() -> Observable<Void> {
            return fetchDefaultItems().`do`(onNext: { result in
                self.dispatch(Result(value: result))
            }, onError: { error in
                self.dispatch(Result(error: NSError.error(from: error)))
            }).completedValue()
        }
        
        private func fetchDefaultItems() -> Observable<[ToDo]> {
            return Observable.just([
                ToDo(text: "First item"),
                ToDo(text: "Second item"),
                ToDo(text: "Third item")
            ])
        }
    }
    
    struct Add: Action {
        typealias Payload = ToDo
        let text: String
        
        func invoke() {
            self.dispatch(Result(value: ToDo(text: text)))
        }
    }
    
    struct Delete: Action {
        typealias Payload = Int
        let index: Int
        
        func invoke() {
            self.dispatch(Result(value: index))
        }
    }
}

final class ToDoStore {
    let todos = Variable<[ToDo]>([])
    private(set) var addedIndex = -1
    private(set) var deletedIndex = -1
    
    private let disposeBag = DisposeBag()
    
    init() {
        let d = Dispatcher.shared
        
        d.rx_notification(ToDoAction.Fetch.self).subscribe(onNext: { [weak self] result in
            switch result {
            case .success(let todos):
                self?.resetIndices()
                self?.todos.value = todos
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        d.rx_notification(ToDoAction.Add.self).subscribe(onNext: { [weak self] result in
            switch result {
            case .success(let todo):
                self?.resetIndices()

                let current = self?.todos.value ?? []
                self?.addedIndex = current.count
                self?.todos.value = current + [todo]
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        d.rx_notification(ToDoAction.Delete.self).subscribe(onNext: { [weak self] result in
            switch result {
            case .success(let index):
                guard let `self` = self else { return }
                self.resetIndices()
                
                self.deletedIndex = index
                var todos = self.todos.value
                todos.remove(at: index)
                self.todos.value = todos
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    private func resetIndices() {
        addedIndex = -1
        deletedIndex = -1
    }
}

final class ToDoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textField: UITextField!
    
    private let todoStore = ToDoStore()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        todoStore.todos.asDriver().drive(onNext: { [unowned self] todos in
            if self.todoStore.addedIndex > 0 {
                self.tableView.insertRows(at: [IndexPath(row: self.todoStore.addedIndex, section: 0)], with: .fade)
                self.textField.text = ""
            } else if self.todoStore.deletedIndex > 0 {
                self.tableView.deleteRows(at: [IndexPath(row: self.todoStore.deletedIndex, section: 0)], with: .fade)
            } else {
                self.tableView.reloadData()
            }
        }).disposed(by: disposeBag)
        
        _ = ToDoAction.Fetch().invoke().subscribe()
    }
    
    @IBAction func tapAdd(_ sender: Any) {
        if let text = textField.text, !text.isEmpty {
            ToDoAction.Add(text: text).invoke()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoStore.todos.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = todoStore.todos.value[indexPath.row].text
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ToDoAction.Delete(index: indexPath.row).invoke()
    }
}
