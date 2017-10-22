//
//  Flux.swift
//  FluxOnSwift
//
//  Created by Satoshi Takano on 2017/10/18.
//  Copyright © 2017年 freee. All rights reserved.
//

import Foundation
import Result
import RxSwift
import RxCocoa

protocol ActionBase {
    associatedtype Payload
    associatedtype ActionError: Error = NSError
}

extension ActionBase {
    static var name: Notification.Name {
        return Notification.Name(String(reflecting: self))
    }
    
    func dispatch(_ result: Result<Payload, ActionError>) {
        Dispatcher.shared.post(
            name: type(of: self).name,
            object: result
        )
    }
}

protocol Action: ActionBase {
    func invoke()
}

protocol AsyncAction: ActionBase {
    func invoke() -> Observable<Void>
}

class Dispatcher: NotificationCenter {
    static let shared = Dispatcher()
}
extension Dispatcher {
    func rx_notification<T: ActionBase>(_ action: T.Type) -> Observable<Result<T.Payload, T.ActionError>> {
        return rx.notification(action.name).map { notification in
            let object = notification.object as! Result<T.Payload, T.ActionError>
            return object
        }
    }
}


extension Observable {
    func completedValue() -> Observable<Void> {
        // completed になった時に値（Void）を流す
        return materialize().filter {
            if case .completed = $0 { return true } else { return false }
            }.map { _ in () }
    }
}
