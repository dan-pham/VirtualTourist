//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/14/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient {
    
    // MARK: Properties
    
    var dataController:DataController!
    static var page:Int?
    static var latitude:Double?
    static var longitude:Double?
    
    // Shared instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // Flickr API Endpoints
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        static let apiKey = "6496abdd06a5d6ccc2e514c00047032a"
        static let apiSecret = "90eebcb9902d7d63"
        static let method = "/?method=flickr.photos.search"
        static let api_key = "&api_key=\(Endpoints.apiKey)"
        static let jsonFormat = "&format=json" // Returns JSON response
        static let jsonCallback = "&nojsoncallback=1" // Returns raw JSON response
        static let mediumUrl = "&extras=url_m"
        static let randomPage = "&page=\(page!)"
        static let lat = "&lat=\(latitude!)"
        static let lon = "&lon=\(longitude!)"
        static let radius = "&radius=5"
        
        case retrieveRandomPageFromFlickr
        case retrievePhotosFromPage
        
        var stringValue: String {
            switch self {
            case .retrieveRandomPageFromFlickr:
                return Endpoints.base + Endpoints.method + Endpoints.api_key + Endpoints.mediumUrl + Endpoints.jsonFormat + Endpoints.jsonCallback + Endpoints.lat + Endpoints.lon + Endpoints.radius
            case .retrievePhotosFromPage:
                return Endpoints.base + Endpoints.method + Endpoints.api_key + Endpoints.mediumUrl + Endpoints.jsonFormat + Endpoints.jsonCallback + Endpoints.lat + Endpoints.lon + Endpoints.radius + Endpoints.randomPage
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // MARK: Get Photos from Flickr
    
    func retrievePhotosFromFlickr(_ pin: Pin) {
        FlickrClient.latitude = pin.latitude
        FlickrClient.longitude = pin.longitude
        
        // Get a random page from Flickr results
        retrieveRandomPageFromResults(url: Endpoints.retrieveRandomPageFromFlickr.url) { (success, page, error) in
            if success {
                // Get the photos from the page
                FlickrClient.page = page
                self.retrievePhotosFromPage(url: Endpoints.retrievePhotosFromPage.url, completion: { (success, photos, error) in
                    if success {
                        // Select random photos and save their URLs
                        self.saveRandomPhotoURLs(pin: pin, photos: photos!)
                    } else {
                        debugPrint("Retrieve photos request: Unable to complete the request.")
                    }
                })
            } else {
                debugPrint("Retrieve random page request: Unable to complete the request.")
            }
        }
    }
    
    // Get a random page from Flickr results
    func retrieveRandomPageFromResults(url: URL, completion: @escaping (_ success: Bool, _ page: Int?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, nil, error)
                debugPrint("Random page request: Unable to complete the request due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, nil, error)
                debugPrint("Random page request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, nil, error)
                debugPrint("Random page request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, nil, error)
                debugPrint("Random page request: Could not parse the JSON data")
                return
            }
            
            // Check for the response status
            guard let status = parsedData["stat"] as? String, status == "ok" else {
                completion(false, nil, error)
                debugPrint("Random page request: The \"stat\" value in the JSON data was not \"ok\"")
                return
            }
            
            // Check for the photos key and set as a dictionary
            guard let photosKey = parsedData["photos"] as? [String : AnyObject] else {
                completion(false, nil, error)
                debugPrint("Random page request: Could not find the \"photos\" key in the JSON data")
                return
            }
            
            // Check for the pages key and set as an integer
            guard let pages = photosKey["pages"] as? Int else {
                completion(false, nil, error)
                debugPrint("Random page request: Could not find the \"pages\" key in the JSON data")
                return
            }
            
            // Set the upper bound for pages and choose a random page
            let maxPages = min(pages, 20)
            let randomPage = Int.random(in: 1...maxPages)
            
            // If everything is successful, return a random page
            completion(true, randomPage, nil)
        }
        task.resume()
    }
    
    // Get the photos from the page
    func retrievePhotosFromPage(url: URL, completion: @escaping (_ success: Bool, _ photos: [[String : AnyObject]]?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, nil, error)
                debugPrint("Photo request: Unable to complete the request due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, nil, error)
                debugPrint("Photo request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, nil, error)
                debugPrint("Photo request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, nil, error)
                debugPrint("Photo request: Could not parse the JSON data")
                return
            }
            
            // Check for the response status
            guard let status = parsedData["stat"] as? String, status == "ok" else {
                completion(false, nil, error)
                debugPrint("Photo request: The \"stat\" value in the JSON data was not \"ok\"")
                return
            }
            
            // Check for the photos key and set as a dictionary
            guard let photosKey = parsedData["photos"] as? [String : AnyObject] else {
                completion(false, nil, error)
                debugPrint("Photo request: Could not find the \"photos\" key in the JSON data")
                return
            }
            
            // Check for the photo key and set as array of dictionaries
            guard let photos = photosKey["photo"] as? [[String : AnyObject]] else {
                completion(false, nil, error)
                debugPrint("Photo request: Could not find the \"photo\" key in the JSON data")
                return
            }
            
            // Check for photos in the array
            if photos.count == 0 {
                completion(false, nil, error)
                debugPrint("Photo request: This page does not have any photos")
                return
            }
            
            // If everything is successful, return photos from the page
            completion(true, photos, nil)
        }
        task.resume()
    }
    
    // Select random photos and save their URLs
    func saveRandomPhotoURLs(pin: Pin, photos: [[String : AnyObject]?]) {
        // If there are less than 30 photos, add all of the photos in the array. Otherwise, pick 30 random photos and add them to the array.
        if photos.count < 30 {
            for photo in photos {
                if let photo = photo {
                    let url = photo["url_m"] as! String
                    addPhoto(pin: pin, url: url)
                }
            }
            DispatchQueue.main.async {
                try? self.dataController.viewContext.save()
            }
        } else {
            var selectedIndices: [Int] = []
            while selectedIndices.count < 30 {
                let randomNumber = randomNumberGenerator(upperBound: photos.count, selectedIndices: selectedIndices)
                selectedIndices.append(randomNumber)
                
                if let randomPhoto = photos[randomNumber] {
                    let randomURL = randomPhoto["url_m"] as! String
                    addPhoto(pin: pin, url: randomURL)
                }
            }
            DispatchQueue.main.async {
                try? self.dataController.viewContext.save()
            }
        }
    }
    
    // Add photo to Core Data
    func addPhoto(pin: Pin, url: String) {
        DispatchQueue.main.async {
            let photoToSave = Photo(context: self.dataController.viewContext)
            photoToSave.url = url
            photoToSave.pin = pin
            try? self.dataController.viewContext.save()
        }
    }
    
    // Referenced from StackOverflow: https://stackoverflow.com/questions/24007129/how-does-one-generate-a-random-number-in-apples-swift-language
    // Generates random numbers
    func randomNumberGenerator(upperBound: Int, selectedIndices: [Int]) -> Int {
        let randomNumber = Int.random(in: 0..<upperBound)
        
        if selectedIndices.contains(randomNumber) {
            return randomNumberGenerator(upperBound: upperBound, selectedIndices: selectedIndices)
        } else {
            return randomNumber
        }
    }
    
    // Download photo using its URL
    func downloadPhotoFromUrl(_ photo: Photo, completion: @escaping (_ success: Bool) -> Void) {
        let url = URL(string: photo.url!)

        // Referenced from StackOverflow: https://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
        DispatchQueue.global(qos: .background).async {
            if let image = try? Data(contentsOf: url!) {
                DispatchQueue.main.async {
                    photo.image = image as Data
                    try? self.dataController.viewContext.save()
                }
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                        debugPrint("Unable to download image from url: \(url)")
                    completion(false)
                }
            }
        }
    }
    
}
