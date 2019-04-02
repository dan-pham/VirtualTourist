//
//  Photo+Extensions.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/14/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    
    convenience init(image: Data, url: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.image = image
            self.url = url
        } else {
            fatalError("Cannot find Photo")
        }
    }
    
}
