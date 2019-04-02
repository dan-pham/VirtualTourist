//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Dan Pham on 3/13/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // MARK: Properties
    
    var pin:Pin!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var deleteButton:UIBarButtonItem!
    var insertedCells:[IndexPath]!
    var deletedCells:[IndexPath]!
    var selectedCells:[IndexPath] = []
    
    // MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: FetchedResultsController setup
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        if let pin = pin {
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
        }
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-photos")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FlickrClient.sharedInstance().dataController = dataController
        setUpDeleteButton()
        setUpFetchedResultsController()
        setUpViews()
        fetchPhotosFromCoreData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
    }
    
    // MARK: Setup functions
    
    // Referenced from Lets Build That App's "Swift 3: Twitter - Custom Navigation Bar (Ep 7)" on YouTube: https://www.youtube.com/watch?v=zS-CCd4xmRY
    // Set up a delete button in navigation bar
    func setUpDeleteButton() {
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(PhotoAlbumViewController.deleteButtonPressed))
        navigationItem.rightBarButtonItem = deleteButton
        deleteButton.isEnabled = false
    }
    
    // Set up the mapView and collectionView
    func setUpViews() {
        mapView.delegate = self
        mapView.isUserInteractionEnabled = false
        addPinToMap(pin: pin)
        
        collectionView.delegate = self
        setUpFlowLayout()
    }
    
    // Add pin details to map from previous view controller
    func addPinToMap(pin: Pin) {
        let latitude = pin.latitude
        let longitude = pin.longitude
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateRegion = MKCoordinateRegion.init(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(coordinateRegion, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
    }

    // Set up flow layout
    func setUpFlowLayout() {
        flowLayout.minimumInteritemSpacing = 3
        flowLayout.minimumLineSpacing = 3
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }

    // MARK: Fetch photos from Core Data
    
    // Use FlickrClient to fetch photos from Core Data
    func fetchPhotosFromCoreData() {
        try? fetchedResultsController.performFetch()
        let fetchedPhotos = fetchedResultsController.fetchedObjects
        if fetchedPhotos?.count == 0 {
            debugPrint("No photos have been downloaded for this pin")
            FlickrClient.sharedInstance().retrievePhotosFromFlickr(self.pin)
        } else {
            debugPrint("This pin should have photos.")
        }
    }
    
    // MARK: CollectionView functions

    // Referenced from Sean Allen's "Swift Gesture Recognizer Tutorial" on YouTube: https://www.youtube.com/watch?v=rnJxpuPyLNA
    // Long press enables collection view selection
    @IBAction func selectCollectionViewCell(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .ended:
            collectionViewSelected(isSelected: true)
        default:
            break
        }
    }

    // Enable and disable properties
    func collectionViewSelected(isSelected: Bool) {
        deleteButton.isEnabled = isSelected
        collectionView.allowsMultipleSelection = isSelected
        newCollectionButton.titleLabel?.text = isSelected ? "Cancel" : "New Collection"

        // If collection view is not selected, reset the selected cells array
        if !isSelected {
            for cell in selectedCells {
                if let pathToRemove = selectedCells.index(of: cell) {
                    selectedCells.remove(at: pathToRemove)
                    collectionView.cellForItem(at: cell)?.alpha = 1.0
                }
            }
        }
    }
    
    // Delete selected photos from collection view
    @IBAction func deleteButtonPressed(_ sender: Any) {
        for indexPath in selectedCells {
            if let photos = fetchedResultsController.fetchedObjects {
                dataController.viewContext.delete(photos[indexPath.item])
                DispatchQueue.main.async {
                    try? self.dataController.viewContext.save()
                }
            }
        }
        selectedCells.removeAll()
    }

    // Button either gets new collection or cancels cell selection
    @IBAction func newCollection(_ sender: Any) {
        if newCollectionButton.titleLabel?.text == "New Collection" {
            // Get new collection from Flickr and save into Core Data
            if let photos = fetchedResultsController.fetchedObjects {
                for photo in photos {
                    dataController.viewContext.delete(photo)
                }
                DispatchQueue.main.async {
                    try? self.dataController.viewContext.save()
                }
            }
            FlickrClient.sharedInstance().retrievePhotosFromFlickr(self.pin)
        } else {
            // Cancel selection
            collectionViewSelected(isSelected: false)
        }
    }
}

extension PhotoAlbumViewController {
    
    // MARK: - MKMapViewDelegate
    
    // Pin detail setup
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = false
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    // Set up actions for FetchedResultsController changes
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedCells.append(newIndexPath!)
            break
        case .delete:
            deletedCells.append(indexPath!)
            break
        default:
            break
        }
    }
    
    // Prepare for FetchedResultsController changes
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedCells = [IndexPath]()
        deletedCells = [IndexPath]()
    }
    
    // Actions for FetchedResultsController changes
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedCells {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedCells {
                self.collectionView.deleteItems(at: [indexPath])
            }
        }, completion: nil)
    }
    
    // MARK: - UICollectionViewDelegate
    
    // Return number of items in collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    // Get images from Flickr and put them in the collection view cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let aPhoto = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomPhotoCollectionViewCell", for: indexPath) as! CustomPhotoCollectionViewCell
        
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        
        if let image = aPhoto.image {
            cell.imageView.image = UIImage(data: image as Data)
            cell.activityIndicator.stopAnimating()
        } else {
            if aPhoto.url != nil {
                FlickrClient.sharedInstance().downloadPhotoFromUrl(aPhoto) { (success) in
                    if success {
                        try? self.fetchedResultsController.performFetch()
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    } else {
                        debugPrint("PhotoAlbumViewController: Error downloading from url")
                    }
                }
            }
        }
        return cell
    }
    
    // Actions for selecting a collection view cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            selectedCells.append(indexPath)
            collectionView.cellForItem(at: indexPath)?.alpha = 0.5
        }
    }
    
    // Actions for deselecting a collection view cell
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let pathToRemove = selectedCells.index(of: indexPath) {
            selectedCells.remove(at: pathToRemove)
            collectionView.cellForItem(at: indexPath)?.alpha = 1.0
        }
    }
}
