//
//  Todo+CoreDataProperties.swift
//  ToDo
//
//  Created by 정지운 on 10/11/24.
//
//

import Foundation
import CoreData


extension Todo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Todo> {
        return NSFetchRequest<Todo>(entityName: "Todo")
    }

    @NSManaged public var date: Date?
    @NSManaged public var task: String?
    @NSManaged public var isCompleted: Bool

}

extension Todo : Identifiable {

}
