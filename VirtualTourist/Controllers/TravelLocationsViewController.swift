//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/12/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: Properties
    
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var latitude:Double?
    var longitude:Double?
    var latitudeDelta:Double?
    var longitudeDelta:Double?
    var center:CLLocationCoordinate2D?
    var span:MKCoordinateSpan?
    var region:MKCoordinateRegion?
    
    // MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: FetchedResultsController setup
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: View function
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setUpFetchedResultsController()
        checkIfFirstLaunch()
    }
    
    // MARK: Launch functions
    
    // If not first time launching app, load previous data. Otherwise, use default settings.
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            debugPrint("App has launched before")
            setMapDetails()
            loadPreviousUserMapLocation()
            loadPreviousUserMapPins()
        } else {
            debugPrint("This is the first launch ever")
            setDefaultUserMapLocation()
        }
    }
    
    // Set up map data
    func setMapDetails() {
        latitude = UserDefaults.standard.double(forKey: "Latitude")
        longitude = UserDefaults.standard.double(forKey: "Longitude")
        latitudeDelta = UserDefaults.standard.double(forKey: "LatitudeDelta")
        longitudeDelta = UserDefaults.standard.double(forKey: "LongitudeDelta")
    }
    
    // Load previous map data
    func loadPreviousUserMapLocation() {
        center = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        span = MKCoordinateSpan(latitudeDelta: latitudeDelta!, longitudeDelta: longitudeDelta!)
        region = MKCoordinateRegion(center: center!, span: span!)
        mapView.setRegion(region!, animated: false)
    }
    
    // Load previous map pins
    func loadPreviousUserMapPins() {
        if let pins = try? dataController.viewContext.fetch(fetchedResultsController.fetchRequest) {
            for pin in pins {
                let pinMKPointAnnotation = MKPointAnnotation()
                pinMKPointAnnotation.coordinate.latitude = pin.latitude
                pinMKPointAnnotation.coordinate.longitude = pin.longitude
                mapView.addAnnotation(pinMKPointAnnotation)
            }
        }
    }
    
    // Load default map settings
    func setDefaultUserMapLocation() {
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "Latitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "Longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
        
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Pin functions
    
    // Referenced from Sean Allen's "Swift Gesture Recognizer Tutorial - Pan" on Youtube: https://www.youtube.com/watch?v=rnJxpuPyLNA
    // Add a new pin to the map by executing a long press
    @IBAction func addNewPinToMap(_ sender: UILongPressGestureRecognizer) {
        let pressLocation = sender.location(in: mapView)
        let newCoordinates = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        let newPin = MKPointAnnotation()
        
        switch sender.state {
        case .ended:
            newPin.coordinate = newCoordinates
            mapView.addAnnotation(newPin)
            addNewPinToCoreData(newCoordinates: newCoordinates)
            
        default:
            break
        }
    }
    
    // Add a new pin to Core Data
    func addNewPinToCoreData(newCoordinates:CLLocationCoordinate2D) {
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = newCoordinates.latitude
        newPin.longitude = newCoordinates.longitude
        try? dataController.viewContext.save()
    }
    
    // Get pin with matching location information from Core Data
    func retrievePinFromCoreData(annotationView: MKAnnotationView) -> Pin? {
        let predicate = NSPredicate(format: "latitude == %@ && longitude == %@", argumentArray: [annotationView.annotation?.coordinate.latitude, annotationView.annotation?.coordinate.longitude])
        fetchedResultsController.fetchRequest.predicate = predicate
        try? fetchedResultsController.performFetch()

        if let pin = try? dataController.viewContext.fetch(fetchedResultsController.fetchRequest).first {
            return pin
        } else {
            debugPrint("Pin not found")
            return nil
        }
    }
}

extension TravelLocationsViewController {

    // MARK: - MKMapViewDelegate

    // Pin detail setup
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
            let reuseId = "pin"
    
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = true
                pinView!.pinTintColor = .red
                pinView!.animatesDrop = true
            }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Save map details any time there is a change
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setDefaultUserMapLocation()
    }
    
    // Pass pin and Core Data information to the next ViewController
    func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
        let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        let retrievedPin = retrievePinFromCoreData(annotationView: annotationView)
        photoAlbumVC.pin = retrievedPin
        photoAlbumVC.dataController = dataController
        navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
}
