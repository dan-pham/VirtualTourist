//
//  Pin+Extensions.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/14/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Cannot find Pin")
        }
    }
}
